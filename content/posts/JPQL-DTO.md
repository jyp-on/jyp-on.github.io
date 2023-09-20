+++
title = "Spring Boot JPQL DTO Mapping"
tags = [
    "jpql", "jpa"
]
date = "2023-09-08T22:16:00-06:00"
# date = "2023-09-02T16:14:00-06:00"
categories = ["spring boot"]
+++
jpa를 사용할때 jpa repository에서 return 을 **DTO**로 변환해서 받을 수 있다.

jpql select 부분에서 DTO로 사용할 객체를 생성 해줘야한다.
주의할 점은 DTO 생성시 패키지 초반부분부터 적어줘야 찾을 수 있다.

먼저 Person 객체와 PersonDTO 객체가 있다고 가정하자.  

`Person 객체에는 name, age, email, id`,  
`PersonDTO 객체에는 name, age`  
이고 만약 최소 나이를 파라미터로 그 나이 이상의 Person 객체를 가져오고 싶다면 JPQL을 아래와 같이 구성 해야 한다.  

``` java
@Query(value = 
      "SELECT " +
      "new com.a.b.person.dto.PersonDTO(p.name, p.age) " +
      "FROM Person p " +
      "WHERE p.age >= :minAge")
List<PersonDTO> getDTOByAge(@Param("minAge") int minAge);
```
List<PersonDTO> 로 받아온 이유는 여러개의 데이터가 있을 수 있기 때문이다.  
만약 그냥 PersonDTO로 Return Type을 지정하였는데 2개 이상의 결과가 있으면 오류가 발생한다.

DTO 객체에 **Json Auto Detect** 어노테이션이 없으면 private field 접근을 못해서 json 변환이 안된다.  
또한 new 로 생성을 해줘야 하기 때문에 AllArgsConstructor도 넣어주자.

``` java
@AllArgsConstructor
@JsonAutoDetect(fieldVisibility = JsonAutoDetect.Visibility.ANY)
public class PersonDTO {
  private String name;
  private int age;
}
```

