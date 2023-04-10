# © Copyright IBM Corporation 2015, 2019
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:18.04

LABEL maintainer "Sam Massey <smassey@uk.ibm.com>"

RUN export DEBIAN_FRONTEND=noninteractive \
  # Install additional packages - do we need/want them all
  && apt-get update -y \
  && apt-get install -y --no-install-recommends \
    bash \
    bc \
    ca-certificates \
    coreutils \
    curl \
    debianutils \
    file \
    findutils \
    gawk \
    grep \
    libc-bin \
    lsb-release \
    mount \
    passwd \
    procps \
    sed \
    tar \
    util-linux \
    iputils-ping \
    sysstat \
    procps \
    apt-utils \
    dstat \
    vim \
    iproute2 \
    wget \
    sudo \
  # Apply any bug fixes not included in base Ubuntu or MQ image.
  # Don't upgrade everything based on Docker best practices https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#run
  && apt-get upgrade -y libkrb5-26-heimdal \
  && apt-get upgrade -y libexpat1 \
  # End of bug fixes
  && rm -rf /var/lib/apt/lists/* \
  # Optional: Update the command prompt 
  && echo "cph" > /etc/debian_chroot \
  && sed -i 's/password\t\[success=1 default=ignore\]\tpam_unix\.so obscure sha512/password\t[success=1 default=ignore]\tpam_unix.so obscure sha512 minlen=8/' /etc/pam.d/common-password \
  && groupadd --system --gid 999 mqm \
  && useradd --system --uid 999 --gid mqm mqperf \
  && usermod -a -G root mqperf \
  && echo mqperf:orland02 | chpasswd \
  && mkdir -p /home/mqperf/cph \
  && chown -R mqperf:root /home/mqperf/cph \
  && chmod -R g+w /home/mqperf/cph \
  && chmod -R a+w /home/mqperf/cph \
  && echo "cd ~/cph" >> /home/mqperf/.bashrc

# Download the large file using wget
RUN wget -T5 -q -O /tmp/mqadv_dev932_ubuntu_x86-64.tar.gz  https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev932_ubuntu_x86-64.tar.gz  && \
    tar xzf /tmp/mqadv_dev932_ubuntu_x86-64.tar.gz && \
    mkdir /lap && \
    cp  -R ./MQServer/lap/* /lap && \
    rm /tmp/mqadv_dev932_ubuntu_x86-64.tar.gz

RUN export DEBIAN_FRONTEND=noninteractive \
  && ./MQServer/mqlicense.sh -accept \
  && dpkg -i ./MQServer/ibmmq-runtime_9.3.2.0_amd64.deb \
  && dpkg -i ./MQServer/ibmmq-gskit_9.3.2.0_amd64.deb \
  && dpkg -i ./MQServer/ibmmq-client_9.3.2.0_amd64.deb \
  && dpkg -i ./MQServer/ibmmq-samples_9.3.2.0_amd64.deb \
  && chown -R mqperf:root /opt/mqm/* \
  && chown -R mqperf:root /var/mqm/* \
  && chmod o+w /var/mqm 

COPY cph/* /home/mqperf/cph/
COPY ssl/* /opt/mqm/ssl/
COPY *.sh /home/mqperf/cph/
COPY *.mqsc /home/mqperf/cph/
COPY qmmonitor2 /home/mqperf/cph/

USER mqperf
WORKDIR /home/mqperf/cph

ENV MQ_QMGR_NAME=PERF0
ENV MQ_QMGR_PORT=1414
ENV MQ_QMGR_CHANNEL=SYSTEM.DEF.SVRCONN
ENV MQ_QMGR_QREQUEST_PREFIX=REQUEST
ENV MQ_QMGR_QREPLY_PREFIX=REPLY
ENV MQ_NON_PERSISTENT=
ENV MQ_CPH_EXTRA=
ENV MQ_USERID=

ENTRYPOINT ["sudo", "/home/mqperf/cph/cphTest.sh"]
