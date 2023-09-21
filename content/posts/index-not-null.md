+++
title = "jpa error - (integer not null)"
tags = [
    "jpa"
]
date = "2023-09-21T2:16:00-06:00"
categories = ["spring boot", "error"]
+++
오늘 jpa entity를 설계하다가 예상치 못한 에러를 겪은 썰을 풀고자 한다..  
문제의 Entity는 다음과 같다.

```java
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "reservation_time")
@Entity
public class Time {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long tno;

    private LocalDate date;

    private int index;

    @JsonBackReference
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mid", nullable = false)
    private Admin admin;

    public void setAdmin(Admin admin) {
        this.admin = admin;
    }
}
```

문제점을 찾았으면 이 글을 더이상 보지 않아도 된다.
엔티티에 대한 설명을 간단히 하자면 관리자의 예약시간을 저장하는 엔티티이다.  
예약을 받으면 Time entity에 1개의 row가 생기고 admin과 연관관계를 맺는다.

하지만 위처럼 코드를 작성하면 다음과 같은 에러를 마주한다.
``` text
WARN 37304 --- [  restartedMain] o.m.jdbc.message.server.ErrorPacket
      : Error: 1064-42000: You have an error in your SQL syntax; 
      check the manual that corresponds to 
      your MariaDB server version for the right syntax to use near 'integer not null,
```
나는 이것을 보고 왜 이런 오류가 뜨는지 이유를 알 수 없었다.   
 ***sql을 직접 짠 것도 아닌데 syntax Error..?***

 영문을 몰라서 나의 영원한 친구 뤼튼에게 질문을 해보았지만 얘도 계속 잘못짚길래 다시 영원한 고통으로 빠져들었다...
 좀 더 고민을 해보니 date나 index 라는 컬럼명이 눈에 들어왔다.  
  ***설마 예약어가 겹쳐서..?***  

index라는 예약어가 있었던 것 같은 생각이 주마등을 스쳐갔다.
아래와 같이 바꾸니 ddl 문이 정상적으로 작동하였다.. ㅠ
```java
@Column(name = "time_index")
private int index;
```

## 오늘의 교훈 : 좀 더 창의적으로 의심하자.
