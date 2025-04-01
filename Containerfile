FROM image-registry.openshift-image-registry.svc:5000/openshift/ubi8-openjdk-21:1.18 AS builder

ARG KCB_RELEASE="26.1-SNAPSHOT"
ARG KC_RELEASE="26.1.4"
ARG KCB_RESULTS_PATH="/opt/keycloak-benchmark/results"

ENV NAME=keycloak-benchmark

ENV SUMMARY="Platform for running Keycloak performance tests and serving results over Apache httpd server" \
    DESCRIPTION="Apache httpd is started in the backgroup and Keycloak benchmark tests run on foreground. \
Parameters for the performance tests can be set using environment variables. \
The HTML report of results is served by Apache httpd server."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Keycloak-benchmark" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,$NAME" \
      name="ubi9/$NAME" \
      maintainer="Lucas Burigo" \
      version="1"

EXPOSE 8080

USER root
RUN microdnf install jq util-linux httpd -y && \
    microdnf clean all && \
    rm -rf /var/cache/yum

WORKDIR /opt

RUN adduser \
    --no-create-home \
    --system \
    kcb

ADD https://github.com/keycloak/keycloak/releases/download/${KC_RELEASE}/keycloak-${KC_RELEASE}.tar.gz .
ADD https://github.com/keycloak/keycloak-benchmark/releases/download/${KCB_RELEASE}/keycloak-benchmark-${KCB_RELEASE}.tar.gz .
RUN tar -zxf keycloak-${KC_RELEASE}.tar.gz && \
    tar -zxf keycloak-benchmark-${KCB_RELEASE}.tar.gz && \
    mv keycloak-${KC_RELEASE} keycloak && \
    mv keycloak-benchmark-${KCB_RELEASE} keycloak-benchmark && \
    rm /opt/keycloak-${KC_RELEASE}.tar.gz && \
    rm /opt/keycloak-benchmark-${KCB_RELEASE}.tar.gz && \
    mkdir ${KCB_RESULTS_PATH} && \
    chgrp -R 0 /opt && \
    chmod -R g=u /opt

RUN sed -i 's/#ServerName.*/ServerName localhost:8080/' /etc/httpd/conf/httpd.conf && \
    sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf && \
    sed -i 's/User apache/User kcb/' /etc/httpd/conf/httpd.conf && \
    sed -i 's/Group apache/Group root/' /etc/httpd/conf/httpd.conf && \
    chown -R kcb:0 /var/log/httpd && \
    chmod -R g=u /var/log/httpd && \
    chown -R kcb:0 /run/httpd && \
    chmod -R g=u /run/httpd && \
    chown -R kcb:0 /etc/httpd && \
    chmod -R g=u /etc/httpd && \
    rm -rf /var/www/html && \
    ln -s ${KCB_RESULTS_PATH} /var/www/html && \
    chown -R kcb:0 /var/www/html && \
    chmod -R g=u /var/www/html

USER kcb
COPY start_perf_test.sh .

CMD ["bash", "start_perf_test.sh"]