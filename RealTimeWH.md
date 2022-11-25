### kafka精确一次消费

​			后置提交offset + 幂等写

### kafka服务挂掉batch缓冲区的消息丢失消息发送失败

​			手动提交offset之前把batch中的数据刷写到broker



维度表历史数据（Redis中没有）

在maxwell 中使用maxwell-boostrap做全量同步



数据处理顺序性

如果同一条数据多次修改，经过实时处理后，存储数据时不能保证数据时按照修改顺序记录的，此问题只可能在kafka环节出现问题

解决：把同一条数据的处理发往topic的同一分区处理，修改maxwell的配置文件，指定数据发往kafka时使用分区键



数据状态不一致

描述： 用户首次访问数据写入Redis后，ES程序故障没有写入，导致两份数据不一致

解决： 在启动程序时先把Redis的数据清空，然后从ES中读取数据同步到Redis 



双流join时数据延迟问题

描述： 有一方数据延迟导致join失败

解决： 当任意方数据延迟时，先把当前数据放入缓存，数据流到来时去缓存中读取数据再join

### 日志/业务数据消费分流任务流程

​	1.准备实时环境

​	2.从Redis读取offset

​	3.从kafka中消费数据

​	4.提取当前offset

​	5.处理数据

​			5.1 转换结构

​			5.2 分流

​	6.刷写kafka缓冲区数据

​	7.提交offset



<img src="F:\Atguigu\04_Note\文档\MDpng\ods_to_dwd总结.png" alt="ods_to_dwd总结" style="zoom:60%;" />

![DWD到DWS层总结](F:\Atguigu\04_Note\文档\MDpng\DWD到DWS层总结.png)