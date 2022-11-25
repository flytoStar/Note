create table child (
    name string,
    friends array<string>,
    children map<string,int>,
    address struct<street:string,city:string>
)
row format delimited fields terminated by ','
collection items terminated by '_'
map keys terminated by ':'
lines terminated by '\n';

select friends[0] friend,children['xiao song'] children,address.city from child;


create external table test (
    name string,
    friends array<string>,
    children map<string,int>,
    street struct<street:string,city:string>
    )
row format delimited fields terminated by ','
collection items terminated by '_'
map keys terminated by ':'
lines terminated by '\n';

create database test2
location '/user/hive/warehouse'
with dbproperties('author'='atguigu');

create database test5
location '/day02/test'
with dbproperties('author'='atguigu');

/*create external table test1 (
    id int,
    name string
)
row format delimited fields terminated by '\t'
lines terminated by '\n';


alter table test1 set tblproperties('external'='false');

insert into table test4 values(10017,'ss17'),(1018,'ss18');

alter table test1 add columns(sex string,age int);

alter table test1 change column sex add string;

alter table test1 replace columns(id1 int, name1 string ,address string, age1 int);


create table test2 (
    id int,
    name string
)
row format delimited fields terminated by '\t'
lines terminated by '\n';

load data local inpath '/home/atguigu/test1'
overwrite into table test2;


create table test4 (
    id int,
    name string
)
row format delimited fields terminated by '\t'
lines terminated by '\n'
location '/QQ';