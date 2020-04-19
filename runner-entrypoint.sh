#!/bin/sh

# parse branch
if [ -f $GITHUB_EVENT_PATH ]; then
  # TODO: remove, for debugging only
	cat $GITHUB_EVENT_PATH

	touch /tmp/variables.json

	# Codefresh system provided variables
	# https://codefresh.io/docs/docs/codefresh-yaml/variables/#system-provided-variables
	REVISION=$(cat $GITHUB_EVENT_PATH | jq -r .head_commit.id)
	REPO_OWNER=$(cat $GITHUB_EVENT_PATH | jq -r .repository.organization)
	REPO_NAME=$(cat $GITHUB_EVENT_PATH | jq -r .repository.name)

	jq -n --arg revision $REVISION --arg repo_owner $REPO_OWNER --arg repo_name $REPO_NAME  \
		'[{"CF_REVISION":"\($revision)", "CF_REPO_OWNER": "\($repo_owner)", "CF_REPO_NAME": "\($repo_name)" }]' > /tmp/variables.json

	cat /tmp/variables.json

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
	codefresh run $PIPELINE_ID --trigger=$TRIGGER_NAME --branch=$BRANCH --var-file=/tmp/variables.json
else
	codefresh run $PIPELINE_ID --branch=$BRANCH --var-file=/tmp/variables.json
fi
