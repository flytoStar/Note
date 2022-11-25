### redis五大数据类型

|        |  String   |      List      |    Set    |    Zset     |       Hash       |
| :----: | :-------: | :------------: | :-------: | :---------: | :--------------: |
|   增   | set(mset) |  (L \| R)push  |   sadd    |    zadd     |       hset       |
|   删   |           |  (L \| R)pop   |   srem    |    zrem     |                  |
|   改   |    add    |  (L \| R)push  |   sadd    |   zincrby   |      hsetnx      |
|   查   | get(mget) | lrange  lindex | smemebers | z(rev)range | hget hkeys kvals |
| length |  strlen   |      llen      |   scard   |   zcount    |                  |



redis内存中数据淘汰策略

noeviction   不会淘汰数据，新添加数据时不再内存中添加，会返回一个错误

volatile  所有设置过过期时间的数据

allkeys 所有数据

volatile-ttl  淘汰距离过期时间最近的数据



volatile-random 随机淘汰数据

allkeys 随机淘汰数据



volatile-lru  淘汰非最近使用的数据

allkeys-lru  淘汰非最近使用的数据



volatile-lfu  淘汰某段时间内使用频率最低的数据

allkeys-lfu   淘汰某段时间内使用频率最低的数据

### Redis持久化

RDB  快照备份  数据

占用存储空间小，恢复数据速度快

可能会丢数据

AOF   日志备份  数据+写操作

占用存储空间大，恢复数据速度慢

丢数据概率较低