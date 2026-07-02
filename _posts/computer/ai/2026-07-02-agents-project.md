---
title: AI - agents-project（Agents-SAAS）
date: 2026-07-02 12:00:00 +0800
categories: [ "ai","agents"  ]
tags: [ "ai","agents" ]
author: wangfuyu
math: true 





---

## agents-project（Agents-SAAS）

AI智能体的技术栈已经从单纯的“调用API”演变为一个包含感知、决策、记忆、执行四个核心维度的复杂系统。

我这边设计了一个面向多租户的AI Agent服务平台，未来肯定有一大批企业都在部署AI Agent驱动的应用。



### 我理解的Agents-SaaS

SAAS : 软件即是服务，又名软件运营服务。

无非理解透是按需租用就行。

那现在还没有太多AI方面的SAAS，都是靠tokens、Credits、Coins作为货币进行计费交易，然后自己“买断”一些模型（其实就是不让你选择自己第三方购买的，只能在这家用），然后赚个差价、服务价。

我按照业界普遍的经典三层架构来设计，自顶向下分别为：**表现层**、**业务层**和**持久化层**-。这种分层设计兼顾了高内聚、低耦合的架构原则，使各层可以独立演进和扩展性。



### 来张图

![jpg]({{site.images-path}}ai-project-01.jpg)

### 围绕重点讲

- 表现层：多端触达，统一体验

  > 表现层是平台与用户交互的窗口，我们设计了三种接入方式：
  >
  > 1. **APP 应用程序**：面向移动端用户，提供轻量级的Agent交互体验，支持语音输入、推送通知等移动端特性。
  >
  > 2. **Web 跨平台端**：基于现代前端框架构建的响应式Web应用，支持桌面与移动浏览器访问，是用户使用平台的主要入口。
  >
  > 3. **OpenAPI 对外开放入口**：这是平台能力对外开放的桥梁。通过标准化的RESTful API和WebSocket接口，第三方系统可以集成Agent能力，实现AI能力的生态化扩展。
  
  三层表现层共享同一套后端服务，通过统一的认证与鉴权机制确保数据安全与租户隔离。

- 业务层：核心能力引擎

  > 业务层是整个平台的心脏，承载了Agent运行的全部核心逻辑。
  >
  > 1. Gateway-Proxy-API（网关代理层）
  >     网关代理层是所有请求的统一入口，承担着路由转发、身份鉴权、限流控制、协议转换等核心职责。在AI场景下，网关需要处理的不再是单纯的RESTful或gRPC请求，还包括大模型特有的流式响应（SSE/WebSocket）等协议。
  >
  > 2. 统一协议逻辑层
  >
  >    这一层封装了Agent运行时的核心业务流程，例如会话管理、消息推送、数据统一定义转换。
  >
  > 3. claw-server 集群（租户）
  >
  >     claw-server 是Agent运行时实例，承载了Agent的实际执行逻辑。每个claw-server实例都是一个独立的Agent运行时容器，具备完整的推理、决策与工具调用能力。
  >
  > 4. LLM-Proxy（大语言模型代理）
  >
  >     LLM-Proxy 是平台与大模型交互的中间层-。它的核心价值在于**抽象化**了对不同大模型的访问，使上层应用无需关心底层模型的具体API差异。
  >
  >     记录每一次LLM调用的Token消耗与成本，为租户计费和成本优化提供数据支撑。
  >
  > 5. Tools-Proxy（工具代理）
  >
  >     Agent不仅需要“思考”，更需要“行动”——调用外部工具完成具体任务。
  >
  >     持续能力对接，如web_search（网页搜索）、计算器、天气查询等。
  >
  > 

  

- 持久化层：数据底座（数据隔离，产物输出）

  > 持久化层为平台提供可靠的数据存储能力：
  > 
  > SqliteDB：用于轻量级场景，如本地开发测试、边缘部署等。
  > 
  > MySQL：作为主数据库，存储用户信息、租户配置、会话记录、Agent元数据等结构化数据。
  > 
  > OSS / OBS：对象存储服务，用于存放非结构化数据，如Agent上传的文档、图片、日志归档等。

  

### 关于入k8s的一点记录

