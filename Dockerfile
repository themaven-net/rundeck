# Dockerfile for rundeck
# https://github.com/jjethwa/rundeck

FROM debian:jessie

MAINTAINER Jordan Jethwa

ENV DEBIAN_FRONTEND=noninteractive \
    SERVER_URL=https://localhost:4443 \
    RUNDECK_STORAGE_PROVIDER=file \
    RUNDECK_PROJECT_STORAGE_TYPE=file \
    NO_LOCAL_MYSQL=false

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \
    apt-get -qq update && \
    apt-get -qqy install -t jessie-backports --no-install-recommends bash openjdk-8-jre-headless ca-certificates-java supervisor procps sudo ca-certificates openssh-client mysql-server mysql-client pwgen curl git uuid-runtime build-essential jq python-pip python python2.7-dev libyaml-dev libpython2.7-dev net-tools lsof unzip && \
    cd /tmp/ && \
    curl -Lo /tmp/rundeck.deb http://dl.bintray.com/rundeck/rundeck-deb/rundeck-2.7.3-1-GA.deb && \
    echo 'ee70fb57187d1fec136d20835bf64c11b4be4735480d48fab93a8ab5ed90013f  rundeck.deb' > /tmp/rundeck.sig && \
    shasum -a256 -c /tmp/rundeck.sig && \
    curl -Lo /tmp/rundeck-cli.deb https://github.com/rundeck/rundeck-cli/releases/download/v1.0.7/rundeck-cli_1.0.7-1_all.deb && \
    echo 'f9cf3348559b2135283d50d96e387b8014ec1b570e3ff67f978720cb367ceb4f  rundeck-cli.deb' > /tmp/rundeck-cli.sig && \
    shasum -a256 -c /tmp/rundeck-cli.sig && \
    cd - && \
    dpkg -i /tmp/rundeck*.deb && rm /tmp/rundeck*.deb && \
    chown rundeck:rundeck /tmp/rundeck && \
    mkdir -p /var/lib/rundeck/.ssh && \
    chown rundeck:rundeck /var/lib/rundeck/.ssh && \
    sed -i "s/export RDECK_JVM=\"/export RDECK_JVM=\"\${RDECK_JVM} /" /etc/rundeck/profile && \
    curl -Lo /var/lib/rundeck/libext/rundeck-slack-incoming-webhook-plugin-0.6.jar https://github.com/higanworks/rundeck-slack-incoming-webhook-plugin/releases/download/v0.6.dev/rundeck-slack-incoming-webhook-plugin-0.6.jar && \
    echo 'd23b31ec4791dff1a7051f1f012725f20a1e3e9f85f64a874115e46df77e00b5  rundeck-slack-incoming-webhook-plugin-0.6.jar' > /tmp/rundeck-slack-plugin.sig && \
    cd /var/lib/rundeck/libext/ && \
    shasum -a256 -c /tmp/rundeck-slack-plugin.sig && \
    cd - && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ADD content/ /
RUN chmod u+x /opt/run && \
    mkdir -p /var/log/supervisor && mkdir -p /opt/supervisor && \
    chmod u+x /opt/supervisor/rundeck && chmod u+x /opt/supervisor/mysql_supervisor

RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin

RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
    unzip awscli-bundle.zip && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
    rm -rf awscli-bundle*

EXPOSE 4440 4443

VOLUME  ["/etc/rundeck", "/var/rundeck", "/var/lib/rundeck", "/var/lib/mysql", "/var/log/rundeck", "/opt/rundeck-plugins", "/var/lib/rundeck/logs", "/var/lib/rundeck/var/storage"]

ENTRYPOINT ["/opt/run"]
