---
title: learn - 项目架构演变-07（dagu一个工作流当作部署工具）
author: "wangfuyu"
description: >-
  小项目，快速接入工作流部署环节，dagu。
date: 2026-08-11 12:00:00 +0800
categories: ["computer", "project"]
tags: ["computer", "project", "CICD"]
math: true 
img_path: /static/image/






---

## 创作背景

我们在从0到1快速搭建项目，有快速版本迭代上线，当节奏突然放缓以后，也就是我们开始用户有增长，肯定要考虑项目的“稳”。

## 目标

- 低成本：要求一个二进制文件运行，占用内存低。
- 快速：适配项目快节奏的快速上线用的shell。
- 版本回退可控：以前用户少，真出先问题，代码回退以后在编译打包上线；但是用户多了的话，要考虑影响范围了，要及时回退到上一版本可用状态，再去排查问题、修复问题。

## 行动

### 方案选型

> - **Jenkins**：通过 Web 界面进行复杂配置，或编写 **Groovy 脚本（Jenkinsfile）** 定义流水线。学习曲线较陡，但灵活性极高。
> - **Drone**：在项目根目录创建 **`.drone.yml`** 文件即可。YAML 结构清晰，每个 `step` 对应一个容器镜像，易于上手。
> - **Dagu**：通过 **YAML 文件**定义工作流（DAG）-，支持 `command`、`docker`、`ssh`、`http` 等多种步骤类型。可以直接调用你现有的任何脚本。

我自己用过`Jenkins`，比较“重”，占用资源高吧，比如我买的`1g2c`的云机器，可能运行其他的程序也会卡一些。

我也试了试`Drone`，是用git仓库进行关联的，账号需要用git自建的仓库来登陆，耦合重，不灵活。

决定`Dagu`,账号独立，可以自定义工作流来当作部署项目用，把个人负责的项目中相关的`build.sh` 和`deploy.sh`关联上就行。

但是我不想在我的那台`1g2c`的云机器上进行编译项目代码，太慢了！用mac pro M4去编译代码，编译完成传到机器上一样好。

![借道超车]({{site.images-path}}project-07-dagu.jpg)

### 部署使用

- 版本

  >  dagu version
  > 2.13.0

  https://github.com/dagucloud/dagu/releases

  昨天新打的release标签，

  https://github.com/dagucloud/dagu/releases/download/v2.13.0/dagu_2.13.0_linux_amd64.tar.gz

- 环境变量配置启动方案

  `run.sh`

  ```shell
  #!/bin/bash
  
  export WORKDIR="/data/chatraha/dagu"
  export DAGU_TZ=Asia/Shanghai
  export DAGU_HOME=$WORKDIR
  export PATH=$PATH:$WORKDIR/bin
  export DAGU_HOST=0.0.0.0
  export DAGU_PORT=8880
  
  $WORKDIR/bin/dagu server
  ```

  我自己在前面一层加了个proxy，发现会出现cors问题，建议直接用`配置文件启动方案`。

  

- **配置文件启动方案**

  > https://docs.dagu.sh/server-admin/reference

  `config.yaml`

  ```yaml
  host: 0.0.0.0
  port: 8000 # 自己定义端口
  public_url: http://localhost.ai # 随便定义个本地用的，
  base_path: ""
  tz: "Asia/Shanghai"
  debug: true
  log_format: "json" 
  access_log_mode: "non-public"
  check_updates: false
  cors_allowed_origins: ["localhost.ai"]
  
  auth:
    mode: builtin
    builtin:
      token:
        secret: "localhost"
        ttl: "1h"
  
  
  queues:
    enabled: true
  paths:
    dags_dir: /data/chatraha/dagu/dags
    wiki_dir: /data/chatraha/dagu/dags/wiki
    log_dir: /data/chatraha/dagu/logs
    data_dir: /data/chatraha/dagu/data
    dag_state_dir: /data/chatraha/dagu/data/dag-state
  ```

  `run.sh`

  ```shell
  #!/bin/bash
  
  export WORKDIR="/data/chatraha/dagu"
  $WORKDIR/bin/dagu server --config /data/chatraha/dagu/config.yaml
  ```

- 然后配置下nginx，解析一下内网域名，就可以用了。

- 配置守护进程

  ```toml
  [Unit]
  Description=Dagu server
  After=syslog.target network.target remote-fs.target nss-lookup.target
  
  [Service]
  Type=simple
  User=root
  PIDFile=/var/run/dagu.pid
  ExecStart=/bin/bash -c 'exec /data/chatraha/dagu/bin/dagu server --config /data/chatraha/dagu/config.yaml >>/data/chatraha/dagu/logs/out.log 2>&1'
  WorkingDirectory=/data/chatraha/dagu
  Restart=always
  RestartSec=5s
  PrivateTmp=true
  StartLimitInterval=0
  LimitCORE=infinity
  LimitNOFILE=65555
  
  [Install]
  WantedBy=multi-user.target
  ```

  



## 结论点

1. 需要把工作流程的yaml文件保存的git仓库，故障时可以快速重装恢复。
2. 注意区分各自环境，建议用工作空间和账号区分。
3. 提醒流水线接入随时知道哪个项目上线过，有记录可查。





