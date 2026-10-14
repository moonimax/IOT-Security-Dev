
![](Images/Pasted%20image%2020261014141013.png)

es 클러스터 상태 확인
- 운영중인 클러스터 명 : elasticsearch
	- status - green
	- total node - 1
	- data shards - 1
	- shards - 8
- 건강하게 클러스터가 잘 돌아가고 있음을 확인할 수 있다.

![](Images/Pasted%20image%2020261014141549.png)

Es 노드 상태 확인
- 노드가 운영되고 있는 서버 ip :  127.0.0.1


---

Elasticsearch 데이터 처리 실습(CRUD)
```bash
#kisec 인덱스 생성
curl -XPUT localhost:9200/man_1?pretty

#생성된 인덱스 확인
curl localhost:9200/man_1?pretty

#id가 1인 document 생성
curl -XPUT "http://localhost:9200/man_1/_doc/1?pretty" -H 'Content-Type: application/json' -d'
{
"name" : "Moon",
"age" : 20
}'

#man_1 인덱스 내에서 document id가 1인 문서 조회
curl -XGET localhost:9200/man_1/_doc/1?pretty

#_create를 사용하여 도큐먼트 중복 방지
curl -XPUT "http://localhost:9200/man_1/_create/1?pretty" -H 'Content-Type: application/json' -d'
{
"name": SuperMario
"age" : 30
}'


#document 1에서 age 필드 수정
curl -XPUT "http://local:9200/man_1/_doc/1?pretty" -H 'Content-Type: application/json' -d'
{
"age" : 43
}'

curl -XPUT "http://local:9200/man_1/_update/1?pretty" -H 'Content-Type: application/json' -d'
{
"age" : 43
}'
# document에 field값이 여러 개일 때 일괄적으로 수정 가능


```