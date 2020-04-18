#!/bin/sh

# parse branch
if [ -f $GITHUB_EVENT_PATH ]; then
  # TODO: remove, for debugging only
	cat $GITHUB_EVENT_PATH
	
	# Codefresh system provided variables
	# https://codefresh.io/docs/docs/codefresh-yaml/variables/#system-provided-variables
	touch /tmp/codefresh_system_variables
	echo "CF_REVISION=$(cat $GITHUB_EVENT_PATH | jq -r .head_commit.id)" > /tmp/codefresh_system_variables
	echo "REPO_ORG=$(cat $GITHUB_EVENT_PATH | jq -r .repository.organization)" > /tmp/codefresh_system_variables
	echo "REPO_NAME=$(cat $GITHUB_EVENT_PATH | jq -r .repository.name)" > /tmp/codefresh_system_variables

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
	codefresh run $PIPELINE_ID --trigger=$TRIGGER_NAME --branch=$BRANCH --var-file=/tmp/codefresh_system_variables
else
	codefresh run $PIPELINE_ID --branch=$BRANCH --var-file=/tmp/codefresh_system_variables
fi
