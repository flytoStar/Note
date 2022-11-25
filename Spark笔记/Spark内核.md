### Spark运行机制

#### cluster模式

spark 提交应用程序流程

​		在启动sprak-submit脚本后，脚本会启动一个进程，进程中会创建一个客户端对象，即yarnclient，用来与yarn集群交互，并且可以将应用程序和指令提交给yarn集群，yarn集群的resourcemanager接收到指令后会将计算任务分配给nodemanager执行，nodemanager接到任务后会启动一个applicationMaster 线程，线程中会创建rmclient对象与rm交互，同时启动一个Driver进程，让用户程序在Driver中执行，Driver线程主要用于计算，main线程主要用于资源，两个线程交叉执行，先执行main线程，启动Driver线程，此时main线程阻塞，等待sparkContext的创建；然后Driver线程执行，过程中会创建SparkContext对象，然后通知main线程执行；main线程主要用于资源申请和启动资源，完成后阻塞让Driver执行，Driver线程执行计算，划分阶段，切分任务，调度任务，执行任务



提交一个Spark应用程序，首先通过Client向ResourceManager请求启动一个Application，同时检查是否有足够的资源满足Application的需求，如果资源条件满足，则准备ApplicationMaster的启动上下文，交给ResourceManager，并循环监控Application状态。
    当提交的资源队列中有资源时，ResourceManager会在某个NodeManager上启动ApplicationMaster进程，ApplicationMaster会单独启动Driver后台线程，当Driver启动后，ApplicationMaster会通过本地的RPC连接Driver，并开始向ResourceManager申请Container资源运行Executor进程（一个Executor对应与一个Container），当ResourceManager返回Container资源，ApplicationMaster则在对应的Container上启动Executor。
    Driver线程主要是初始化SparkContext对象，准备运行所需的上下文，然后一方面保持与ApplicationMaster的RPC连接，通过ApplicationMaster申请资源，另一方面根据用户业务逻辑开始调度任务，将任务下发到已有的空闲Executor上。
    当ResourceManager向ApplicationMaster返回Container资源时，ApplicationMaster就尝试在对应的Container上启动Executor进程，Executor进程起来后，会向Driver反向注册，注册成功后保持与Driver的心跳，同时等待Driver分发任务，当分发的任务执行完毕后，将任务状态上报给Driver。
    Client只负责提交Application并监控Application的状态。对于Spark的任务调度主要是集中在两个方面: 资源申请和任务分发，其主要是通过ApplicationMaster、Driver以及Executor之间来完成。



使用shell向yarn集群提交Spark任务后会在本地启动一个yarnclient，yarnclient会向RM提交任务信息，同时会申请启动一个AM，如果指定的NM资源足够就会在该NM启动AM，AM启动后会初始化SC，然后启动Driver线程，DRiver会通过RPC与AM保持通讯，AM再向RM注册AM，同时向RM申请资源，RM会向AM返回空闲资源列表，AM接收到列表后根据资源空闲列表在相应的NM启动executor线程，executor启动后会向Driver注册，同时通过RPC与Driver保持心跳，然后Driver会划分任务 executor线程会创建executor对象，创建成功后调度器根据分配规则将任务分配给executor，executor线程会向Driver反馈任务执行信息

![QQ图片20220527172052](F:\Atguigu\04_Note\文档\MDpng\QQ图片20220527172052.jpg)





#### client模式





![QQ图片20220527172119](F:\Atguigu\04_Note\文档\MDpng\QQ图片20220527172119.jpg)





### Spark通讯机制



### RDD阶段划分

执行一次行动算子就会提交一次job

一个job中的阶段数量(stage) =1 + shuffle依赖的数量 

job的任务数量(Tasks) = 每一个阶段的最后一个RDD分区数之和

1. 初始化sc后开始执行程序，执行到行动算子，每执行一个行动算子提交一次job，jobnum = 行动算子的数量
2. DAG调度器开始对job进行阶段划分，阶段数 = shuffle次数+ 1 ，根据stage数量确定tasknum
3. tasknum = 每个阶段最后一个算子的分区数之和
   taskscheduler通过taskset获取job的所有task，序列化后发往executor

### Spark任务调度机制

FIFO&FAIR

默认调度器是FIFO

计算的首选位置：按照本地化级别（进程本地化，节点本地化，机架本地化）选择

在划分完阶段和划分完task后，taskscheduler通过taskset获取到一个阶段的所有task，由tasksetmanager调度分配，分配原则按照计算首选位置，也就是本地化级别来分配，进程本地化，节点本地化，机架本地化三个，然后序列化后发往executor

​		在调度执行时，调度器默认会让每个task以最高的本地化级别来启动任务，但是往往由于该级别对应的executor资源不充足二启动失败，此时也不会马上降低本地化级别，而是在一个最大超时时间内一直尝试启动，如果超时，才会去尝试下一个本地级别；因此，我们可以调高每个级别的超时时间，让task在启动失败时等待，在等待时executor可能会有资源去执行该task，在一定程度上可以提高效率

![image-20220818145256766](F:\Atguigu\04_Note\文档\MDpng\image-20220818145256766.png)

### shuffle

ByPassMergeSortShuffleHandle

​	1. shuffle时是否有预聚合

​	2. reduce阶段的分区数量小于等于200

SerializeShuffleHandle

序列化管理器支持重定位

#### hashshuffle

每个task线程只输出一个数据文件，下游多个并行度去同时读取会产生并行访问冲突；每个task线程输出数据文件数量和下游并行度相同，会有小文件过多的问题；

#### sortshuffle





#### RDD 五大属性

- **分区属性** : 每个RDD包括多个分区，分区即是RDD的数据单位， 也是计算粒度，每个分区由一个task线程处理，在RDD创建时可以指定分区数，如果没有指定就使用默认分区数（executor的核数）。
- **分区方法** ： 指的是RDD的分区函数， 目前有Hashpartition 和 Rangepartition两种，它决定了当前的分区数和输出的分区数。
- **依赖关系** ： 依赖指的是RDD之间的转换关系，记录依赖关系有助于阶段和任务的划分，依赖分为宽依赖和窄依赖，窄依赖的partition被至多一个子RDD partition 依赖，宽依赖的partition 被多个子RDD partition依赖。
- **获取分区迭代列表** ： 当RDD的iterator方法无法从缓存和检查点中获取RDD指定的分区迭代器时，使用compute方法来获取。
- **优先分配节点列表** ： 每个RDD会维护一个列表，这个列表保存了分区task分配给哪个executor执行的优先级，Spark秉承移动计算不移动数据的原则，就是尽量在存储数据的节点执行计算。

