#!/bin/bash

set -e

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
    echo "[metwork]" >/etc/yum.repos.d/metwork.repo
    echo "name=metwork" >>/etc/yum.repos.d/metwork.repo
    echo "baseurl=${REPOSITORY}/" >>/etc/yum.repos.d/metwork.repo
    echo "gpgcheck=0" >>/etc/yum.repos.d/metwork.repo
    echo "enabled=1" >>/etc/yum.repos.d/metwork.repo
    echo "metadata_expire=0" >>/etc/yum.repos.d/metwork.repo
    #yum -y update
    mkdir mfext mfextaddon_scientific mfextaddon_mapserver mfextaddon_python3_ia
    yum -y install metwork-mfext-full
    cd mfext
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfext src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    yum -y remove metwork-mfext
    yum -y install metwork-mfext-layer-python3_scientific
    cd ../mfextaddon_scientific
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_scientific src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    yum -y remove metwork-mfext-layer_scientific
    yum -y install metwork-mfext-layer-python3_mapserverapi
    cd ../mfextaddon_mapserver
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_mapserver src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    yum -y remove metwork-mfext-layer-mapserver
    yum -y install metwork-mfext-layer-python3_ia
    cd ../mfextaddon_python3_ia
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_python3_ia src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh

fi

if test "${BACKEND}" = "urpmf"; then
    urpmi.addmedia metwork ${REPOSITORY}
    #yes |urpmi.update -a
    yes | urpmi lib64apr1_0 lib64apr-util1_0
    yes |urpmi wget procmail tcsh
    yes |urpmi metwork-mfext-full metwork-mfext-layer-python3_scientific metwork-mfext-layer-python3_mapserverapi metwork-mfext-layer-python3_ia
    mkdir mfext mfextaddon_scientific mfextaddon_mapserver mfextaddon_python3_ia
    cd mfext
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfext src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    cd ../mfextaddon_scientific
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_scientific src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    cd ../mfextaddon_mapserver
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_mapserver src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    cd ../mfextaddon_python3_ia
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_python3_ia src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
fi

if test "${BACKEND}" = "zypper"; then
    zypper ar -G ${REPOSITORY} metwork_${BRANCH}
    zypper -n install metwork-mfext-full metwork-mfext-layer-python3_scientific
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfext src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
fi
