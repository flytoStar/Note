## Hbase

分布式，可扩展，支持海量数据随机读写的NoSQL

### Hbase 数据模型

namespace  类似关系型数据库的database，里面承载表

table  类似关系型数据库的表

rowkey  hbase每行数据都有对应的rowkey

column  Hbase有列族的概念，每个列族都有一个或多个列   建表时只需指明列族即可



### Hbase架构



RegionServer  Region的管理者，操作Region，操作数据

Master	 RegionServer的管理者，操作RegionServer，操作表

Zookeper  实现hbase高可用，监控master和regionServer

HDFS   提供hbase的数据存储服务

### Hbase 基本操作

#### namespace DDL

创建namespace     		create_namespace '名称' , {'备注项'=>'val','备注项'=>'val'   ...}

修改备注项信息 	     	alter_namespace '名称' , {METHOD=>'set' , '备注项'=>'new val'} 

删除namespace	  		drop_namespace '名称' , {METHOD=>'unset',NAME=>'val'}

查看namespace详情	   describe_namespace '名称'

查看all namespaces    	list_namespace

查看all tables             	list_namespace_tables  '名称'



#### table DDL

查看all tables              list

创建表							create 'namespace:表名' , {NAME=>'列族名称' ， VERSIONS=>维护版										本数} , {NAME=>'列族名称' , VERSIONS=>维护版本数} , ...

​										create 'namespace:表名' , '列族名称' , '列族名称' , ...

修改表						   alter '表名' , {NAME=>'列族名称' , VERSIONS=>维护版本数} , 									{NAME=>'列族名称' , VERSIONS=>维护版本数} , ...

删除列族                   alter '表名' , {NAME=>'列族名称'，METHOD=>'delete'}

​									alter '表名' , 'delete'=>'列族名称'

查看是否禁用					     is_disabled  '表名'

查看是否启用						 is_enabled   '表名'

禁用表									disable  '表名'

启用表									enable  '表名'

删除表									drop '表名'

查看表是否存在					  exists  '表名'

查看表的Region					 list_regions  '表名'



#### table DML

插入数据								put '表名' , 'rowkey值' , '列族 : 字段名' , 'val'

查询数据								get  '表名' , 'rowkey值' , '列族 : 字段名' 

扫描数据								scan  '表名'

​											 scan  '表名' , {STARTROW=>'rowkey' , STOPROW=>'rowkey'}

修改数据								put '表名' , 'rowkey值' , '列族 : 字段名' , 'new val'

删除数据								deleteall '表名' , 'rowkey值' , '列族 : 字段名' 

​											 deleteall '表名' , 'rowkey值' , '列族' 

​											 deleteall '表名' , 'rowkey值' 

清空数据								truncate  '表名'



### Hbase 读写原理

#### 	Hbase写入原理

​			客户端首先访问zookeper去获取表的元数据处于哪个RegionServer ，得到结果后再访问RegionServer获取表的元数据，根据写入请求的参数查询出数据在哪个Region中，并将Region和RegionServer信息存入meta cache中，然后把写入操作记录在WAL中，然后把数据写入memstore中，完成之后应答客户端结果，memstore到达刷写时间后将数据刷写到Hfile中



#### Hbase 读取流程

​			客户端首先访问zookeper去获取表的元数据处于哪个RegionServer，得到结果后再访问RegionServer获取表的二元数据，根据读取请求的参数查询数据在哪个Region中，并将Region和RegionServer信息存入meta cache，然后与目标RegionServer 通讯，分别在memstore和Hfile中查询数据，并将查到的数据合并，将查询到的新的数据块缓存到Block cache中，最后将合并后的结果返回给客户端

从Hfile中读取数据时从时间范围，rowkey范围，布隆过滤器过滤数据，

#### memstore 自动刷写

​		1）当Region中的某个memsotr 大小达到flush.size（默认128M）之后，Region的所有memstore都会刷写,当大道东了flush.size * 4后会阻止客户端继续写入

​		1)当RegionServer中的memstore总大小达到给HBASE分配的堆内存大小达到了38%，Region会按照从大到小的顺序刷写memstore，当RegionServer中的memstore总大小达到给HBASE分配的堆内存大小达到了40%后会阻止客户端继续写入

​		3）不满足以上两点，而达到自动刷写时间后自动刷写，默认间隔是一小时

#### 		StoreFile Compaction ：

​		 minjor Compaction 将一个store下的临近的若干个hfile合并成一个大文件

​		 major Compaction将一个store 下的所有Hfile合并成一个大文件，并清理掉所有过期和删除的数据

#### Region split

​		当RegionServer只有一个Region时，storefile大小超过flush.filesize(默认256M)时分裂，否则storefile大小超过max.filesize(默认10G)时分裂



### Phoenix二级索引

全局索引

​		将索引列与原表的rowkey拼接起来作为索引表的rowkey

​		create index ind_user_name on USER(name);

包含索引

​		create index ind_user_name_age on USER(name) include age;

本地索引

​		create local index ind_user_name on USER(name);

**总结：多读少写场景使用全局索引，少读多写场景使用本地索引**



#### row key设计原则

Rowkey的唯一原则  必须在设计上保证其唯一性

Rowkey的长度原则  Rowkey是一个二进制码流 ,建议越短越好，不要超过16个字节,太长会降低检索效率。

Rowkey的散列原则  Rowkey应均匀的分布在各个RegionServer上

反转时间戳  牺牲了有序性

加盐值 牺牲了效率，读写开销更大
