## spark-sql

#### RDD-dataframe-dataset之间的转换

RDD关注数据本身

dataframe关注数据结构，面向sql

dataset关注类型,面向对象

RDD-->dataframe         rdd**.**toDF(顺序的字段名称)          需要隐式转换

dataframe-->RDD         dataframe**.**rdd

dataframe-->dataset     df.as[类型]      							 需要隐式转换

dataset-->dataframe      ds.toDF()

RDD-->dataset             添加结构添加类型后的RDD.toDS()

dataset-->RDD              ds**.**rdd

**dataframe的本质是dataset的一种特定泛型dataset[Row]**

编译器进行类型匹配时，如果找不到合适的类型，那么隐式转换会让编译器在作用范围内自动推导出来合适的类型