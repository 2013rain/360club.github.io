---
title: k8s - 节点增加监控node-exporter
date: 2026-07-24 12:00:00 +0800
categories: ["k8s", "node-exporter","prometheus"]
tags: ["k8s","node-exporter","prometheus"]
author:
  name: wangfuyu
  email: yu2121wfy@qq.com
math: true 
img_path: /static/image/







---

## k8s - 节点增加监控node-exporter



### 安装node-exporter

```shell
wget https://github.com/prometheus/node_exporter/releases/download/v1.11.1/node_exporter-1.11.1.linux-amd64.tar.gz
tar xvf node_exporter-1.11.1.linux-amd64.tar.gz

cp node_exporter-1.11.1.linux-amd64/node_exporter /opt/node_exporter/node_exporter

# 是否需要单独开一个账户运行，自行决定
```



### 配置服务管理

```shell
# /etc/systemd/system/node_exporter.service 
cat <<EOF | tee /etc/systemd/system/node_exporter.service 
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/opt/node_exporter/node_exporter

[Install]
WantedBy=multi-user.target
EOF



systemctl daemon-reload

systemctl start node_exporter
systemctl status node_exporter

# 开机启动
systemctl enable node_exporter


```

默认端口 9100，也可以指定端口：

> ```
> ExecStart=/usr/local/bin/node_exporter \
>     --web.listen-address=:9100 \
>     --collector.systemd \
>     --collector.processes
> ```



### 配置prometheus抓取

如果端口不可直接访问，可以集中到一个网络抓取
```yaml
location /test/ { rewrite ^/test/(.*)$ /$1 break; proxy_pass http://192.168.1.110:9100; }
```

如果promethuse配置了外部json文件,类似这样，则直接写json

```yaml
  ...
  - job_name: 'node_exporter'
    file_sd_configs:
      - files:
        - './targets/node*.json'
        refresh_interval: 30s
   ...
```

```json
[
  {
    "targets": ["wangfuyu.aliyun.com:80"],
    "labels": {
      "__metrics_path__": "/test/metrics",
      "instance": "test",
      "env": "production"
    }
  }
]
```

如果promethuse也采用了服务管理方式。

```
cat /etc/systemd/system/prometheus.service 
[Unit]
Description=Prometheus Monitoring System
After=network.target   # 确保在网络就绪后启动

[Service]
Type=simple
ExecStart=/opt/prometheus/prometheus \
  --config.file=/opt/prometheus/prometheus.yml \
  --web.external-url=/raha-prometheus \
  --web.route-prefix="/"

Restart=on-failure     # 服务异常退出时自动重启
RestartSec=5
WorkingDirectory=/opt/prometheus

[Install]
WantedBy=multi-user.target
```

```
# 验证是否有问题
./promtool check config prometheus.yml

systemctl restart prometheus
```



### 告警规则rules

业务端,可以参考官网例子



### 告警对接

飞书群、钉钉群、短信、邮件、微信等



## 结论

整个流向：

node -> prometheus（主动pull数据）-> alert_rules (告警规则) ->  app（push消息到接收端）

