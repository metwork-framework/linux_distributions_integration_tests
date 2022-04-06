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
    if test "${BASE}" = "ubuntu"; then
        cat /etc/apt/sources.list |grep -v '^#' |sed 's~http[^ ]* ~mirror://mirrors.ubuntu.com/mirrors.txt ~g' >/etc/apt/sources.list2
        mv -f /etc/apt/sources.list2 /etc/apt/sources.list
    fi
    apt-get update
    apt-get -y install apt-file
    apt-file update
fi

if test "${BACKEND}" = "yum"; then
    yum -y update
    yum -y git
fi

if test "${BACKEND}" = "urpmf"; then
    yes |urpmi.update -a
    yes |urpmi lib64apr1_0 lib64apr-util1_0
    yes |urpmi git wget procmail
fi

if test "${BACKEND}" = "zypper"; then
    zypper -n install git
fi
