#!/bin/bash

case $1 in
"start") {
		echo "================== 启动 集群 =================="
		#启动zookeeper集群
		myzk start
		
		#启动hadoop集群
		myhadoop start
		
		#启动kafka集群
		mykf start
		
		#启动flume采集集群
		f1.sh start
		
		#启动flume消费集群
		f2.sh start
};;

"stop") {
		echo "================== 停止 集群 ==================”
		#停止flume消费集群
		f2.sh stop
		
		#停flume采集止集群
		f1.sh stop
		
		#停止kafka集群
		mykf stop
		
		#停止hadoop集群
		myhadoop stop
		
		#停止zookeeper集群
		myzk stop
};;
esac