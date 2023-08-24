#!/bin/bash

#set -eu
set -x

TAG=

    
case "${GITHUB_EVENT_NAME}" in
    repository_dispatch)
        B=${PAYLOAD_BRANCH};;
    workflow_dispatch)
	B=$(WORKFLOW_BRANCH);;
    pull_request)
        case "${GITHUB_BASE_REF}" in
            master | integration | experimental* | release_* | ci* | pci*)
                B=${GITHUB_BASE_REF};;
            *)
                B=null;
        esac;;
    push)
        case "${GITHUB_REF}" in
            refs/tags/v*)
                B=`git branch -a --contains "${GITHUB_REF}" | grep remotes | grep release_ | cut -d"/" -f3`;;
            refs/heads/*)
                B=${GITHUB_REF#refs/heads/};;
            *)
                B=null;
        esac;;
esac
if [ -z ${B} ]; then
  B=null
fi
if [ "${GITHUB_EVENT_NAME}" != "repository_dispatch" ]; then
    case "${GITHUB_REF}" in
        refs/tags/v*)
            TAG=${GITHUB_REF#refs/tags/};;
    esac
fi

if [ -z ${TAG} ]; then
  CI=continuous_integration
else
  CI=releases
fi

echo "branch=${B}" >> ${GITHUB_OUTPUT}
echo "tag=${TAG}" >> ${GITHUB_OUTPUT}
echo "repository=http://metwork-framework.org/pub/metwork/${CI}/rpms/${B}/portable/" >> ${GITHUB_OUTPUT}
