# MCSManager Docker Image

MCSManager 的 Docker 镜像

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
