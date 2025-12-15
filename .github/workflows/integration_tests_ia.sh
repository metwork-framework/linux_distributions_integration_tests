#!/bin/bash

set -e

BASE=$(echo "${IMAGE}" |awk -F ':' '{print $1;}')
if test "${BASE}" = "debian"; then
    BACKEND="apt-get"
elif test "${BASE}" = "ubuntu"; then
    BACKEND="apt-get"
elif test "${BASE}" = "fedora"; then
    BACKEND="dnf"
elif test "${BASE}" = "centos"; then
    BACKEND="dnf"
elif test "${BASE}" = "rockylinux"; then
    BACKEND="dnf"
elif test "${BASE}" = "rockylinux/rockylinux"; then
    BACKEND="dnf"
elif test "${BASE}" = "almalinux"; then
    BACKEND="dnf"
elif test "${BASE}" = "dokken/centos-stream-8"; then
    BACKEND="dnf"
elif test "${BASE}" = "dokken/centos-stream-9"; then
    BACKEND="dnf"
else
    echo "ERROR: can't find a backend for ${BASE}"
    exit 1
fi

if test "${BACKEND}" = "apt-get"; then
    if test "${BASE}" = "ubuntu"; then
        cat /etc/apt/sources.list |grep -v '^#' |sed 's~http[^ ]* ~mirror://mirrors.ubuntu.com/mirrors.txt ~g' >/etc/apt/sources.list2
        mv -f /etc/apt/sources.list2 /etc/apt/sources.list
    fi
    apt-get update
    apt-get -y install apt-file
    apt-file update
fi

if test "${BACKEND}" = "dnf"; then
    echo "[metwork]" >/etc/yum.repos.d/metwork.repo
    echo "name=metwork" >>/etc/yum.repos.d/metwork.repo
    echo "baseurl=${REPOSITORY}/" >>/etc/yum.repos.d/metwork.repo
    echo "gpgcheck=0" >>/etc/yum.repos.d/metwork.repo
    echo "enabled=1" >>/etc/yum.repos.d/metwork.repo
    echo "metadata_expire=0" >>/etc/yum.repos.d/metwork.repo
    if test "${BASE}" = "rockylinux/rockylinux"; then
        dnf -y install epel-release
    fi
    dnf -y install metwork-mfext-layer-python3_ia
    mkdir mfextaddon_python3_ia
    cd mfextaddon_python3_ia
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_python3_ia src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
fi

