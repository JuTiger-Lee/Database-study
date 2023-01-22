/* id 순서 */
EXPLAIN 
SELECT 
 사원.사원번호, 
 사원.`이름`, 
 사원.`성`, 
 급여.`연봉`, 
 (SELECT MAX(부서번호) FROM 부서사원_매핑 AS 매핑 WHERE 매핑.사원번호 = 사원.사원번호) AS COUNT /*스칼라서브쿼리*/
FROM 사원, 급여
WHERE 사원.`사원번호` = 10001
AND 사원.`사원번호` = 급여.`사원번호`;

/*select type*/

/*--SIMPLE--*/
/*desc: UNION이나 내부쿼리가 없는 SELECT 문 단순한 SELECT 문을 의미*/
EXPLAIN SELECT * FROM 사원 WHERE 사원번호 = 100000;

EXPLAIN SELECT 사원.`사원번호`, 사원.`이름`, 사원.`성`, 급여.`연봉`
FROM 사원,
	(SELECT 사원번호, 연봉 FROM 급여 WHERE 연봉 > 80000) AS 급여
WHERE 사원.사원번호 = 급여.`사원번호` AND 사원.사원번호 BETWEEN 10001 AND 10010;

/*--PRIMARY--*/
/*desc: SQL문에서 처음 SELECT 구문이 작성된 쿼리가 먼저 접근한다는 의미로 PRIMARY가 출력*/
EXPLAIN SELECT 사원.사원번호, 사원.`이름`, 사원.`성`,
(
 SELECT MAX(부서번호) FROM 부서사원_매핑 AS 매핑 WHERE 매핑.사원번호 = 사원.`사원번호`
)AS mapping_count /*스칼라서브쿼리*/
FROM 사원 
WHERE 사원.`사원번호` = 100001;

EXPLAIN SELECT 사원1.사원번호, 사원1.이름, 사원1.성
FROM 사원 AS 사원1
WHERE 사원1.`사원번호` = 100001
UNION ALL
SELECT 사원2.사원번호, 사원2.이름, 사원2.성
FROM 사원 AS 사원2
WHERE 사원2.`사원번호` = 100002;


/*--SUBQUERY--*/
/*desc: 독립적으로 수행되는 서브쿼리 즉 outer 쿼리에 컬럼을 참조하지 않는 쿼리르 의미*/
EXPLAIN SELECT (SELECT COUNT(*) FROM 부서사원_매핑 AS 매핑) AS 카운트, (SELECT MAX(연봉) FROM 급여) AS 급여;

/*--DERIVED--*/
/*desc: from 절에 작성된 서브쿼리를 의미*/
EXPLAIN SELECT 사원.사원번호, 급여.`연봉` FROM 사원,
(SELECT 사원번호, MAX(연봉) AS 연봉 FROM 급여 WHERE 사원번호 BETWEEN 10001 AND 20000) AS 급여
WHERE 사원.사원번호 = 급여.사원번호;

/*--DEOEBEDEBT SUBQUERY--*/
/*desc: UNION 또는 UNION ALL을 사용하는 서브쿼리가 메인 테이블의 영향을 받는 경우, UNION으로 연결되는 첫번째 쿼리*/

/*--DEOEBEDEBT UNION--*/
/*desc: UNION 또는 UNION ALL을 사용하는 서브쿼리가 메인 테이블의 영향을 받는 경우, UNION으로 연결되는 두번째 쿼리*/

EXPLAIN SELECT 관리자.부서번호, 
(
	SELECT 사원1.이름 FROM 사원 AS 사원1 WHERE 성별 = 'F' AND 사원1.사원번호 = 관리자.사원번호 /*DEOEBEDEBT SUBQUERY*/
	UNION ALL
	SELECT 사원2.이름 FROM 사원 AS 사원2 WHERE 성별 = 'M' AND 사원2.사원번호 = 관리자.사원번호 /*DEOEBEDEBT UNION*/
) AS 이름
FROM 부서관리자 AS 관리자;

/*UNCACHEABLE SUBQUERY*/
/*desc: 메모리에 상주하여 재활용되어야할 서브쿼리가 재사용되지 못할 때 출력되는 유형*/
EXPLAIN SELECT * FROM 사원 WHERE 사원번호 = (SELECT ROUND(RAND()*1000000));

