---
title: work - 在线专属服务器
date: 2026-09-01 12:00:00 +0800
categories: [ "mime","work"  ]
tags: [ "mime","work" ]
author: wangfuyu
math: true 



---

## work - 在线专属服务器

### 基础安装功能

#### 1. 安装网络代理服务端（squid）

```shell
 yum install squid
 cat /etc/squid/squid.conf
```

> 配置好一个代理服务器，还可以当作DNS解析用。

#### 2. 安装DNS服务器（dnsmasq）

```shell
yum install dnsmasq -y
cat /etc/dnsmasq.conf
```

> 解析一些不允许互联网公开的地址，特别好用，只需要把路由的DNS修改成当前的服务器ip即可。

#### 3. 安装大模型代理服务（GoModel）

参考源码地址：`https://github.com/ENTERPILOT/GoModel`

我使用的当时最新版：v0.1.84

```shell
wget https://github.com/ENTERPILOT/GoModel/releases/download/v0.1.84/gomodel_0.1.84_linux_amd64.tar.gz
```

稍微修改`config.yaml` 即可。

> 到几大大模型厂商，注册账号，然后添加虚拟模型，增加负载均衡，用来学习开发绝对够了。
>
> 我比较喜欢每天做活动的那些厂家，而且不需要他们打广告，使用的人都互相给传开了（毕竟有点羊毛可以薅，就跟不充值就能玩游戏一样），我推荐`modelscope` ,`volcengine`,`sensenova` 这三个每天都赠送，以后还有没有赠送就看这几家公司发展情况了。

#### 4. 安装工作流（dagu）

参考源码地址：`https://github.com/dagucloud/dagu`

我使用的当时最新版：v2.13.0

```shell
# 当前有新版本v2.16.1
wget https://github.com/dagucloud/dagu/releases/download/v2.16.1/dagu_2.16.1_linux_amd64.tar.gz
git clone https://gitee.com/chatraha/dagu.git
```



#### 5. 安装提醒通知服务（guards）



#### 6. 安装网络穿透（frp）

参考源码地址：`https://github.com/fatedier/frp`

我使用的当时最新版：v0.68.1

```shell
# 当前有新版本
wget https://github.com/fatedier/frp/releases/download/v0.71.0/frp_0.71.0_linux_amd64.tar.gz
cat /usr/local/frp/frps.toml
/usr/local/frp/frps -c /usr/local/frp/frps.toml
```



#### 7. 安装web服务器（openresty）



#### 8. 安装ssh （授权）



### 备份与恢复

需要一个脚本来一键完成新机器部署或旧机器配置回滚。

还可以一键完成旧机器配置备份。

脚本项目：

## 
