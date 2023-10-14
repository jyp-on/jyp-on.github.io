+++
title = "Linux 일반 사용자 Root 권한 추가"
tags = [
    "root", "ubuntu", "ssh", "Permission Denied" 
]
date = "2023-10-13T2:16:00-06:00"
categories = ["Linux"]
+++


## 본 포스팅은 Ubuntu 22.04.3 LTS 환경을 사용하고 있습니다.


1. super user 리스트에 들어가서 다음과 같이 일반 사용자에게도 super user 권한을 등록합니다.

``` bash
// 꼭 sudo를 붙여줘야 수정 가능합니다.
sudo vi /etc/sudoers
```

![](/Linux일반사용자/1.png)

2. uid, gid를 0으로 수정합니다.
``` bash
vi /etc/passwd
```

![](/Linux일반사용자/2.png)

3. root group에서 내가 사용할 사용자의 username을 적는다
``` bash
vi /etc/group
```

![](/Linux일반사용자/3.png)

여기까지 하면 jyp라는 사용자에게 root권한을 부여하는 것이 끝났습니다.  
하지만 jyp를 ssh를 통해서 원격으로 접속할 시 Permission Denied가 됩니다.

SSH의 설정 파일중 default로 Root권한을 가진 사용자로는 SSH 접속을 막기 때문입니다.  
다음과 같은 설정들로 이를 해결 할 수 있습니다.

``` bash
vi /etc/ssh/sshd_config

...
// 주석처리된 것들을 해제하고 yes 문자열이 뒤에 있어야 합니다.

PermitRootLogin yes
PasswordAuthentication yes
```

- 마지막으로 바뀐 설정들을 적용하기 위해 **sudo service ssh restart** 를 통해 SSH를 재시작 해주면 외부에서도 SSH를 통해 잘 접속할 수 있습니다.