/*--MATERIALZED--*/
/*desc: IN절 구문에 연결된 서브쿼리가 임시 테이블을 생성한 뒤, 조인이나 가공 작업을 수행할 때 출려되는 유형
즉 IN 절의 서브쿼리를 임시 테이블로 만들어서 조인작업을 수행 */

EXPLAIN SELECT * FROM 사원 WHERE 사원번호 IN(SELECT 사원번호 FROM 급여 WHERE 시작일자 > '2020-01-01');

/*type*/

/*--system--*/
/*desc: 테이블에 데이터가 없거나 한개만 있는 경우 성능상 최상의 type */

/*--const--*/
/*desc: 조회되는 데이터가 단 1건일 때 출력되는 유형, 속도 및 리소스 사용 측면에서 지향해야할 타입*/

/*--eq_ref--*/
/*desc: 조인이 수행될 때 드리븐 테이블의 데이터에 접근하며 고유 인덱스 또는 기본키로 단 1건의 데이터를 조회하는 방식*/
EXPLAIN SELECT 매핑.사원번호, 부서.`부서번호`, 부서.`부서명` FROM 부서사원_매핑 AS 매핑, 부서 
WHERE 매핑.`부서번호` = 부서.`부서번호` AND 매핑.`사원번호` BETWEEN 100001 AND 100010;

/*--ref--*/
/*desc: eq_ref 유형과 유사한 방식 조인을 수행할 떄 드리븐 테이블의 데이터 접근 범위가 2개 이상일 경우를 의미*/
/*info: 1건의 사원 데이터 대비 여러개의 직급 데이터가 조회될 수 있는 구조, 드라이빙 테이블인 사원 테이블의 사원번호를 조인키로 삼아 직급 테이블의 접근, 
하지만 하나의 사원번호당 다수의 직급 데이터가 조회된다고 짐작이 가능*/
EXPLAIN SELECT 사원.`사원번호`, 직급.`직급명`
FROM 사원, 직급
WHERE 사원.`사원번호` = 직급.`사원번호`
AND 사원.`사원번호` BETWEEN 10001 AND 10100;

/*--ref_or_null--*/
/*desc: ref 유형과 유사 is null에 구문에 대해 인덱스를 활용하도록 최적화된 방식*/
/*info: mysql, mariadb는 null에 대해서도 인덱스를 활용해 검색이가능 이 때 null은 맨앞에 정렬
null 데이터양이 적다면 효율적이나 null 데이터양이 많다면 sql 튜닝 태상*/
EXPLAIN SELECT * FROM 사원출입기록 WHERE 출입문 IS NULL OR 출입문 = 'A';

/*--range--*/
/*desc: 테이블 내의 연속된 범위를 조회하는 유형, =,<>,>,>=,<,<=, is null, <=> between, in 연산을 통해 범위 스캔을 수행하는 방식*/
/*info: 스캔할 범위가 넓으면 저하의 요인이 될수있으므로 sql 튜닝 검토대상*/
EXPLAIN SELECT * FROM 사원 WHERE 사원번호 BETWEEN 10001 AND 1000000;

/*--fulltext--*/
/*desc: 텍스트 검색을 빠르게 처리하기위해 전문 인덱스(full text index)를 사용하여 데이터에 접근하는 방식*/

/*--index_merge--*/
/*desc: 결합된 인덱스들이 동시에 사용하는 유형, 테이블에 생성된 두개이상의 인덱스가 병홥되어서 동시에 적용, 이 때 전문 인덱스는 제외*/
EXPLAIN SELECT * FROM 사원 WHERE 사원번호 BETWEEN 10001 AND 100000 AND 입사일자 = '1985-11-21';

/*--index--*/
/*desc: 인덱스 풀스캔을 의미, 물리적인 인덱스 블록을 처음부터 끝까지 훑는 방식*/
/*info: 데이터 스캔 대상이 인덱스라는 점 뿐 테이블 풀스캔인 all 유형과 유사하며 풀스캔보다 빠를 가능성이 높음*/
EXPLAIN SELECT 사원번호 FROM 직급 WHERE 직급명 = 'Manager';

