---
title: redis - docker安装redis
author: "wangfuyu"
description: >-
  仅用于开发、测试环境，方便自己创建数据库和对缓存管理。
date: 2025-09-02 12:00:00 +0800
categories: ["docker", "redis"]
tags: ["redis", "docker"]
math: true 
img_path: /static/image/








---

## 创作背景

不管是自己沉寂多年的台式机、笔记本，或者是花了个优惠券购买了云主机，都想着自己搭建个完整的项目，此时有恰好我们在用redis（用到其他的话，可以看其他篇幅文章）。

让项目run起来。

## 实施

安装docker，参考我之前的文章。

创建目录

```bash
mkdir -p /data/redis/data
mkdir -p /data/redis/conf
mkdir -p /data/redis/logs
```

编写配置文件 `cat /data/redis/conf/redis.conf` 

```ini
# Redis 配置文件示例

# 网络相关配置
bind 0.0.0.0
port 6379
timeout 0
tcp-keepalive 300

# 常规配置
daemonize no
pidfile /var/run/redis/redis-server.pid
#loglevel notice
#logfile /var/log/redis/redis-server.log
databases 16

# 安全配置 - 密码认证（重要！）
requirepass "wfY@2024USA"
# 重命名危险命令以增强安全性
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "REDIS-CONFIG"
rename-command SHUTDOWN "REDIS-SHUTDOWN"

# 内存管理
maxmemory 1gb
maxmemory-policy allkeys-lru

# 持久化配置 - RDB
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data

# 持久化配置 - AOF
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes

# 主从复制配置
# 如果这是从节点，取消注释并设置主节点的IP和端口
# slaveof 192.168.1.100 6379
# 如果主节点有密码，设置主节点密码
# masterauth "MasterP@ssw0rd"

# 慢查询日志
slowlog-log-slower-than 10000
slowlog-max-len 128

# 客户端配置
maxclients 10000

# 性能优化
hz 10
aof-rewrite-incremental-fsync yes

# 集群模式
# 如果启用集群模式，取消注释以下行
# cluster-enabled yes
# cluster-config-file nodes.conf
# cluster-node-timeout 15000

# TLS/SSL 配置（可选，增强安全性）
# tls-port 6379
# tls-cert-file /path/to/redis.crt
# tls-key-file /path/to/redis.key
# tls-ca-cert-file /path/to/ca.crt
# tls-auth-clients optional

# 监控配置
# 启用监控，可以设置监控密码
# monitor-threshold 100
```



开始运行起来吧（我们不持久化，这样可以重启容器来达到全部清理缓存）

```bash
docker pull  redis:7.2.5

#docker run -p 6379:6379  --name redis  -v /data/redis/data:/data  -d redis:7.2.5 redis-server --appendonly no
docker run -d \
  --name my-redis \
  -p 6379:6379 \
  -v /data/redis/conf/redis.conf:/etc/redis/redis.conf \
  -v /data/redis/data:/data \
  --restart unless-stopped \
  redis:7.2.5 redis-server /etc/redis/redis.conf

```

## 问题处理

- 如何在阿里云放开该端口？

  点击服务器实例，看到网络组或者防火墙，进入进行端口针对白名单ip放开即可。

## 总结











