---
title: k8s - 卸载与安装
date: 2026-03-28 12:00:00 +0800
categories: ["k8s", "docker"]
tags: ["k8s","openclaw"]
author:
  name: wangfuyu
  email: yu2121wfy@qq.com
math: true 
img_path: /static/image/




---

## k8s -openClaw部署方案

> https://docs.openclaw.ai/install/docker
>
> https://docs.openclaw.ai/install/kubernetes
>
> 跟着官方文档走一圈。

### deploy.yaml

1. **Deployment**：管理 OpenCLAW 的 Pod 副本，确保它始终运行。
2. **Service (ClusterIP)**：在集群内部暴露端口，让 Ingress 能访问到。
3. **Ingress**：提供外部访问入口（例如通过域名或 IP 访问）。
4. **PersistentVolume (PV)**：用于保存 OpenCLAW 的数据（防止 Pod 重启后数据丢失）。

```
kubectl apply -f deploy-openclaw.yaml
```

文件参考本目录的`deploy-openclaw.yaml`

```yaml
    spec:
      containers:
      - name: openclaw
        image: ghcr.io/openclaw/openclaw:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 18789  # 请根据实际镜像暴露的端口修改
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m" #1000m (毫核) = 1 CPU。
          limits:
            memory: "512Mi"
            cpu: "500m"
```

```
<--- Last few GCs --->
[15:0x29006000]    54609 ms: Mark-Compact 251.7 (257.3) -> 250.7 (257.6) MB, pooled: 2 MB, 1014.07 / 0.00 ms  (average mu = 0.098, current mu = 0.005) allocation failure; scavenge might not succeed
[15:0x29006000]    55894 ms: Mark-Compact 251.7 (257.6) -> 250.7 (257.3) MB, pooled: 2 MB, 1280.89 / 0.00 ms  (average mu = 0.049, current mu = 0.004) allocation failure; scavenge might not succeed
FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory
----- Native stack trace -----
 1: 0x735eec node::OOMErrorHandler(char const*, v8::OOMDetails const&) [openclaw-gateway]
```

配置的资源太少了。需要适度调整。

```
<--- Last few GCs --->
[15:0x157a0000]    82816 ms: Mark-Compact 506.5 (514.2) -> 505.2 (515.2) MB, pooled: 0 MB, 2421.00 / 0.00 ms  (average mu = 0.196, current mu = 0.039) allocation failure; scavenge might not succeed
[15:0x157a0000]    85307 ms: Mark-Compact 507.3 (515.2) -> 506.4 (520.4) MB, pooled: 0 MB, 2398.79 / 0.00 ms  (average mu = 0.119, current mu = 0.037) allocation failure; scavenge might not succeed
FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory
----- Native stack trace -----
 1: 0x735eec node::OOMErrorHandler(char const*, v8::OOMDetails const&) [openclaw-gateway]
```

```
2026-03-28T06:53:55.403+00:00 [gateway] log file: /tmp/openclaw/openclaw-2026-03-28.log
2026-03-28T06:53:55.489+00:00 [browser/server] Browser control listening on http://127.0.0.1:18791/ (auth=token)
<--- Last few GCs --->
[15:0x3c775000]    57675 ms: Scavenge 911.4 (929.9) -> 906.3 (947.7) MB, pooled: 0 MB, 9.12 / 0.00 ms  (average mu = 0.343, current mu = 0.338) allocation failure; 
[15:0x3c775000]    60364 ms: Mark-Compact (reduce) 917.0 (948.6) -> 898.9 (918.2) MB, pooled: 0 MB, 497.51 / 0.00 ms  (+ 1840.0 ms in 158 steps since start of marking, biggest step 70.9 ms, walltime since start of marking 2689 ms) (average mu = 0.336, cur
FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory
----- Native stack trace -----

```

```
root@raha-0001:~# kubectl top nodes
NAME          CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
master-node   193m         9%       2204Mi          60%         
raha-0002     1559m        77%      2491Mi          68%  
```

```
2026-03-31T04:06:13.243+00:00 [gateway] agent model: ollama/qwen2.5-coder:3b
2026-03-31T04:06:13.246+00:00 [gateway] listening on ws://127.0.0.1:18789, ws://[::1]:18789 (PID 15)
2026-03-31T04:06:13.248+00:00 [gateway] log file: /tmp/openclaw/openclaw-2026-03-31.log
2026-03-31T04:06:13.369+00:00 [browser/server] Browser control listening on http://127.0.0.1:18791/ (auth=token)
<--- Last few GCs --->
[15:0x39f16000]    58643 ms: Scavenge 904.0 (923.4) -> 898.6 (941.4) MB, pooled: 0 MB, 8.74 / 0.00 ms  (average mu = 0.330, current mu = 0.317) allocation failure; 
[15:0x39f16000]    61423 ms: Mark-Compact (reduce) 906.1 (941.7) -> 887.1 (909.3) MB, pooled: 0 MB, 749.15 / 0.00 ms  (+ 1635.5 ms in 120 steps since start of marking, biggest step 70.7 ms, walltime since start of marking 2781 ms) (average mu = 0.338, cur
FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory
----- Native stack trace -----
 1: 0x735eec node::OOMErrorHandler(char const*, v8::OOMDetails const&) [openclaw-gateway]
```

> https://docs.openclaw.ai/install/docker
>
> 官方文档指出：
>
> ```
> Prerequisites
> Docker Desktop (or Docker Engine) + Docker Compose v2
> At least 2 GB RAM for image build (pnpm install may be OOM-killed on 1 GB hosts with exit 137)
> Enough disk for images and logs
> If running on a VPS/public host, review Security hardening for network exposure, especially Docker DOCKER-USER firewall policy.
> ```
>
> 至少2G的内存，否则会被OMM杀掉。
