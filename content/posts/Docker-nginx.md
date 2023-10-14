+++
title = "Docker에 nginx 컨테이너 올리기"
tags = [
    "nginx", "container", "apache"
]
date = "2023-10-05T2:16:00-12:00"
categories = ["Docker"]
+++

Docker에 nginx를 올리는 방법은 다음과 같다.

```bash
// 5121 포트로 들어가면 nginx가 받아서 80포트로 넘겨준다.
docker run -dit --name {name} -p 5121:80 nginx
```

하지만 이렇게 올리면 nginx 컨테이너의 bash로 들어가서 정적파일들을 특정 장소에 위치시켜줘야한다.

nginx 컨테이너 bash에 들어가는 방법은 다음과 같다.

```bash
docker exec -it {컨테이너이름} /bin/bash -exec는 뒤에 명령어를 실행 하는 것
or
docker attach {컨테이너이름} -바로 컨테이너에 들어가는 것
```

- -it 명령어는 컨테이너 속 터미널 입력을 할수 있도록 하는데 터미널에서 /bin/bash를 실행해서 bash shell로 들어갈수 있다.

하지만 볼륨을 이용해서 로컬에있는 정적파일을 nginx의 특정 장소에 바로 매핑해주면 로컬에서 파일을 자동으로 매핑해준다.

```bash
docker run -d --name {컨테이너이름} -p 5121:80 -v /$(pwd)$/webroot/:/usr/share/nginx/html:ro nginx
```

- -d (detach mode) 명령어는 기본적으로 포그라운드에서 실행되는 컨테이너를 백그라운드로 분리하라는 명령어다. (콘솔창을 바로 사용가능하다)
- --name 명령어는 컨테이너 이름을 지정해주는 명령어다.
- -p 명령어는 클라이언트에서 5121 port로 접속하면 컨테이너 내의 80 포트로 넘겨준다.
- -v 명령어는 -v {호스트폴더}:{컨테이너폴더} 로 파일을 매핑해준다.
- :ro는 read only로 로컬저장소의 파일을 불러올떄 읽기만 허용하도록 한다.

아파치의 컨테이너 폴더는 다음과 같다.

```bash
docker run -dit --name {컨테이너이름} -p 5121:80 -v {호스트폴더}:/usr/local/apache2/htdocs/ httpd
```

만약 -d 를 안쓰고 포그라운드로 들어갔다면
exit으로 나올수 있지만 CTRL+p, CTRL_q 를 순서대로 입력하면 된다.