/*--ALL--*/
/*desc: 테이블을 처음부터 끝까지 읽는 테이블 풀 스캔 방식*/
/*info: all 유형은 활용 가능한 인덱스가 없거나 옵티마이저가 인덱스 사용이 비효율적이라 판단되었을 떄 선택
index를 추가하거나 변경하여 튜닝이 가능하나 전체 테이블 중 10~20% 이상 분량의 데이터를 조회할 떄는 ALL 유형이 성능상 유리*/
EXPLAIN SELECT * FROM 사원;

/*possible_keys*/
/*desc: 옵티마이저가 SQL문을 최적화하고자 사용할 수 있는 인덱스 목록을 출력*/

/*key*/
/*desc: 옵티마이저가 SQL문을 최적화하고자 사용한 기본 키 인덱스명을 의미*/
/*info: 어느 인덱스로 데이터를 검색했는지 확인이 가능*/

/*key_len*/
/*desc:인덱스를 사용할 때는 인덱스 전체를 사용하거나 일부 인덱스만 사요, key_len은 이렇게 사용한 인덱스의 바이트 수를 의미*/
/*info: '사원번호 + 직급명 + 시작일'열들로 구성된 PK 활용했는지 분석을 하자면 사원번호는 INT 데이터 유형으로 4바이트 varchar(50) 데이터 유형으로 (50+1) x 3 = 155바이트에 
해당 pk에서 사원번호의 4바이트 + 직급명 155바이트 => 159 즉 key_len은 159바이트가 출력되는거를 확인*/
EXPLAIN SELECT 사원번호 FROM 직급 WHERE 직급명 = 'Manager';

/*ref*/
/*desc: 테이블 조인을 수행할 때 어떤 조건으로 테이블에 액세스되었는지를 알려주는 정보*/
EXPLAIN SELECT 사원.`사원번호`, 직급.`직급명` FROM 사원, 직급
WHERE 사원.`사원번호` = 직급.`사원번호` AND 사원.`사원번호` BETWEEN 10001 AND 10100;

/*rows*/
/*desc: sql문을 수행하고자 접근하는 데이터의 모든 행 수를 나타내는 예측 항목*/
/*info: 디스크에서 데이터 파일을 읽고 메모리에서 처리해야 할 행수를 예측하는 값, 수시로 변경되는 mysql 통계정보를 참고하여 산출하는 값이므로 수치가 정확하지 않음
sql문 최종결과 건수와 비교해 rows 수가 크게 차이날 때는 불필요하게 mysql 엔진까지 데이터를 많이가져왔다는 뜻이므로 sql 튜닝 대상*/

/*filtered*/
/*desc: DB엔진으로 가져온 데이터를 대상으로 필터조건에 따라 어느정도의 비율로 데이터를 제거했는지 의미하는 항목*/
/*info: DB엔진으로 100건의 데이터를 가져왔고 where 절의 사원번호 between 1 and 10 조건으로 100건의 데이터가 10건으로 필텅링이된다.
이처럼 100건에서 10건으로 필터링 되었으므로 filtered에는 10이라는 정보가 출력된다. 이 때 단위는 %이다.*/

/*extra*/
/*desc: sql문을 어떻게 수행할 것인지에 관한 추가 정보를 보여주는 항목*/
/*info: 세미콜론으로 구분하여 여러가지 정보를 나열할 수 있으며 30여가지 항목으로 정리가 가능, Mysql에서는 extra에서 수행되는 정보가 도무 출력되지는 않음*/

/*--Distinct--*/
/*desc: 중복이 제거되어 유일한 값을 찾을 때 출력되는 정보*/
/*info: distinct 키워드나 union 구문이 포함된 경우*/

/*--Using where--*/
/*desc: where 절의 필터조건을 사용해서 mysql엔진으로 가져온 데이터를 추출한것*/

/*--Using temporary--*/
/*desc: 데이터의 중간 결과를 저장하고자 임시 테이블을 생성*/
/*info:데이터를 가져와 저장한 뒤에 정렬작업을 수행하거나 중복을 제거하는 작업등을 수행, 보통 DISTINCT, GROUP BY, ORDER BY 구문이 포함된경우 해당 정보가 출력
임시 테이블을 메모리에 생성하거나 메모리 영역을 초과하여 디스크에 임시 테이블을 생하면 성능 저하의 원인이될수있어 튜닝 대상*/

