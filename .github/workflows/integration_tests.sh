#!/bin/bash

BASE=$(echo "${IMAGE}" |awk -F ':' '{print $1;}')
if test "${BASE}" = "debian"; then
    BACKEND="apt-get"
elif test "${BASE}" = "ubuntu"; then
    BACKEND="apt-get"
elif test "${BASE}" = "fedora"; then
    BACKEND="yum"
elif test "${BASE}" = "centos"; then
    BACKEND="yum"
elif test "${BASE}" = "rockylinux"; then
    BACKEND="yum"
elif test "${BASE}" = "opensuse/leap"; then
    BACKEND="zypper"
elif test "${BASE}" = "mageia"; then
    BACKEND="urpmf"
else
    echo "ERROR: can't find a backend for ${BASE}"
    exit 1
fi

if test "${BACKEND}" = "apt-get"; then
    echo "***** PREPARING *****"
    echo
    if test "${BASE}" = "ubuntu"; then
        cat /etc/apt/sources.list |grep -v '^#' |sed 's~http[^ ]* ~mirror://mirrors.ubuntu.com/mirrors.txt ~g' >/etc/apt/sources.list2
        mv -f /etc/apt/sources.list2 /etc/apt/sources.list
    fi
    apt-get update
    apt-get -y install apt-file
    apt-file update
    echo
    echo
fi

if test "${BACKEND}" = "yum"; then
    echo "[metwork]" >/etc/yum.repos.d/metwork.repo
    echo "name=metwork" >>/etc/yum.repos.d/metwork.repo
    echo "baseurl=${REPOSITORY}/" >>/etc/yum.repos.d/metwork.repo
    echo "gpgcheck=0" >>/etc/yum.repos.d/metwork.repo
    echo "enabled=1" >>/etc/yum.repos.d/metwork.repo
    echo "metadata_expire=0" >>/etc/yum.repos.d/metwork.repo
    yum -y install metwork-mfext-full git
    git clone -b ${DRONE_BRANCH} https://github.com/metwork-framework/mfext src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
else
    echo "Not yet implemented for ${BACKEND}"
fi
