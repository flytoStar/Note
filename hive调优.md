## Yarn

每个nodemanager给container分配的内存大小为 节点总内存大小减去其他服务所需的内存

分配给container的核数设为内存的1/4

单个container可使用的最大内存为16，最小512M

## Spark-executor

executor的核数最好设为可被分配container的最大核数整除的数量

executor的内存分为堆内存和堆外内存，在计算出单个executor可分配多少内存后按照1：10给堆内存和堆外内存配置

executor的个数有两种模式，动态分配和静态分配，静态分配需要自行预估每个Spark应用所需的资源

动态分配根据每个Spark应用的工作负载，动态的调整所占的资源，在需要时，可以申请更多的资源，应用执行完后再释放资源

### 启用动态分配

\#启动动态分配

spark.dynamicAllocation.enabled  true

\#启用Spark shuffle服务

spark.shuffle.service.enabled  true

\#Executor个数初始值

spark.dynamicAllocation.initialExecutors  1

\#Executor个数最小值

spark.dynamicAllocation.minExecutors  1

\#Executor个数最大值

spark.dynamicAllocation.maxExecutors  12

\#Executor空闲时长，若某Executor空闲时间超过此值，则会被关闭

spark.dynamicAllocation.executorIdleTimeout  60s

\#积压任务等待时长，若有Task等待时间超过此值，则申请启动新的Executor

spark.dynamicAllocation.schedulerBacklogTimeout  1s

\#使用旧版的shuffle文件Fetch协议

spark.shuffle.useOldFetchProtocol true

在一个stage执行完，executor资源释放后，下游的stage在执行时无法从上游stage获取输出的数据文件，开启shuffleFetch服务后由shuffleFetch管理



## hive优化

### map-side预聚合

--启用map-side聚合

```sql
set hive.map.aggr=true;

--hash map占用map端内存的最大比例

set hive.map.aggr.hash.percentmemory=0.5;
```

在map端维护了hashtable利用它完成相同分区数据的预聚合，然后将预聚合的结果发送到reduce端进行最终的聚合

**优点**：map端预聚合能够减少shuffle的数据量，提高分组聚合的效率

### map join（大表小表join）

默认是common join, 默认是map端读取数据，按照关联字段分区，然后将数据发送到reduce端

#### map join

```sql
--启用map join自动转换
set hive.auto.convert.join=true;
--common join转map join小表阈值
set hive.auto.convert.join.noconditionaltask.size

```

在参与join的表中，要有n-1张表时小表，然后map端缓存小表的全部数据，扫描大表，在map端进行关联

#### bucket map jon

参与join的表均为分桶表，关联字段为分桶字段，大表的分桶数量为小表的分桶数量的整数倍，此时可以以分桶为单位在map端进行关联，无需在map端缓存小表的全部数据了，只需缓存所需的分桶数据。

### Spark数据倾斜优化

### map join

```sql
--启用map join自动转换
set hive.auto.convert.join=true;
--common join转map join小表阈值
set hive.auto.convert.join.noconditionaltask.size
```

在参与join的表中，要有n-1张表时小表，然后map端缓存小表的全部数据，扫描大表，在map端进行关联，没有reduce阶段，避免了数据倾斜

### skew join（inner join使用）

```sql
--启用skew join优化
set hive.optimize.skewjoin=true;
--触发skew join的阈值，若某个key的行数超过该参数值，则触发
set hive.skewjoin.key=100000;

```

在两表join时，如果某一key对应的数据量超过hive.skewjoin.key的数值，就先将这些数据写入hdfs，其他key的数据join完成后，再加载到内存进行一次map join，最后将数据输出

### 并行度优化

```sql
--计算Reduce并行度时，从上游Operator统计信息获得输入数据量
set hive.spark.use.op.stats=true;
--计算Reduce并行度时，使用列级别的统计信息估算输入数据量
set hive.stats.fetch.column.stats=true;

```

开启估算数据量后下一个阶段的数据量都会减少，提高了计算效率





#### hive的优化

1.大表join小表是开启mapjoin
2.建表时创建分区表，防止查询时全表扫描
3.提前行列过滤 ，查询时只拿需要的字段，提前使用where将数据过滤，where在map阶段执行，减少map输出的数据量 （谓词下推）
4.处理小文件问题
	（1）开启jvm重用，减少jvm实例开关时间
	（2）使用combinehiveinputformat及其切片规则
	（3）merge   将小于16M的文件合并到256M
5.在shuffle前使用压缩，减少磁盘io
6.使用列式存储，加快查询效率
7.不影响业务的情况下使用combiner
8.设置合理的reduce个数
9.切换计算引擎 MR--》tez --》Spark 



#### 解决数据倾斜的几种方法

1.大表join小表是开启mapjoin
2.大表join大表  左表加随机前缀，右表扩容，最后聚合
3.使用
4.单个key 加随机数，双重聚合。第一次在数据key前加随机数，把相同key的数据分布到不同分区，进行局部聚合；第二次去掉前缀，进行全局聚合。
	inner join时配置skew join 双重聚合
5.多个key 自定义分区器，自定义散列函数将相同key的数据散列到不同reduce进行聚合
6.增加reduce个数
7.加随机数，双重聚合
配置skew join 双重聚合


编译器 --抽象语法树--逻辑执行计划--逻辑执行计划优化--物理执行计划--物理执行计划优化--执行器





 1）数据倾斜
            （1）group by  
                map side 
                skewindata
            

            （2）join
                大小表 mapjoin  
                大表大表
                smb 
                左表随机 右表扩容
                skew  
