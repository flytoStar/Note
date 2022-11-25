## Flink项目

### 什么是flink？

flink是一个面向数据流处理和批处理的分布式计算引擎，它基于流式执行模型，支持流式处理和批处理两种场景。flink还提供了容错机制，状态，时间语义等核心功能，还有抽象层的API，如对静态数据批处理的DataSet API ，对数据流流处理的DataStream API，对结构化数据查询操作的Table API，还提供了特定领域的领域库，如机器学习库，图计算库等。

flink和SparkString的区别

- flink是标准的实时处理引擎，基于事件驱动，SparkString是准实时微批次的处理引擎
- flink支持三种时间机制，事件时间，处理时间，注入时间，同时还支持watermark机制处理迟到数据；而SparkString只支持处理时间
- 架构模型不同，SparkString在运行时的架构有master，worker，Driver，executor；flink在运行时的架构有jobmanager，taskmanager，slot
- 容错机制不同，SparkString的任务设置完检查点，如果发生故障重启，从检查点恢复数据，虽然可以保障数据不丢，但是不能做到恰好处理一次；而flink也有检查点，可以使用内置的两阶段提交来解决这个问题，

**两阶段提交**：

1. 对于每个检查点，sink任务都会启动一个事务，并将所有接收到的数据都添加到事务里
2. 然后将要输出的数据写入外部sink系统的事务中，但不正式提交，
3. 当sink算子接收到检查点完成的通知时，才正式提交外部设备的事务



### flink架构有哪些，各自的作用

flink程序在运行时主要有Jobmanager，Taskmanager，slot三个角色

1. Jobmanager：在集群中作为master，它负责接收job，协调检查点，故障恢复，管理从节点Taskmanager。
2. Taskmanager： 在集群中作为worker，它负责



#### **maven依赖优先级**

- jar包路径最短
- 导入依赖的上下顺序

#### **监控业务数据为什么不用flinkCDC**

- CDC只支持全库表的增量同步，不支持业务数据的全量表的全量同步

- 替换后会导致架构结构不对称，把数据直接发送到flink，ods层各来源数据会混淆

  Maxwell和flinkCDC都支持断点续传

#### DIM层为什么不用Redis而使用HBASE？旁路缓存为什么又用了Redis？

- 有些表数据量比较大，保存在Redis中内存压力比较大

​	旁路缓存不会把所有数据都缓存起来，也不会一直缓存，会设置生命周期，避免冷数据常驻内存（flink状态不便维护）

#### 实时数仓实现表join

1. 滚动窗口 可能满足关联条件的数据不在同一窗口

   2.滑动窗口 会有重复关联的数据

​		以上问题都可维护状态解决

- intervalJoin 底层是用connect将两条流进行连接，然后各为两条流维护了状态
  - 判断数据是否迟到
  - 将数据存入对应的状态中
  - 将时间范围内的数据进行join
  - 清理状态

#### FlinkSQL join

| 连接类型 | 左表状态更新类型 | 右表状态更新类型 |
| :------: | :--------------: | :--------------: |
|  内连接  | OnCreateAndWrite | OnCreateAndWrite |
| 左外连接 |  OnReadAndWrite  | OnCreateAndWrite |
| 右外连接 | OnCreateAndWrite |  OnReadAndWrite  |
| 全外连接 |  OnReadAndWrite  |  OnReadAndWrite  |

#### lookupJoin

- 左表

  - 先根据数据创建动态表

  - 再将从kafka消费数据插入到动态表
- 右表
  - 先根据数据创建动态表
  - 再将从kafka消费数据插入到动态表
- 最后使用flinkSQL 将两表数据join在一起

**一般用作有一方数据数据更新缓慢的环境**

proctime（）函数作为数据连接的版本表的版本标记



#### source端到端一致性

- kafka ---> 可重发

#### sink 端到端一致性

- flinkproducer	 底层是两阶段提交，job执行完成是预提交，检查点完成后才是真正的提交


- clickhouse  建表时采用replacing/replacated引擎，由于自动合并去重的时间不确定，需要手动合并，执行optinze ,或者在查询时查询语句后加上final


- HBASE 	幂等写入

