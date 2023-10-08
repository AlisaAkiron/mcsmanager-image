# MCSManager Docker Image

[MCSManager](https://github.com/MCSManager/MCSManager/) 的 Docker 镜像

[简体中文](README-cn.md) | [English](README.md)

## Tag

- `latest`：最新版本
- `9.6.0`：指定版本
- `9.6`：指定主版本和次版本，将指向最新的 Patch 版本
- `9`：指定主版本，将指向当前大版本号下的最新版本
- `sha-e278f4c`: 指定 Commit

## 使用方法

### Web

使用 Docker CLI

```bash
docker run -it -d \
    --name mcsm-web \
    -p 23333:23333 \
    -v /path/to/data:/opt/mcsmanager/web/data \
    alisaqaq/mcsmanager-web:latest
```

使用 Docker Compose

```yaml
version: "3"

services:
  mcsm-web:
    image: alisaqaq/mcsmanager-web:latest
    container_name: mcsm-web
    ports:
      - "23333:23333"
    volumes:
      - /path/to/data:/opt/mcsmanager/web/data
    restart: unless-stopped
```

### Daemon

使用 Docker CLI

```bash
docker run -it -d \
    --name mcsm-daemon \
    -p 24444:24444 \
    -v /path/to/data:/opt/mcsmanager/daemon/data \
    -v /var/run/docker.sock:/var/run/docker.sock \
    alisaqaq/mcsmanager-daemon:latest
```

使用 Docker Compose

```yaml
version: "3"

services:
  mcsm-daemon:
    image: alisaqaq/mcsmanager-daemon:latest
    container_name: mcsm-daemon
    ports:
      - "24444:24444"
    volumes:
      - /path/to/data:/opt/mcsmanager/daemon/data
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
```

## 在 Kubernetes 中使用 MCSManager WebUI

> Daemon 不建议在 Kubernetes 中使用

使用 Config Map 存储自定义的配置文件，如果不需要对配置文件进行自定义，可以不创建该资源。

请注意，配置文件是在 InitContainer 中复制进入 Volume 中的，因此在每一次启动中，都会覆盖掉 Volume 中的配置文件

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: mcsm-web-config
  namespace: mcsm
data:
  config.json: |
    {
        "httpPort": 23333,
        "httpIp": null,
        "dataPort": 23334,
        "forwardType": 1,
        "crossDomain": false,
        "gzip": false,
        "maxCompress": 1,
        "maxDonwload": 10,
        "zipType": 1,
        "loginCheckIp": true,
        "loginInfo": "",
        "canFileManager": true,
        "language": "zh_cn"
    }
```

使用 PersistentVolumeClaim 存储 MCSManager 的数据，你可以使用 HostPath 或其他的方式来实现。

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mcsm-web-pvc
  namespace: mcsm
  labels:
    app: mcsm-web-pvc
spec:
  storageClassName: nfs-1
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

创建 Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcsm-web
  namespace: mcsm
  labels:
    app: mcsm-web
spec:
  selector:
    matchLabels:
      app: mcsm-web
  replicas: 1
  template:
    metadata:
      labels:
        app: mcsm-web
    spec:
      # 如果没有自定义配置文件，不需要下面的 InitContainer
      initContainers:
        - name: configuration
          image: busybox:1.28
          volumeMounts:
            - mountPath: /data
              name: data
            - mountPath: /custom-config
              name: custom-config
          command:
            [
              "sh",
              "-c",
              "mkdir -p /data/SystemConfig && cp -f /custom-config/config.json /data/SystemConfig/config.json",
            ]
      containers:
        - name: mcsm-web
          image: docker.io/alisaqaq/mcsmanager-web:latest
          resources:
            requests:
              cpu: 100m
              memory: 100Mi
            limits:
              cpu: 200m
              memory: 200Mi
          ports:
            - containerPort: 23333
              name: mcsm-web
          volumeMounts:
            - name: data
              mountPath: /opt/mcsmanager/web/data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: mcsm-web-pvc
        # 如果没有自定义配置文件，不需要下面的 Volome
        - name: custom-config
          configMap:
            name: mcsm-web-config
            items:
              - key: config.json
                path: config.json
      restartPolicy: Always
```

创建 Service，你可以选择使用其他的方式来暴露服务，此处示例使用 ClusterIP 配合 Ingress 的方式

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mcsm-web
  namespace: mcsm
spec:
  selector:
    app: mcsm-web
  type: ClusterIP
  ports:
    - name: mcsm-web
      protocol: TCP
      port: 80
      targetPort: 23333
```

创建 Ingress 暴露服务

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mcsm-web-ingress
  namespace: mcsm
  annotations:
    # 如果使用其他的 Ingress Controller，需要修改此处
    # 或者增加其他自定义的 Annotation
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  # 如果使用其他的 Ingress Controller，需要修改此处
  ingressClassName: "traefik"
  tls:
    - hosts:
        - mcsm.example.com
      secretName: mcsm-web-cert # SSL 证书 Secret
  rules:
    - host: mcsm.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: mcsm-web
                port:
                  number: 80
```
