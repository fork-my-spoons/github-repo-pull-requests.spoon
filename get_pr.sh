#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No arguments provided"
    exit 1
fi

for var in "$@"
do
    dirname ~/.cache/github-pull-requests/$var | xargs mkdir -p 
    touch ~/.cache/github-pull-requests/$var
    /usr/local/bin/gh pr list --repo $var  --limit 15 --json "title,author,url,createdAt,isDraft" > ~/.cache/github-pull-requests/$var
done
