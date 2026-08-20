# 第三方组件

部署会使用以下开源组件。版本与 `docker-compose.yml` 保持一致。

| 组件 | 版本 | 用途 | 许可证 | 官方来源 |
| --- | --- | --- | --- | --- |
| CVAT Community | v2.73.0 | 标注平台基础 | MIT | https://github.com/cvat-ai/cvat |
| PostgreSQL | 15 Alpine | 任务与账户数据库 | PostgreSQL License | https://www.postgresql.org/ |
| Redis | 7.2.11 Alpine | 内存队列与状态 | BSD-3-Clause | https://redis.io/ |
| Apache Kvrocks | 2.15.0 | 持久化任务队列 | Apache-2.0 | https://kvrocks.apache.org/ |
| Open Policy Agent | 1.12.2 | 权限规则 | Apache-2.0 | https://www.openpolicyagent.org/ |
| Traefik Proxy | 3.6 | 本地反向代理 | MIT | https://traefik.io/traefik/ |

本项目发布的 Server 和 UI 镜像来自公开源码仓库：

https://github.com/Christanding/cvat-yolo26-annotation-tool

Docker Desktop 由使用者从 Docker 官方网站单独安装，不随本项目分发；安装和使用时应遵守 Docker 的许可条款。
