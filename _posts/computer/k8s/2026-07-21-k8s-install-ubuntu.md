---
title: k8s - 安装- ubuntu
date: 2026-03-27 12:00:00 +0800
categories: ["k8s", "docker"]
tags: ["k8s"]
author:
  name: wangfuyu
  email: yu2121wfy@qq.com
math: true 
img_path: /static/image/




---

## k8s k8s - 安装- ubuntu

> **K8s v1.30**
>
>  **Ubuntu 22.04 官方源中的 `containerd` 版本过旧，无法满足 Kubernetes v1.30 和 gVisor 的兼容性及稳定性要求**。
>
> **`containerd`**> **`1.7.27`**

> 假设主节点IP：172.27.5.129

### 主机信息-系统、硬件

```
~# cat /etc/os-release
PRETTY_NAME="Ubuntu 22.04.2 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.2 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy
```



### Container安装

```shell
# 1. 添加 Docker 官方 GPG 密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 2. 添加 Docker 官方软件源
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 3. 更新包列表并安装 containerd.io
sudo apt-get update
sudo apt-get install -y containerd.io
apt install -y ca-certificates curl

# out
~# containerd --version
containerd containerd v2.2.6 11ce9d5f3c68c941867e82890e93e815c1304f1b
```



```shell
swapoff -a
 
#前置条件(转发 IPv4 并让 iptables 看到桥接流量)
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 设置所需的 sysctl 参数，参数在重新启动后保持不变
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# 应用 sysctl 参数而不重新启动
sudo sysctl --system
```

#### 重新生成默认

> 源文件只有一个简单的配置：disabled_plugins = ["cri"]。初始化一个完整的配置。

```shell
# 生成默认配置文件
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# 重启 containerd
sudo systemctl restart containerd
sudo systemctl enable containerd
```



### 安装 gVisor (runsc)

```shell
#下载 gVisor 二进制文件

ARCH=$(uname -m)
URL=https://storage.googleapis.com/gvisor/releases/release/latest/${ARCH}
wget ${URL}/runsc ${URL}/runsc.sha512 ${URL}/containerd-shim-runsc-v1 ${URL}/containerd-shim-runsc-v1.sha512
sha512sum -c runsc.sha512 -c containerd-shim-runsc-v1.sha512
rm -f *.sha512
chmod a+rx runsc containerd-shim-runsc-v1
mv runsc containerd-shim-runsc-v1 /usr/local/bin
```

#### 配置 containerd 支持 runsc

```shell

# 1. 还原一份最纯净的基础配置，并开启 Cgroup
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# 2. 告诉 Containerd 去读取外部目录（非常关键）
if grep -q "^imports =" /etc/containerd/config.toml; then
    sudo sed -i 's|^imports =.*|imports = ["/etc/containerd/config.toml.d/*.toml"]|' /etc/containerd/config.toml
else
    sudo sed -i '2i imports = ["/etc/containerd/config.toml.d/*.toml"]' /etc/containerd/config.toml
fi

# 3. 创建外挂目录
mkdir -p /etc/containerd/config.toml.d

# 4. 创建独立、绝对纯净的 gVisor 配置（这里我把 Containerd 1.x 和 2.0 最新版的所有可能路径全写上了，它会自动匹配你当前的版本，绝不会漏！）
cat <<EOF | sudo tee /etc/containerd/config.toml.d/gvisor.toml
version = 2

# 匹配 Containerd 1.6 / 1.7
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"

# 匹配 Containerd 2.0 (全路径)
[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"

# 匹配 Containerd 2.0 (扁平路径)
[plugins."io.containerd.cri.v1.runtime".runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
EOF


systemctl restart containerd
```

#### 配置 containerd 支持 私有仓库

> 
> /etc/containerd/config.toml
> 

```
#找到 [plugins."io.containerd.grpc.v1.cri".registry] 部分，如果不存在则添加
# 注意：如果已有 registry.mirrors 配置，直接在其后添加上述条目。
[plugins."io.containerd.grpc.v1.cri".registry.mirrors]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."172.27.5.129:30500"]
    endpoint = ["http://172.27.5.129:30500"]
    
# 每个node都要配置
systemctl restart containerd
```



### 安装 Kubernetes 组件 (v1.30) kubeadm、kubelet、kubectl

#### 官方源

```shell
# 添加 Kubernetes 官方 GPG 密钥
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 添加 Kubernetes v1.30 源
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 安装
sudo apt update
#sudo apt install -y kubelet=1.30.14-1.1 kubeadm=1.30.14-1.1 kubectl=1.30.14-1.1
#apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl   # 锁定版本，防止自动升级
```



