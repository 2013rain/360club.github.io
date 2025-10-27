---
title: golang - 介绍一个网盘cloudreve
date: 2025-10-27 12:00:00 +0800
categories: ["计算机" ]
tags: ["computer" , "网盘" ]
author: wangfuyu
math: true 
img_path: /static/image/





---

## 写作背景

  我家里有几台电脑，由于配置比较低，当废品卖掉比较可惜，就直接安装了个centos7用来当做一个家庭个人服务器。

我重新购买了一个1T的机械磁盘用来存放手机的照片，如果哪天更换手机，我可以直接对原来的手机进行出厂模式恢复即可（扩容手机厂商自带的网盘也是可行的，不过就当交电费了，我周末开一次电脑足够了）。

## 动手准备

1. 系统安装后，固定一下机器的ip

   ```
   打开目录：/etc/sysconfig/network-scripts/
   选择已使用的网卡。例如vim ifcfg-eth0
   更改内容包括
   BOOTPROTO=static ##以指定静态IP地址 IPADDR=192.168.10.10 # 静态IP地址 NETMASK=255.255.255.0 # 子网掩码 GATEWAY=192.168.10.1 # 网关IP地址 DNS1=8.8.8.8 # 主DNS服务器 DNS2=8.8.4.4 # 备用DNS服务器
   重启网卡：sudo systemctl restart network
   验证：ip addr show eth0
   ```

   

2. 放弃机器的显示器依赖，开启ssh，以后用远程登录操作

   ```
   开启sshd: service sshd start
   端口22放开：firewall-cmd --zone=public --add-port=22/tcp --permanent
   重启防火墙：service firewalld network
   家庭没有必要开启防火墙了：systemctl stop firewalld.service
   永久关闭防火墙：systemctl disable firewalld (自己家用，完全完毕就行)
   开机启动:systemctl enable ssh
   ```

   

3. 时间同步也是有必要的，比如如果断电太久（纽扣电池也没有电了，可能会重置BIOS，导致时钟错乱）

   ```
   yum install -y ntp  ##安装ntp服务
   systemctl start ntpd    #启动时间同步
   systemctl enable ntpd   # 允许开机启动
   date   # 查看服务器时间是否与已同步正确
   ```

   

4. 安装个LNMP环境，这样自带了MySQL和Nginx，同时也可以玩玩PHP

   ```
   wget https://soft.lnmp.com/lnmp/lnmp2.0.tar.gz -O lnmp2.0.tar.gz && tar zxf lnmp2.0.tar.gz && cd lnmp2.0 && ./install.sh lnmp
   #默认密码可以自己统一设置123456或者1234567890wasd，（看个人习惯，纯内网用）
   ```

   

5. 安装个Redis，大部分的服务都会依赖Redis

   ```
   wget https://download.redis.io/releases/redis-7.0.15.tar.gz
    # 提示依赖 python3 和 tcl 
    yum install -y python3 tcl
    cd redis-7.0.15/src
    make test && make install
    cp utils/redis_init_script /etc/init.d/
    # 根据里面写的每个端口对应一个配置文件 /etc/redis/{port}.conf ,创建文件增加端口号
    ```conf
    port 6379
    
   chkconfig redis_init_script on # 文件生效-开机启动
   service redis_init_script start # 启动服务
   service redis_init_script stop # redis 服务器停止
   ```

   

6. cloudreve下载与安装(我用的是v3.8.3)

   ```
   # https://docs.cloudreve.org/zh/getting-started/install
   # 很早前还能访问这个文档，后来就404了，我觉得有必要记录下手册
   到这里下载合适自己系统的压缩包：
       https://github.com/cloudreve/Cloudreve/releases
   
   #解压获取到的主程序
   tar -zxvf cloudreve_VERSION_OS_ARCH.tar.gz
   
   # 赋予执行权限
   （我这里转移出来放置到了/data/www/cloudreve目录下）
   chmod +x ./cloudreve
   
   # 启动 Cloudreve
   ./cloudreve
   Cloudreve 默认会监听 5212 端口。你可以在浏览器中访问 http://localhost:5212进入 Cloudreve。请注册一个账户，首个注册的账户会被设置为管理员。
   ```

   配置下` conf.ini`（端口号和Redis）
   > 原本是在同级目录的配置（v3），现在的版本替换到了data目录下的配置(v4)。
   {: .prompt-warning }

   ```
   [System]
   Debug = false
   Mode = master
   Listen = :5212
   SessionSecret = Ins2Xsft8VfSJeGTjVffQr4qAGCucYVkwtS2kFxeINUub0Oi4G1Whs1QWzVsc7tw
   HashIDSalt = rCQ73j8ed3CjZCAdOQ6sS43Ha5xudeLIMk9BOwM0hF6SDHr4WWV1klLxcdzBLHWn
   
   [Redis]
   Server = 127.0.0.1:6379
   Password =
   DB = 0
   ```

   如果首次启动，会生成一个随机的密码，可以保存下来，下次开机启动就不会有这样的提示了。例如

   ```
   ## cloudreve 
   [Info]    2024-01-14 12:02:18 Admin user name: admin@cloudreve.org
   [Info]    2024-01-14 12:02:18 Admin password: KyA6W8Lg
   
   
   ###
   ```

   

   

7. 挂载了另一个机械盘，周末机器运行中，晚上自动执行计划任务

   `crontab` 

   ```
   
   # backup software
   10 22 * * *  rsync -av  /data/soft/  /backup/soft  >> /dev/null
   
   # backup www
   
   10 23 * * *  rsync -av  /data/www/  /backup/www  >> /dev/null
   
   # restart wifi
   
   10 3 * * *  /data/run/restart_wifi.sh  >> /dev/null 2&>1
   ```

   家里还有一个2012年购买的路由器，给用上链接到家庭网络，通过这个路由器映射下端口用，所以数据量大的时候路由器会不稳定导致死机，所以晚上自动重启下路由器。

## 开始使用

为了确保在家的时候，只要链接了wifi，家庭所有设备都可以访问网盘（例如看电视，备份照片等）

![jpg]({{site.images-path}}网络拓扑图.jpg)

1. PC端

   > http://192.168.1.2:5212/
   >
   > 使用首次生成的账号和密码：
   >
   > admin@cloudreve.org
   >
   > KyA6W8Lg

   

2. 移动端

   ```
   到机器上
   
   http://192.168.1.2/apk/
   
   下载`autosync` 安卓工具
   ```

   到【用户】新增用户，这里新增一个用户和密码，属于管理用的。

   然后通过这个设置好的用户，进行登录，再到【连接】功能区，进行创建新连接账号（**只是生成几个密码，留作客户端来同步文档用**）

   ```
   #webdav地址填写
   http://192.168.1.2:5212/dav
   
   账号填写带有邮箱的账号名
   密码填写创建的连接备注的密码（随机的一串数字）
   ```

   

## 结果

周末在家晚上充满电后，都可以开启自动同步文件功能，大概一小时就能同步好多G的照片到家庭网盘。

而且可以把图片从服务区上拷贝下或者用浏览器查看打包下载。

使用机械盘做数据备份，即使哪天机器坏掉了，两个同时坏掉的概率要低一些，间隔10年，更换硬件后，重新拷贝过去，又可以继续用。

