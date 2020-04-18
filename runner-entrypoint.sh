#!/bin/sh

# parse branch
if [ -f $GITHUB_EVENT_PATH ]; then
  # TODO: remove, for debugging only
	cat $GITHUB_EVENT_PATH

	# repo name and organization
	REPO_ORG=$(cat $GITHUB_EVENT_PATH | jq -r .repository.organization)
	REPO_NAME=$(cat $GITHUB_EVENT_PATH | jq -r .repository.name)

	# in case of push event
	BRANCH=$(cat $GITHUB_EVENT_PATH | jq -r .ref | awk -F '/' '{print $3}')

	if [ -z "$BRANCH" ]
    then
    	# in case of pull request event
    	BRANCH=$(cat $GITHUB_EVENT_PATH | jq -r head.ref)
    fi
else
	echo "Required file on path 'GITHUB_EVENT_PATH' not exists"
fi
codefresh auth create-context context --api-key $CF_API_KEY
codefresh auth use-context context


if [ -n "$TRIGGER_NAME" ]
then
	codefresh run $PIPELINE_ID --trigger=$TRIGGER_NAME --branch=$BRANCH -v CF_REPO_OWNER=$REPO_ORG -v CF_REPO_NAME=$REPO_NAME
else
	codefresh run $PIPELINE_ID --branch=$BRANCH -v CF_REPO_OWNER=$REPO_ORG -v CF_REPO_NAME=$REPO_NAME
fi
