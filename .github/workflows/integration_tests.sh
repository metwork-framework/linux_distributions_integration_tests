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

if test "${BACKEND}" = "dnf"; then
    echo "[metwork]" >/etc/yum.repos.d/metwork.repo
    echo "name=metwork" >>/etc/yum.repos.d/metwork.repo
    echo "baseurl=${REPOSITORY}/" >>/etc/yum.repos.d/metwork.repo
    echo "gpgcheck=0" >>/etc/yum.repos.d/metwork.repo
    echo "enabled=1" >>/etc/yum.repos.d/metwork.repo
    echo "metadata_expire=0" >>/etc/yum.repos.d/metwork.repo
    dnf -y install metwork-mfext-full metwork-mfext-layer-python3_scientific metwork-mfext-layer-python3_extratools metwork-mfext-layer-python3_mapserverapi metwork-mfext-layer-python3_ia metwork-mfext-layer-python3_radartools
    mkdir mfext mfextaddon_scientific mfextaddon_mapserver mfextaddon_python3_ia mfextaddon_radartools
    dnf -y install metwork-mfserv metwork-mfdata metwork-mfbase metwork-mfadmin metwork-mfsysmon
    mkdir mfserv mfdata mfbase mfadmin mfsysmon
    yum -y install make cronie diffutils acl
    cd mfext
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfext src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    cd ../mfextaddon_radartools
    git clone -b ${BRANCH} https://metworkbot:${SECRET}@github.com/metwork-framework/mfextaddon_radartools src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    cd ../mfextaddon_scientific
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_scientific src
    export SPATIALINDEX_C_LIBRARY=/opt/metwork-mfext/opt/scientific/lib
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    cd ../mfextaddon_mapserver
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_mapserver src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    cd ../mfextaddon_python3_ia
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_python3_ia src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    cd ../mfserv
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfserv src
    su --command="mfserv.init" - mfserv
    su --command="mfserv.start" - mfserv
    su --command="mfserv.status" - mfserv
    chown -R mfserv src/integration_tests
    cd src/integration_tests
    su --command="cd `pwd`; ./run_integration_tests.sh" - mfserv
    cd -
    su --command="mfserv.stop" - mfserv
    cd ../mfdata
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfdata src
    su --command="mfdata.init" - mfdata
    su --command="mfdata.start" - mfdata
    su --command="mfdata.status" - mfdata
    chown -R mfdata src/integration_tests
    cd src/integration_tests; su --command="cd `pwd`; ./run_integration_tests.sh" - mfdata
    cd -
    su --command="mfdata.stop" - mfdata
    cd ../mfbase
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfbase src
    su --command="mfbase.init" - mfbase
    su --command="mfbase.start" - mfbase
    su --command="mfbase.status" - mfbase
    chown -R mfbase src/integration_tests
    cd src/integration_tests
    su --command="cd `pwd`; ./run_integration_tests.sh" - mfbase
    cd -
    su --command="mfbase.stop" - mfbase
    cd ../mfadmin
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfadmin src
    su --command="mfadmin.init" - mfadmin
    su --command="mfadmin.start" - mfadmin
    su --command="mfadmin.status" - mfadmin
    chown -R mfadmin src/integration_tests
    cd src/integration_tests
    su --command="cd `pwd`; ./run_integration_tests.sh" - mfadmin
    cd -
    su --command="mfadmin.stop" - mfadmin
    cd ../mfsysmon
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfsysmon src
    su --command="mfsysmon.init" - mfsysmon
    su --command="mfsysmon.start" - mfsysmon
    su --command="mfsysmon.status" - mfsysmon
    chown -R mfsysmon src/integration_tests
    cd src/integration_tests
    su --command="cd `pwd`; ./run_integration_tests.sh" - mfsysmon
    cd -
    su --command="mfsysmon.stop" - mfsysmon

fi

if test "${BACKEND}" = "urpmf"; then
    urpmi.addmedia metwork ${REPOSITORY}
    #yes |urpmi.update -a
    yes | urpmi lib64apr1_0 lib64apr-util1_0
    yes |urpmi wget procmail tcsh
    yes |urpmi metwork-mfext-full metwork-mfext-layer-python3_scientific metwork-mfext-layer-python3_extratools metwork-mfext-layer-python3_mapserverapi metwork-mfext-layer-python3_ia metwork-mfext-layer-python3_radartools
    yes |urpmi mfserv mfdata mfbase mfadmin mfsysmon
    mkdir mfext mfextaddon_scientific mfextaddon_mapserver mfextaddon_python3_ia mfextaddon_radartools
    mkdir mfserv mfdata mfbase mfadmin mfsysmon
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
    cd -
    cd ../mfextaddon_radartools
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfextaddon_radartools src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
    cd -
    cd ../mfserv
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfserv src
    su --command="mfserv.init" - mfserv
    su --command="mfserv.start" - mfserv
    su --command="mfserv.status" - mfserv
    chown -R mfserv src/integration_tests
    cd src/integration_tests
    su --command="cd `pwd`; ./run_integration_tests.sh" - mfserv
    cd -
    su --command="mfserv.stop" - mfserv
    cd ../mfdata
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfdata src
    su --command="mfdata.init" - mfdata
    su --command="mfdata.start" - mfdata
    su --command="mfdata.status" - mfdata
    chown -R mfdata src/integration_tests
    cd src/integration_tests; su --command="cd `pwd`; ./run_integration_tests.sh" - mfdata
    cd -
    su --command="mfdata.stop" - mfdata
    cd ../mfbase
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfbase src
    su --command="mfbase.init" - mfbase
    su --command="mfbase.start" - mfbase
    su --command="mfbase.status" - mfbase
    chown -R mfbase src/integration_tests
    cd src/integration_tests
    su --command="cd `pwd`; ./run_integration_tests.sh" - mfbase
    cd -
    su --command="mfbase.stop" - mfbase
    cd ../mfadmin
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfadmin src
    su --command="mfadmin.init" - mfadmin
    su --command="mfadmin.start" - mfadmin
    su --command="mfadmin.status" - mfadmin
    chown -R mfadmin src/integration_tests
    cd src/integration_tests
    su --command="cd `pwd`; ./run_integration_tests.sh" - mfadmin
    cd -
    su --command="mfadmin.stop" - mfadmin
    cd ../mfsysmon
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfsysmon src
    su --command="mfsysmon.init" - mfsysmon
    su --command="mfsysmon.start" - mfsysmon
    su --command="mfsysmon.status" - mfsysmon
    chown -R mfsysmon src/integration_tests
    cd src/integration_tests
    su --command="cd `pwd`; ./run_integration_tests.sh" - mfsysmon
    cd -
    su --command="mfsysmon.stop" - mfsysmon

fi


if test "${BACKEND}" = "zypper"; then
    zypper ar -G ${REPOSITORY} metwork_${BRANCH}
    zypper -n install metwork-mfext-full metwork-mfext-layer-python3_scientific metwork-mfext-layer-python3_extratools
    git clone -b ${BRANCH} https://github.com/metwork-framework/mfext src
    cd src/integration_tests && /opt/metwork-mfext/bin/mfext_wrapper ./run_integration_tests.sh
fi