1. 前提是，所有的租户单独开一个pod使用，租期到了就延缓一周进行清理（给租户一个筹备期，虽然没有真正在续费到，总是留个念想）。

   

   ```go
   import (
   	"wangfuyu/ai-gateway/config2"
   	"fmt"
   
   	"k8s.io/client-go/kubernetes"
   	"k8s.io/client-go/tools/clientcmd"
   )
   
   func newClient() (*kubernetes.Clientset, error) {
   	// Create the client configuration from the kubeconfig file.
   	restCfg, err := clientcmd.RESTConfigFromKubeConfig(config2.K8sData.Config)
   	if err != nil {
       //todo err handler
   		return nil, err
   	}
   	clientSet, err := kubernetes.NewForConfig(restCfg)
   	if err != nil {
       //todo err handler
   		return nil, err
   	}
   
   	return clientSet, nil
   }
   //todo 部署、删除、PVC等
   ```

   

2. pod+deployment+service(或者Headless service)

   ```shell
   #一个dockerfile
   #如果要安装：golang\node工具（其实也可以直接ADD .tar.gz文件进去，主要看两者对于结果镜像影响大小）
   ARG GO_IMAGE=golang:1.25-bookworm
   ARG NODE_IMAGE=node:20-bookworm-slim
   ARG RUNTIME_IMAGE=debian:12-slim #使用这个当作基础镜像
   FROM ${GO_IMAGE} AS go-toolchain
   FROM ${NODE_IMAGE} AS node-runtime
   
   FROM ${RUNTIME_IMAGE}
   COPY --from=go-toolchain /usr/local/go /usr/local/go
   COPY --from=node-runtime /usr/local/bin/node /usr/local/bin/node
   COPY --from=node-runtime /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
   RUN apt-get update \
     && apt-get install -y --no-install-recommends \
       ca-certificates \
       coreutils \
       diffutils \
       ffmpeg \
       git \
       gzip \
       patch \
       python3 \
       python3-pip \
       ripgrep \
       tar \
       unzip \
     && rm -rf /var/lib/apt/lists/*
   RUN useradd --uid 10001 --gid 0 --home-dir /home/claw --create-home claw \
     && mkdir -p /home/claw/.claw /tmp/claw \
     && chown -R 10001:0 /home/claw /tmp/claw  
   #todo 其他操作
   ...
   # 编号1的进程
   ENTRYPOINT ["/usr/local/bin/run"] 
   
   ```

   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   # 创建一个PVC,我用了集群node自己的storageClass,如果有共享盘，我觉得最好用共享盘
   metadata:
     name: "{{REPLACE-DEPLOYMENT-NAME}}"
     namespace: default
   spec:
     accessModes:
       - ReadWriteOnce # RWO
     resources:
       requests:
         storage: 10Gi   # 根据需求调整
     # 如果集群有默认的RWX StorageClass，可以取消注释下面一行
     storageClassName: local-path # 默认kubectl get storageClass
   
   ```

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: "{{REPLACE-DEPLOYMENT-NAME}}"
     labels:
       app: "u{{REPLACE-USER-ID}}"
   spec:
     selector:
       app: "u{{REPLACE-USER-ID}}"
     ports:
     - name: grpc
       port: 9000
       targetPort: 10001 #这个都是自己定的。默认30000 到 32767，自己定义个10000的也行
   ```

   ```yaml
   
   # kubectl apply -f deployment-hello.yaml,实际部署pod
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: "{{REPLACE-DEPLOYMENT-NAME}}"  # Deployment 自身标识：名称 + 命名空间唯一（与 Pod 类似）
     labels:
       app: "u{{REPLACE-USER-ID}}"
   spec:
     replicas: 1  #  永远只运行一个实例
     strategy:
       type: Recreate  # 默认 RollingUpdate 策略，绝对不能容忍双 Pod 同时存在，可以把 strategy.type 改为 Recreate
     revisionHistoryLimit: 2   # 减少历史版本
     selector:
       matchLabels:
         app: "u{{REPLACE-USER-ID}}" # 用来匹配 Pod 的标签
     template:
       metadata:
         labels:
           app: "u{{REPLACE-USER-ID}}"
       spec:
         restartPolicy: Always    # Pod 异常退出后自动重启（默认就是 Always，可省略）
         runtimeClassName: gvisor  # 关键：指定使用 gvisor 运行时
         containers:
         initContainers:
           - name: "init-server"
             image: busybox:latest
             imagePullPolicy: IfNotPresent # Always 、 IfNotPresent
             command:
               - /bin/sh
               - -c
               - |
                 cat > /etc/server/conf <<'EOF'
                 hello world
                 EOF
                
             volumeMounts:
               - name: empty-data
                 mountPath: /run/server/  # 挂载路径
         - name: "main-server" # 容器名称前缀
           image: 192.178.1.11:6666/hello-world:latest # 局域网安装一个dockerhub方便部署
           imagePullPolicy: IfNotPresent
           ports:
             - containerPort: 12345  # 容器端口，rpc 服务
               protocol: TCP
           securityContext:
             allowPrivilegeEscalation: false
             readOnlyRootFilesystem: true
             capabilities:
               drop: [ "ALL" ]
           resources:
             requests:
               cpu: 10m
               memory: 32Mi
             limits:
               cpu: 250m
               memory: 128Mi
           env:
             - name: MY_POD_IP  # 分配 Pod IP 到环境变量
               valueFrom:
                 fieldRef:
                   fieldPath: status.podIP
             - name: MY_POD_USER_ID
               value: "{{REPLACE-USER-ID}}"
           volumeMounts:
             - name: empty-data
               mountPath: /etc/server  # 挂载路径
             - name: shared-storage
               mountPath: /home/claw   # 挂载路径
         volumes:
           - name: shared-storage
             persistentVolumeClaim:
               claimName: "{{REPLACE-DEPLOYMENT-NAME}}"   # 引用上面创建的PVC
   
   
   ```

   

