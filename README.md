# 离线安装Kube-Prometheus

**1. 在线获取安装包和镜像**

部署机安装docker，保持网络在线，执行：
```
bash init.sh
```
以上命令会下载kube-prometheus的源码包并自动将项目依赖的全部docker镜像下载保存

**2. K8s节点准备工作**

每个k8s节点修改时区
```
timedatectl set-timezone Asia/Shanghai
date -s 正确时间
hwclock -w
```

每个k8s master节点执行：
```
cd install-kube-prometheus
./fix-k8s-master-nodes.sh
cd ../../
```

每个k8s worker节点执行：
```
cd install-kube-prometheus
./fix-k8s-worker-nodes.sh
cd ../../
```

**3. 离线部署**

拷贝部署机整个install目录至一个k8s worker节点，修改一下components.txt里的变量：

将MyImageRepositoryIP=192.168.9.20修改成实际的私有镜像仓库地址，并执行：
```
cd install-kube-prometheus
bash deploy.sh
```
