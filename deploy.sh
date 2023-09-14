#!/bin/bash

# Build the project.
hugo -t hello-friend-ng

# github.io 레포 push위해 파일 경로 이동
cd public
# 충돌 방지를 위해 한번 pull
git pull origin main

# git내용들 추가
git add .

# Commit 바꾸기. git commit -m "원하는 커밋 메세지"를 입력하거나
# git commit만 입력시 커밋날짜를 메세지로 자동설정
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# github.io 레포에 push
git push origin main

# 상위 폴더인 blog도 push위해 경로 변경
cd ..

# blog 저장소 Commit & Push
# 충돌 방지를 위해 한번 pull
git pull origin main
git add .

msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

git push origin main