## kafka

​			kafka : 分布式的基于发布订阅模式的消息队列

### kafka应用场景（作用）

​		1）消峰

​		2）解耦

​		3）异步通信

发布订阅模式可以有多个topic，消费者消费数据后不会删除数据，每个消费者相互独立可以消费不同的数据

#### kafkaProducer发送数据流程

​	启动producer后首先会创建一个main线程，然后创建一个producer实例，通过调用send方法将数据向后传输，在此过程中可以实现拦截器（可选），序列化器，分区器，数据会被发送到内存中的缓存中，缓存默认32M，缓存中会维护队列，数据会发送到缓存进入到队列，缓存数据的单位是batch，默认大小16K，**在满足数据量到达batch.size时** 或 **linger.ms 到达设定时间时** sender线程会从缓存队列中拉取数据，将数据封装成request请求保存在inflight队列中，通过selector通道将数据发送到kafka集群的broker，kafka集群收到数据后有三种应答机制（acks）

- 0  生产者发送过来的数据，不需要等待数据落盘就应答
- 1  生产者发送过来的数据，broker Leader收到数据后应答
- -1  生产者发送过来的数据，broker Leader和ISR队列中的所有节点都收到数据后应答



#### kafka broke工作流程

启动的broker会依次在zk注册，最先注册的broker controller说了算，它会监听borkers的变化，由controller决定Leader的选举，以在ISR中存活为前提，AR中顺序靠前的成为Leader，然后controler将节点信息上传到zk，其他controler再从zk同步节点信息，生产者发送数据过来，Leader接收到后，follower会从Leader复制一份到本地，数据是以log的形式存储的，为了查询数据方便，log文件生成的同时还伴生有index文件；如果当前的Leader挂了，controller监听到节点变化，会从zk获取ISR信息，按照选举规则重新选举新的Leader，然后controller再将节点信息上传到zk，其他controler再从zk同步节点信息

**ISR**，表示和Leader保持同步的Follower集合

**AR**Kafka分区中的所有副本统称为AR

#### kafka消费者组初始化流程

每个broker都有一个coordinator，通过用groupID%50得出的分区数在哪个broker上，该broker的coordinator就成为coordinator的老大，每个consumer都会向coordinator发送一个joingroup的请求，消费者组随机随机选出一个消费者作为Leader，coordinator将要消费的topic信息发送给consumerLeader，consumerLeader会定制一个消费方案发送给coordinator，coordinator再将消费方案发送给每个consumer；每个consumer都会和coordinator保持心跳，默认3s，一旦超时（45s），该消费者会被coordinator移除，然后触发再平衡，如果consumer处理消息的时间过长也会触发再平衡



#### kafka消费者组消费流程

消费者组会创建一个consumerNetWorkClient对象用来和集群交互，，然后调用sendFetches方法，将消费的配置参数传给consumerNetWorkClient，然后会调用一个send方法向集群发送消费请求，通过onsuccess方法将数据抓取过来放在消费者组的消息队列中，然后一个消费者会从消息队列中拉取一批消息，默认500条，之后对数据进行，反序列化，拦截器的处理

最小抓取大小	1kb

最小抓取大小未到达的超时时间	500ms

最大抓取大小	50M

拉取返回消息的最大条数	500条



#### kafka分区策略

生产者端

- 有指定的分区值，直接将数据发送到该分区
- 没有分区值但有key，将key与topic的分区数取余得到分区值，将该key对应的数据写入对应分区内
- 没有分区值也没有key，采用粘性分区器，即随机选择一个分区，当batch被拉取走了再随机选择一个分区，不会和上次相同
  

​			

消费者端

Range，先将消费者和分区进行排序，然后  topic分区数/消费者数	，余下的分区由前面的几个消费者各消费1个

(针对一个topic进行分区)

- 容易产生数据倾斜

RoundRobin，通过轮询算法，将分区依次分配给每个消费者

（针对多个topic进行分区）

- 随机的均衡分配

topic数量多选roundRobin

topic数量少选range

和粘性组合使用，在触发再平衡时粘性起作用



#### kafka数据重复问题

- 首先开启幂等性，producer端事务协调器将pid和事务id绑定，即使重启也能通过事务ID获取原来的pid，用幂等性保证数据不会重复，事务协调器还会把事务写入kafka transaction log主题，服务重启事务也可以恢复
- 消费者端使用自定义事务，把数据消费过程和提交offset原子绑定，当数据被拉取成功后手动提交offset到支持事务的自定义介质中

 

#### kafka乱序问题

把表的主键作为kafka主题分区的key，这样相同key的数据就会出现在相同分区内