3. Ai-Gateway （Gateway-Proxy 或者统一逻辑层）如果也一起部署在同一个集群的话，可以直接通过SVC来访问。

4. 如果3要部署在k8s集群外部，那么与1进行通信可以通过这个简单的代理来实现：nginx+service+nodeport。

   ```yaml
   
   # one-proxy.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: one-proxy
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: one-proxy
     template:
       metadata:
         labels:
           app: one-proxy
       spec:
         containers:
         initContainers:
           - name: "init-server"
             image: busybox:latest
             imagePullPolicy: IfNotPresent # Always 、 IfNotPresent
             command:
               - /bin/sh
               - -c
               - |
                 cat > /etc/nginx/conf.d/default.conf  <<'EOF'
                 resolver kube-dns.kube-system.svc.cluster.local valid=10s;
   
                 server {
                     listen 80;
                     location ~ ^/u/(?<user_id>[^/]+)/(?<path>.*)$ {
                         set $backend "{{serviceName}}-$user_id.default.svc.cluster.local";
                         proxy_pass http://$backend:8080/$path$is_args$args;
                         proxy_http_version 1.1;
                         proxy_set_header Upgrade $http_upgrade;
                         proxy_set_header Connection "upgrade";
                         proxy_read_timeout 86400s;
                     }
                 }
                 server {
                     listen 9090 http2;
                     location / {
                         set $user_id $http_x_user_id; #一个demo
                         set $backend "{{serviceName}}-user_id.default.svc.cluster.local";
                         grpc_pass grpc://$backend:9090;
                         grpc_set_header X-User-Id $user_id;
                         grpc_read_timeout 86400s;
                     }
                 }
                 EOF
                
             volumeMounts:
               - name: empty-data
                 mountPath: /etc/nginx/conf.d/  # 挂载路径
           - name: nginx
             image: nginx:alpine
             ports:
             - containerPort: 80
             - containerPort: 9090
             volumeMounts:
               - name: empty-data
                 mountPath: /etc/nginx/conf.d/  # 挂载路径
           volumes:
           - name: empty-data
             emptyDir: {}
   
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: one-proxy
   spec:
     type: NodePort
     selector:
       app: one-proxy
     ports:
     - name: http
       port: 80
       targetPort: 80
       nodePort: 30080
     - name: grpc
       port: 9090
       targetPort: 9090
       nodePort: 30090
   
   ```

   

5. LLM-Proxy和ToolsProxy 按需是否要在每个k8s集群中部署一个，因为也就是只给2使用的（除非还有其他微服务也可能会用）。

6. 所有pod进行隔离，使用gvisor (自行查询如何安装gvisor)

   ```yaml
   apiVersion: node.k8s.io/v1
   kind: RuntimeClass
   metadata:
     name: gvisor
   handler: runsc
   ```

   



### 结论

我这个Agent-SAAS 平台从架构设计到落地实施，经历了从概念验证到生产级部署的完整过程。三层架构的清晰分层、LLM-Proxy与Tools-Proxy的双代理设计、以及Kubernetes原生多租户隔离方案，共同构成了一个**安全、可扩展、可观测**的AI Agent服务平台。

**分层是架构的灵魂**：清晰的分层让每一层的职责一目了然，也使得各层可以独立演进。我之前的文章有架构按照五层划分，也是这样来的，只不过把数据层和逻辑层重新柔和清洗分层。