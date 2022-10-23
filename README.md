# MCSManager Docker Image

MCSManager 的 Docker 镜像

## Tag

- `latest`：最新版本
- `9.6.0-amd64`：指定版本和架构
- `9.6.0`：指定版本，将根据系统架构自动选择对应的镜像
- `9.6`：指定主版本和次版本，将指向最新的 Patch 版本
- `9`：指定主版本，将指向当前大版本号下的最新版本

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