#### master-node

```shell
kubeadm init --pod-network-cidr=10.244.0.0/16 --upload-certs
# 初始化成功后，会输出类似以下的 kubeadm join 命令，请保存好，后续用于添加工作节点。
## master其他主节点：
# 生成的证书密钥默 2 小时后失，
# 过期后需执行 kubeadm init phase upload-certs --upload-certs 重新生成才能加入新 Mastes
#

```

output:

> ```
> # 如果忘记了 token，可以在 master 节点重新生成
> kubeadm token create --print-join-command
> ```

```text
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.27.5.129:6443 --token 1shfd8.z054q6q8q4zto3sz \
        --discovery-token-ca-cert-hash sha256:61bcf8f5ae321654b0a8a86fd1c4e652e6cd5892a01f50ca55a760791ef42463 
```



配置kubectl

```
初始化成功后，终端会输出这三行命令，请以普通用户（或 root）身份执行：
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

```

允许master可以当作worker-node部署pod

```shell
# kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule
 
# kubectl taint nodes --all node-role.kubernetes.io/control-plane=true:NoSchedule

```

安装 Flannel 网络插件

```shell
# 如果有节点node 处于 NotReady，很可能：Network plugin returns error: cni plugin not initialized
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# 等待所有 Pod 状态变为 Running
kubectl get pods -n kube-flannel
```

创建 gVisor RuntimeClass

```shell
# gvisor-runtimeclass.yaml
cat <<EOF | tee gvisor-runtimeclass.yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
EOF

kubectl apply -f gvisor-runtimeclass.yaml

```



#### 安装dockerhub-registry-内部镜像仓库

registry.yaml 

> 宿主机器需要安装docker-cli工具：`apt-get install docker-ce-cli` 是不行的。
> 理由：：**Docker CLI 试图通过 HTTP 协议与 containerd 的 socket 通信，但 containerd 的 socket 使用的是 GRPC 协议，而不是 HTTP，因此通信失败**。
>
> #### `nerdctl` 来进行build
>
> ```shell
> # 下载最新版本（以 v2.0.0 为例）
> wget https://github.com/containerd/nerdctl/releases/download/v2.0.0/nerdctl-2.0.0-linux-amd64.tar.gz
> tar xvf nerdctl-2.0.0-linux-amd64.tar.gz
> sudo mv nerdctl /usr/local/bin/
> 
> ##为 nerdctl 配置 BuildKit（用于构建镜像）
> #nerdctl build 需要 BuildKit 作为后端。
> wget https://github.com/moby/buildkit/releases/download/v0.26.3/buildkit-v0.26.3.linux-amd64.tar.gz
> tar xvf buildkit-v0.26.3.linux-amd64.tar.gz
> sudo mv bin/* /usr/local/bin/
> 
> #启动 BuildKit 守护进程,可以改成systemctl
> sudo /usr/local/bin/buildkitd &
> 
> #使用 nerdctl 构建镜像：
> nerdctl build -t myapp .
> ```
>
> 

```yaml
apiVersion: v1
kind: Service
metadata:
  name: registry
spec:
  type: NodePort
  selector:
    app: registry
  ports:
  - port: 5000
    targetPort: 5000
    nodePort: 30500          # 可自定义，30000-32767
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce # RWO
  resources:
    requests:
      storage: 5Gi   # 根据需求调整，存镜像用
  # 如果集群有默认的RWX StorageClass，可以取消注释下面一行
  storageClassName: local-path # 默认kubectl get storageClass
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      nodeSelector:
        registry: host
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
        volumeMounts:
        - name: shared-storage
          mountPath: /var/lib/registry
        env:
        - name: REGISTRY_STORAGE_DELETE_ENABLED
          value: "true"               # 允许删除镜像
      volumes:
        - name: shared-storage
          persistentVolumeClaim:
            claimName: registry   # 引用上面创建的PVC
#       - name: storage
#         hostPath:
#           path: /data/registry
#           type: DirectoryOrCreate
```



#### worker-node

```
# kubeadm join 192.168.1.10:6443 --token <your-token> --discovery-token-ca-cert-hash sha256:<your-hash>
kubeadm join 172.27.5.129:6443 --token 1shfd8.z054q6q8q4zto3sz \
        --discovery-token-ca-cert-hash sha256:61bcf8f5ae321654b0a8a86fd1c4e652e6cd5892a01f50ca55a760791ef42463 
```



