+++
title = "Spring Boot [NaverCloud ObjectStorage] 사용법"
tags = [
    "Object Storage",
    "Naver Cloud"
]
date = "2023-09-02T16:14:00-06:00"
categories = ["spring boot"]
+++

이번에 진행하는 프로젝트에서 영상 및 JSON 파일을 object storage에 저장하는 서비스 로직을 추가하게 되었다

설명에 앞서 Amazon의 S3가 아닌 Ncloud의 objectStorage를 선정한 이유는 크게 4가지다.

1. 국내서비스라 문서읽기가 매우편함.

2. 최근 Ncloud의 Server, DB 등등 사용해봐서 익숙함.

3. AWS 과금에 당한적이있음.

4. objectstorage 1주간 사용해봤는데 파일 크기가 얼마안되는지 아직까지 0원 청구됨. (매우쌈)

Amazon의 S3랑 완벽하게 호환되고 국내서비스라 Docs를 읽을때 좀 더 쉽게 이해할 수 있었다
나는 spring boot 즉 java 언어를 사용하기 때문에 아래와 같은 Docs를 참고하여 사용하였음

[Object Stroage Docs](https://guide.ncloud-docs.com/docs/storage-storage-8-1)

[Java용 AWS SDK Guide](https://guide.ncloud-docs.com/docs/storage-storage-8-1)

aws s3랑은 다르게 리소스가 좀 부족하여 개인적으로 커스터마이징을 하여서 사용하였는데 지금부터 어떻게 사용하였는지 설명하려고 한다

먼저 object storage를 사용신청하고 bucket을 만들어야한다.

나는 rehab이라는 bucket을 만들어놓았다.

추가적으로 json이랑 video 파일을 업로드할 폴더를 구분해놓았다. (이건 자유)

![Alt text](/NaverCloud-ObjectStroage/img1.png)


**gradle 설정**

나는 spring boot 2.7.14, jdk 11을 사용하였고 밑에 의존성을 추가하였다

``` gradle
implementation 'com.amazonaws:aws-java-sdk-s3:1.11.238'
```

## 1. ncloud에서 access-key, secret-key 발급

마이페이지 -> 인증키 관리 (여기서 인증키를 발급하면 된다)

## 2. application.yml 작성

발급받은 키를 작성해주고 사용할 bucket이름을 써주면된다.

git같은 공유저장소에 올릴꺼라면 보안상 이파일을 숨겨주어야 한다.

필자는 따로 application-secret 을 따로만들어서 prifiles로 불러왔다.

``` yml
cloud:
  aws:
    credentials:
      access-key: ""
      secret-key: ""
    stack:
      auto: false
    region:
      static: ap-northeast-2
    s3:
      endpoint: https://kr.object.ncloudstorage.com
      bucket: "rehab"
```

## 3. S3Client 설정파일 만들기

@Configuration을 통해 설정파일을 만들어준다. (Configuration은 싱글톤을 유지해줘서 설정파일에 많이쓰인다고함)

외부에서 S3Client의 getAmazonS3 메소드를 이용해 s3 객체를 사용할 수 있도록 Bean 등록 해주었다.

Amazon s3와 연동되게 만들어서 그런지 AmazonS3를 반환해서 사용한다.

``` java
@Configuration
public class S3Client {

    @Value("${cloud.aws.credentials.access-key}")
    private String accessKey;

    @Value("${cloud.aws.credentials.secret-key}")
    private String secretKey;

    @Value("${cloud.aws.s3.endpoint}")
    private String endPoint;

    @Value("${cloud.aws.region.static}")
    private String regionName;

    public AmazonS3 getAmazonS3() {
        return AmazonS3ClientBuilder.standard()
                .withEndpointConfiguration(new AwsClientBuilder.EndpointConfiguration(endPoint, regionName))
                .withCredentials(new AWSStaticCredentialsProvider(new BasicAWSCredentials(accessKey, secretKey)))
                .build();
    }
}
```

## 4. UploadAPI 구현

필자의 서비스로직 중 upload부분만 따로 가져왔다.

나는 MultipartFile들을 받아 File로 변환 후 S3에 경로를 지정후 저장해준다. (File로 변환해야 저장할수있음)

Path와 URL이 각각 존재하는 이유는 Path는 Object Stroage에 실제로 저장되는 경로이고 URL은 사용자가 접근 하여 파일을 얻을 수 있는 경로이다.

필자는 Path와 URL 둘다 DB에 저장하여 Path는 파일을 object storage에서 삭제할 때 사용하고 URL은 Client에게 접근할 수 있는 URL을 주기위해 사용한다. 참고로 URL은 object storage에서 파일 생성시 만들어주는데 만드는 방식이 일정해서 필자가 따로 URL을 예측하여 DB에 저장한다.

Path에서 video/, json/ 이 경로가 아까만든 bucket에 만든 폴더라고 보면된다.

추가적으로 uuid를 만들어 파일명 앞에 붙여놓았다. 같은 파일이름이 있으면 에러가 나기때문.

전달받은 이미지들은 spring이 정해진 임시저장소에 저장하는데 file upload가 끝나면 삭제처리를 해주었다. 

``` java
public UploadFileDTO uploadFileToS3(MultipartFile videoFile, MultipartFile jsonFile, Program program) {
    AmazonS3 s3 = s3Client.getAmazonS3();

    UUID uuid = UUID.randomUUID();
    String videoFileName = uuid + "_" + videoFile.getOriginalFilename();
    String jsonFileName = uuid + "_" + jsonFile.getOriginalFilename();

    File uploadVideoFile = null;
    File uploadJsonFile = null;

    try {
        uploadVideoFile = convertMultipartFileToFile(videoFile, videoFileName);
        uploadJsonFile = convertMultipartFileToFile(jsonFile, jsonFileName);

        String guideVideoObjectPath = "video/" + videoFileName;
        String jsonObjectPath = "json/" + jsonFileName;

        s3.putObject(bucketName, guideVideoObjectPath, uploadVideoFile);
        s3.putObject(bucketName, jsonObjectPath, uploadJsonFile);

        String baseUploadURL = "https://kr.object.ncloudstorage.com/" + bucketName + "/";
        String guideVideoURL = baseUploadURL + guideVideoObjectPath;
        String jsonURL = baseUploadURL + jsonObjectPath;

        log.info(guideVideoURL);
        log.info(jsonURL);

        setAcl(s3, guideVideoObjectPath);
        setAcl(s3, jsonObjectPath);

        return UploadFileDTO.builder()
                .guideVideoURL(guideVideoURL)
                .jsonURL(jsonURL)
                .guideVideoObjectPath(guideVideoObjectPath)
                .jsonObjectPath(jsonObjectPath)
                .build();

    } catch (AmazonS3Exception e) { // ACL Exception
        log.info(e.getErrorMessage());
        System.exit(1);
        return null; // 업로드 오류 시 null 반환
    } finally {
        // 업로드에 사용한 임시 파일을 삭제합니다.
        if (uploadVideoFile != null) uploadVideoFile.delete();
        if (uploadJsonFile != null) uploadJsonFile.delete();
    }
}
```

또 설명할 중요한 부분이 남아있다.

bucket은 폴더, 파일 단위로 외부에 공개할 수 있는 설정 권한을 매번 설정해줘야하는데 다음과 같이 변경하면

![Alt text](/NaverCloud-ObjectStroage/img2.png)

json/ 밑에 생기는 파일들은 새로 생기는 파일들이라 다시 외부에 비공개가되어 이짓거리를 매번 해줘야한다.

그래서 생각해낸 방법이 파일을 생성하자마자 그 파일에 대한 권한을 바꾸는 방법이다.

Docs를 찾아보니 ACL 권한을 수정하는 API가 존재하였다.

필자는 setAcl 이라는 메소드를 지정해서 s3 인스턴스와 Path를 넘겨서 처리하였다.

``` java
public void setAcl(AmazonS3 s3, String objectPath) {
    AccessControlList objectAcl = s3.getObjectAcl(bucketName, objectPath);
    objectAcl.grantPermission(GroupGrantee.AllUsers, Permission.Read);
    s3.setObjectAcl(bucketName, objectPath, objectAcl);
}
```

이런식으로 Read권한을 설정해주면 등록 한 후 권한을 바로 바꿔주어서 URL로 Client가 바로 접근가능하다.

## 5. Delete API 구현

마찬가지로 bucketname과 Path를 이용하여 삭제 요청을 하면된다.

``` java
public void deleteFileFromS3(String guideVideoObjectPath, String jsonObjectPath) {
    AmazonS3 s3 = s3Client.getAmazonS3();

    try {
        s3.deleteObject(bucketName, guideVideoObjectPath);
        s3.deleteObject(bucketName, jsonObjectPath);
        log.info("Delete Object successfully");
    } catch(SdkClientException e) {
        e.printStackTrace();
        log.info("Error deleteFileFromS3");
    }
}
```
