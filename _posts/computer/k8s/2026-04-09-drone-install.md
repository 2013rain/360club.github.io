---
title: k8s - drone的安装
date: 2026-03-28 12:00:00 +0800
categories: ["k8s", "docker"]
tags: ["k8s","drone", "docker"]
author:
  name: wangfuyu
  email: yu2121wfy@qq.com
math: true 
img_path: /static/image/





---

## k8s -云原生Ci工具 drone

> https://docs.drone.io/
>
> https://www.drone.io/
>
> 跟着官方文档走一圈。

### 使用docker-compose一键搭建服务

#### 失败经历

背景介绍： mac安装了 【Docker Destop】,然后挂在执行文件docker时，就用不了docker命令。

```shell
ll /usr/local/bin/docker
lrwxr-xr-x@ 1 root  wheel  54 Dec 29 14:13 /usr/local/bin/docker -> /Applications/Docker.app/Contents/Resources/bin/docker

```

比如挂载`/usr/local/bin/docker` 这个到容器中，会发现这个不存在的，本身就是一个软连接。

然后我改成了`/Applications/Docker.app/Contents/Resources/bin/docker`, 但是运行不起来，yml文件执行就提示这个：
```
Error response from daemon: mounts denied: 
The path /Applications/Docker.app/Contents/Resources/bin/docker is not shared from the host and is not known to Docker.
You can configure shared paths from Docker -> Preferences... -> Resources -> File Sharing.

```

然后我共享了目录...能执行yml文件了，但是在容器中却不能执行该命令：
```
/ # docker info
/usr/local/bin/docker: line 1: 
                               : not found
/usr/local/bin/docker: line 2: syntax error: unexpected "("
/ # 

```

放弃使用这种方式，到服务器上来一遍看看。

> 出现clone disable之类的错误，也就是下载不了代码。

#### 本地直接用上一体的

也是阻塞在第一步，没有任何提示。我怀疑是gogs的版本太高了，等下次有时间，降低一下试试看，附上`docker-compose.yml`文件：

```
#Aversion: '3.8'
services:
  gogs-server:
    image: gogs/gogs:0.13.3
    container_name: gogs-server
    restart: always
    ports:
      - "10880:3000"
      - "10022:22"
    volumes:
      - ./gogs/:/data
      - /etc/localtime:/etc/localtime:ro  # 只读挂载
    networks:
      - drone-net
  drone-server:
    image: drone/drone:latest
    container_name: drone-server
    restart: always
    ports:
      - "8880:80"
    volumes:
      - ./data/:/data
      - /etc/localtime:/etc/localtime:ro  # 只读挂载
    environment:
      - DRONE_AGENTS_ENABLED=true # admin 的密码
      - DRONE_GOGS_SERVER=http://192.168.110.170:10880
      - DRONE_RPC_SECRET=secret
      - DRONE_SERVER_HOST=192.168.110.170:8880
      - DRONE_SERVER_PROTO=http
      - DRONE_GOGS_SKIP_VERIFY=true
    networks:
      - drone-net
    depends_on:
      - gogs-server

  drone-runner:
    image: drone/drone-runner-docker:latest
    container_name: drone-runner
    restart: always
    ports:
      - "3000:3000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro  # 只读挂载
      - /etc/localtime:/etc/localtime:ro  # 只读挂载
    environment:
      - DRONE_RPC_PROTO=http # admin 的密码
      - DRONE_RPC_HOST=192.168.110.170:8880 # 不使用192.168.110.170:8880
      - DRONE_RPC_SECRET=secret
      - DRONE_RUNNER_CAPACITY=2
      - DRONE_RUNNER_NAME=my-runner
    networks:
      - drone-net
    depends_on:
      - drone-server

networks:
  drone-net:
    driver: bridge

```

