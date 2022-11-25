#定义组件
a1.sources=r1
a1.channels=c1
a1.sinks=k1

#配置source
a1.sources.r1.type = org.apache.flume.source.kafka.KafkaSource
a1.sources.r1.batchSize = 5000
a1.sources.r1.batchDurationMillis = 2000
a1.sources.r1.kafka.bootstrap.servers = hadoop102:9092,hadoop103:9092,hadoop104:9092
a1.sources.r1.kafka.topics = topic_log
a1.sources.r1.interceptors=i1
a1.sources.r1.interceptors.i1.type=com.atguigu.gmall.flume.log.interceptor.TimestampIntterceptor$Builder

#配置channel
a1.channels.c1.type=file
a1.channels.c1.checkpointDir=/opt/module/flume/checkpoint/behavior1
a1.channels.c1.dataDirs=/opt/module/flume/data/behavior1
a1.channels.c1.maxFileSize=2146435071
a1.channels.c1.capacity=1000000
a1.channels.c1.keep-alive=6

#配置sink
a1.sinks.k1.type = hdfs
a1.sinks.k1.hdfs.path =/origin_data/gmall/log/topic_log/%Y-%m-%d
a1.sinks.k1.hdfs.filePrefix = log
a1.sinks.k1.hdfs.round = false
a1.sinks.k1.hdfs.rollInterval = 10
a1.sinks.k1.hdfs.rollSize = 134217728
a1.sinks.k1.hdfs.rollCount=0

#设置输出文件类型
a1.sinks.k1.hdfs.fileType=CompressedStream
a1.sinks.k1.hdfs.codeC=gzip

#组装
a1.sources.r1.channels=c1
a1.sinks.k1.channel=c1