/*--Using index--*/
/*desc: 물리적인 데이터 파일을 읽지 않고 인덱스만 읽어서 sql 문의 요청사항을 처리할 수 있는 경우 일명 커버링 인덱스 방식*/
/*info: 인덱스로 구성된 열만 sql 문에서 사용할 경우 이 방식을 활용 테이블보다 인덱스가 작고 정렬되어있으므로 적은 양의 데이터에 저근할 때 성능명에서 효율적
::직급 테이블의 기본 키는 사원번호, 직급명, 시작일 순서로 구성 WHERE 절에는 사원번호를 SELECT 절에는 직급명 조회하므로 기본키만 활용해서 원하는 정보 모두 가져올 수 있는 커버링 인덱스 방식으로 데이터 접근*/

EXPLAIN SELECT 직급명 FROM 직급 WHERE 사원번호 = 100000;

/*--Using filesort--*/
/*desc: 정렬이 필요한 데이터를 메모리에 올리고 정렬 작업을 수행한다는 의미*/
/*info: 이미 정렬된 인덱스를 사용하면 정렬작업이 필요없지만 인덱스를 사용못할 때는 정렬을 위해 메모리 영역에 데이터를 올리게 됨, 해당 방식은 추가적인 정렬작업이므로 인덱스를 활용하도록 sql 튜닝 대상*/

/*--Using join buffer--*/
/*desc: 조인을 수행하기 위해 중간 데이터 결과를 저장하는 조인 버퍼 사용한다는 의미*/
/*info: 드라이빙 테이블의 데이터에 먼저 접근한 결과를 조인 버퍼에 담고 조인 버퍼와 드리븐 테이블 간에 서로 일치하는 조인 키값을 찾는 과정을 수행,
조인 버퍼를 활용하는 일련의 과정이 존재하면 Using join buffer 정보가 출력*/

/*--Using union/Using interset/ Using sort_union*/
/*desc: 인덱스가 병합되어 실해되는 sql문의 extra 항목에는 인덱스를 어떻게 병합했는지에 관한 상제 정보가 출력 그 정보가 Using union/Using interset/ Using sort_union이다*/
/*info: 
 ::Using union은 인덱스들을 합집합처럼 모두 결합하여 데이터에 접근한다는 뜻 ::SQL 문이 OR 구문으로 작성된 경우 해당
 ::Using intersect는 인덱스들을 교집합처럼 추출하는 방식 ::SQL 문이 AND 구문으로 작성된 경우 확인 가능
 ::Using sort_union는 Using union과 유사 ::WHERE절의 OR 구문이 동등조건이 아닐 떄 확인 가능
*/

/*--Using index condition*/
/*desc: 필터 조건을 스토리지 엔진으로 전달하여 필터링 작업에 대한 mysql 엔진 부하를 줄이는 방식*/
/*info: 스토리지 엔진의 데이터 결과를 mysql 엔진으로 전송하는 데이터양을 줄여 성능 효율 높일 수 있는 옵티마이저 최적화 방식*/

/*--Using index condition(BKA)--*/
/*desc: Using index condition 유형과 비슷, 데이터를 검색하기 위해 배치 키 액세스를 사용하는 방식*/

/*--Using index for group-by*/
/*desc: SQL문에 group by 구문이나 distinc 구문이 포함될 때 인덱스로 정렬 작업을 수행하여 최적화, 인덱스로 정렬작업을 수행하는 인덱스 루스 스캔일 때 출력되는 부가 정보*/

/*--Not exits--*/
/*desc:하나의 일치하는 행을 추가로 행을 더 검색하지 않아도될 때 출력되는 유형*/
/*info: 왼쪽 외부 조인 또는 오른쪽 외부 조인에서 테이블에 존재하지 않는 데이터를 명시적으로 검색할 때 발생*/

/*--profiling--*/
SHOW VARIABLES LIKE 'profiling%';
SET profiling = 'ON';
SELECT 사원번호 FROM 사원 WHERE 사원번호 = 100000;
SHOW PROFILES;
SHOW PROFILE ALL FOR QUERY 5;