#### 创建卷

local-path-StorageClass.yaml

```
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.35/deploy/local-path-storage.yaml

#
# 查看 Provisioner Pod 状态
kubectl -n local-path-storage get pods

# 查看 StorageClass
kubectl get storageclass


## 个别例子
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: ""  # 标记为true默认StorageClass,空不默认[reference:1]
provisioner: rancher.io/local-path                         # 指定存储提供者[reference:2][reference:3]
volumeBindingMode: WaitForFirstConsumer                   # 延迟绑定，直到Pod被调度[reference:4]
reclaimPolicy: Delete                                     # 删除PVC时，同时删除PV及其数据[reference:5]
```

### 代理服务

openclaw-proxy.yaml

```yaml
# openclaw-proxy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openclaw-proxy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: openclaw-proxy
  template:
    metadata:
      labels:
        app: openclaw-proxy
    spec:
      restartPolicy: Always
      runtimeClassName: gvisor
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        - containerPort: 9090
        command: ["/bin/sh", "-c"]
        args:
        - |
          cat > /etc/nginx/conf.d/default.conf <<'EOF'

          resolver kube-dns.kube-system.svc.cluster.local valid=10s;

          server {
              listen 80;
              location ~ ^/u/(?<user_id>[^/]+)/(?<path>.*)$ {
                  set $backend "openclaw-$user_id.default.svc.cluster.local";
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
                  set $user_id $http_x_user_id;
                  set $backend "openclaw-$user_id.default.svc.cluster.local";
                  grpc_pass grpc://$backend:9090;
                  grpc_set_header X-User-Id $user_id;
                  grpc_read_timeout 86400s;
              }
          }
          EOF
          exec nginx -g "daemon off;"
        volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx/conf.d
        - name: nginx-run
          mountPath: /var/run
        - name: cache
          mountPath: /var/cache/nginx
      volumes:
      - name: nginx-conf
        emptyDir: {}
      - name: nginx-run
        emptyDir: {}
      - name: cache
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: openclaw-proxy
spec:
  type: NodePort
  selector:
    app: openclaw-proxy
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



### 每个node 设置一个标签

```
kubectl label nodes claw-0001 registry=claw-0001

# 使用的时候
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      nodeSelector:
        registry: claw-0001 # 选择节点标签
      containers:
      - name: registry
        ...
```



### todo晋级版，对pod出口网络控制（NetworkPolicy）

暂时不考虑，因为尝试过程中，莫名其妙多出2000个pod。

> network_policy.yaml
>
> ```shell
> # 检测支持项
> kubectl get pods -n kube-system | grep -E 'calico|cilium|flannel|weave|antrea'
> 
> # 安装 Calico 操作器
> kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.5/manifests/tigera-operator.yaml
> # 应用安装资源
> kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.5/manifests/custom-resources.yaml
> 
> #验证安装
> # kubectl get pods -n calico-system
>  kubectl get pods -n kube-system
>  kubectl get pods -n tigera-operator
> ```

####  首先. 集群内访问：通过 Service 名称定义规则

下面的例子允许带有标签 `network: claw-network-policy` 的 Pod 访问 `kube-system` 命名空间下的 `kube-dns` 服务（即 CoreDNS）

```yaml
apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: allow-cluster-services
  namespace: default
spec:
  selector: network == 'claw-network-policy'
  types:
  - Egress
  egress:
  - action: Allow
    destination:
      services:
        name: kube-dns
        namespace: kube-system
```

####  集群外访问：通过域名定义规则（使用 NetworkSet）

**第一步：创建 NetworkSet 定义允许的域名**

```
apiVersion: projectcalico.org/v3
kind: NetworkSet
metadata:
  name: allowed-domains
  namespace: default
  labels:
    allow-egress: "true"
spec:
  allowedEgressDomains:
  - 'www.deepseek.com'
```

**第二步：在 NetworkPolicy 中引用 NetworkSet**

```

apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: claw-egress-policy
  namespace: default
spec:
  selector: network == 'claw-network-policy'
  types:
  - Egress
  egress:
  # 规则1: 允许访问指定 IP 和端口
  - action: Allow
    destination:
      nets:
      - 172.27.3.189/32
      ports:
      - 8218
      - 8318
      - 8208
  # 规则2: 允许访问 NetworkSet 中定义的域名
  - action: Allow
    destination:
      selector: allow-egress == 'true'
      ports:
      - 443
```

