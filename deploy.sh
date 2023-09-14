#!/bin/bash

# Build the project.
hugo -t hello-friend-ng

# git내용들 추가
git pull origin main
git add .

msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# github.io 레포에 push
git push origin main