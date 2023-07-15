# syntax=docker/dockerfile:1

# Author: Austin Hunt
# Date: 12 July 2023
# Version: 1.0

# Purpose of the Dockerfile:
# Build the Zeek container image

# Usage:
# Don't touch this unless you know how to or you want to tinker

# Edit this ZEEK_TAG arg value if you want to use a different tag number from zeekurity/zeek
ARG ZEEK_TAG=lts
FROM zeek/zeek:${ZEEK_TAG}
RUN apt update && apt install -y gdb iproute2 vim ip
# Edit this ZEEK_HOME_DIR arg value to /opt/zeek/ if your installation uses that directory instead
ARG ZEEK_HOME_DIR=/usr/local/zeek/
# Edit this ZEEK_LISTEN_INTERFACE arg value to your NIC's name so Zeek can listen on the right network interface
# This is set as the start_zeek_docker script is running.
ARG ZEEK_LISTEN_INTERFACE=
# Edit this PORT arg value to change the default port number that Zeek listens on.
ARG ZEEK_PORT_NUM=27760
# Force Zeek to log files in json format.
# Set a Zeek port number so the container doesn't error out.
# Set log rotation to 1 day.
ARG ZEEK_LOG_ROTATION_INTERVAL=86400
# The Zeek logs are under ${ZEEK_HOME_DIR}logs/current -> ${ZEEK_HOME_DIR}spool/zeek/
# Disable the zeek emails
RUN echo "# Output logs in json format"       | tee -a ${ZEEK_HOME_DIR}share/zeek/site/local.zeek && \
    echo "@load policy/tuning/json-logs.zeek" | tee -a ${ZEEK_HOME_DIR}share/zeek/site/local.zeek && \
    echo "10.0.0.0/8"                         | tee -a ${ZEEK_HOME_DIR}etc/networks.cfg && \
    echo "172.16.0.0/12"                      | tee -a ${ZEEK_HOME_DIR}etc/networks.cfg && \
    echo "192.168.0.0/16"                     | tee -a ${ZEEK_HOME_DIR}etc/networks.cfg && \
    echo "# Set zeek port number"             | tee -a ${ZEEK_HOME_DIR}etc/zeekctl.cfg && \
    echo "ZeekPort = ${ZEEK_PORT_NUM}"        | tee -a ${ZEEK_HOME_DIR}etc/zeekctl.cfg && \
    echo "# Disable Zeek Emails"              | tee -a ${ZEEK_HOME_DIR}etc/zeekctl.cfg && \
    echo "SendMail ="                         | tee -a ${ZEEK_HOME_DIR}etc/zeekctl.cfg && \
    sed -Ei "s/^LogRotationInterval.*/LogRotationInterval = ${ZEEK_LOG_ROTATION_INTERVAL}/"   ${ZEEK_HOME_DIR}etc/zeekctl.cfg && \
    sed -Ei "s/^interface=.*/interface=${ZEEK_LISTEN_INTERFACE}/" ${ZEEK_HOME_DIR}etc/node.cfg
CMD zeekctl deploy && while true; do sleep 30s; done
