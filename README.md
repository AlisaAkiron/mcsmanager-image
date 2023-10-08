# MCSManager Docker Image

Docker Image for [MCSManager](https://github.com/MCSManager/MCSManager/)

[简体中文](README-cn.md) | [English](README.md)

## Tag

- `latest`：The latest version
- `9.6.0`：Specific version, the corresponding image will be selected automatically according to the system architecture
- `9.6`：Specific major and minor version, the latest Patch version will be pointed to
- `9`：Specific major version, the latest version under the current major version number will be pointed to
- `sha-e278f4c`: Specific commit

## Usage

### Web

Use Docker CLI

```bash
docker run -it -d \
    --name mcsm-web \
    -p 23333:23333 \
    -v /path/to/data:/opt/mcsmanager/web/data \
    alisaqaq/mcsmanager-web:latest
```

Use Docker Compose

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

Use Docker CLI

```bash
docker run -it -d \
    --name mcsm-daemon \
    -p 24444:24444 \
    -v /path/to/data:/opt/mcsmanager/daemon/data \
    -v /var/run/docker.sock:/var/run/docker.sock \
    alisaqaq/mcsmanager-daemon:latest
```

Use Docker Compose

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

## Run MCSManager WebUI in Kubernetes

> Do not recommend using Daemon in Kubernetes

Use Config Map to store custom configuration, if you don't need to customize the configuration, you can skip this step.

Be aware that the configuration file will be copied into the volume in the InitContainer, so every time you restart the Pod, the configuration file will be overwritten.

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

Create a PersistentVolumeClaim to store data.

You could also use a HostPath volume, depending on your needs.

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

Create Deployment

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
      # If you do not have custom configurations, you can delete the intiContainers
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
        # If you do not have custom configurations, you can delete the volume
        - name: custom-config
          configMap:
            name: mcsm-web-config
            items:
              - key: config.json
                path: config.json
      restartPolicy: Always
```

Create Service, you can change the type according to your needs.

In the example below, we use ClusterIP and Ingress to access the service.

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

Create Ingress to expose the service.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mcsm-web-ingress
  namespace: mcsm
  annotations:
    # If you are using other Ingress Controller, you need to change the annotations
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  # If you are using other Ingress Controller, you need to change the ingressClassName
  ingressClassName: "traefik"
  tls:
    - hosts:
        - mcsm.example.com
      secretName: mcsm-web-cert # The secret in the same namespace that contains the TLS certificate
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
