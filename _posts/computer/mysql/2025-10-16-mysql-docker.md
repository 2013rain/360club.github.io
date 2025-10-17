---
title: mysql - docker安装mysql
author: "wangfuyu"
description: >-
  仅用于开发、测试环境，方便自己创建数据库和对数据管理。
date: 2025-09-02 12:00:00 +0800
categories: ["docker", "mysql"]
tags: ["mysql", "docker"]
math: true 
img_path: /static/image/







---

## 创作背景

不管是自己沉寂多年的台式机、笔记本，或者是花了个优惠券购买了云主机，都想着自己搭建个完整的项目，此时有恰好我们在用mysql（用到其他的话，可以看其他篇幅文章）。

让项目run起来。

## 实施

安装docker，参考我之前的文章。

创建目录

```bash
mkdir -p /data/mysql/data
mkdir -p /data/mysql/conf
mkdir -p /data/mysql/logs
```

编写配置文件 `cat /data/mysql/conf/my.cnf` 

```ini
[client]
# 客户端默认字符集
default-character-set = utf8mb4
# 客户端端口
port = 3306
# 客户端socket文件位置
socket = /var/run/mysqld/mysqld.sock

[mysql]
# MySQL客户端默认字符集
default-character-set = utf8mb4
# 启用自动补全
auto-rehash = 1
# 提示符设置，显示当前数据库
prompt = '\\u@\\h [\\d]> '

[mysqld]
# ===== 基础配置 =====
# 服务端端口
port = 3306
# 服务端socket文件位置
socket = /var/run/mysqld/mysqld.sock
# 数据目录
datadir = /var/lib/mysql
# 进程文件位置
pid-file = /var/run/mysqld/mysqld.pid

# ===== 字符集配置 =====
# 服务端默认字符集
character-set-server = utf8mb4
# 服务端默认排序规则
collation-server = utf8mb4_unicode_ci
# 连接字符集
init_connect = 'SET NAMES utf8mb4'
# 字符集相关文件和目录
character-set-filesystem = utf8mb4

# ===== 网络与连接 =====
# 绑定地址，0.0.0.0表示允许所有IP连接
bind-address = 0.0.0.0
# 最大连接数
max_connections = 200
# 最大错误连接数
max_connect_errors = 100
# 连接超时时间（秒）
connect_timeout = 60
# 等待超时时间（秒）
wait_timeout = 28800
# 交互式连接超时时间（秒）
interactive_timeout = 28800

# ===== 内存配置 =====
# 查询缓存大小（建议关闭，MySQL 8.0已移除）
query_cache_type = 0
query_cache_size = 0

# InnoDB缓冲池大小（重要：通常设置为可用内存的50-80%）
innodb_buffer_pool_size = 128M

# 临时表大小
tmp_table_size = 32M
max_heap_table_size = 32M

# ===== InnoDB配置 =====
# InnoDB存储引擎设置
default-storage-engine = InnoDB
innodb_data_file_path = ibdata1:12M:autoextend
innodb_log_file_size = 48M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50
innodb_file_per_table = 1
```



开始运行起来吧

```bash
docker pull mysql:5.7

docker run -p 3306:3306 --name mysql -v  /data/mysql/conf/my.cnf:/etc/mysql/my.cnf -v  /data/mysql/logs:/logs -v  /data/mysql/data:/mysql_data -e MYSQL_ROOT_PASSWORD=11223344 -d mysql:5.7

```

## 问题处理

- 如何在阿里云放开该端口？

  点击服务器实例，看到网络组或者防火墙，进入进行端口针对白名单ip放开即可。

## 总结











