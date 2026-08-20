# YOLO26 图片标注工具部署

这是面向普通使用者的 Windows 部署仓库，只包含启动所需的文件。完整源码和开发记录保存在 [cvat-yolo26-annotation-tool](https://github.com/Christanding/cvat-yolo26-annotation-tool)。

## 首次安装

电脑需要安装 [Docker Desktop](https://www.docker.com/products/docker-desktop/) 和 [Git for Windows](https://git-scm.com/download/win)。安装 Docker Desktop 时使用默认的 WSL 2 方式即可。

启动 Docker Desktop，然后在 PowerShell 中运行：

```powershell
git clone https://github.com/Christanding/cvat-yolo26-annotation-deploy.git
cd cvat-yolo26-annotation-deploy
powershell -ExecutionPolicy Bypass -File .\Start.ps1
```

第一次运行会自动下载镜像、创建工作目录并启动服务。按提示设置一次本地账户和密码后，Edge 会自动打开 <http://localhost:8080>。

默认工作目录是：

```text
C:\Users\你的用户名\YOLO-Workspace
```

如果希望放在其他位置，首次启动时指定目录即可：

```powershell
powershell -ExecutionPolicy Bypass -File .\Start.ps1 -WorkspaceRoot D:\YOLO-Workspace
```

## 日常使用

启动 Docker Desktop，在部署目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\Start.ps1
```

需要停止时运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\Stop.ps1
```

停止服务不会删除图片、视频、任务或标注。完成首次部署后，日常标注可以断网使用。

## 更新

先确认没有正在执行的抽帧、导入或导出任务，再运行：

```powershell
git pull --ff-only
powershell -ExecutionPolicy Bypass -File .\Start.ps1
```

启动脚本会在版本变化时下载新镜像，已有工作目录和标注不会被清理。

## 数据放在哪里

原始图片和视频直接放入工作目录。任务、账户和标注保存在工作目录内的 `.cvat-local`，不要手动修改这个目录。

任务开始后，不要移动、重命名或删除任务引用的图片、视频和文件夹。迁移电脑前应先停止服务，再完整复制工作目录。

## 项目来源

本工具基于 CVAT Community `v2.73.0` 开发，并保留 CVAT 的 MIT License、版权和上游来源。所用容器及许可证见 [THIRD_PARTY.md](THIRD_PARTY.md)。

目前正式支持 Windows 10/11 x64、Docker Desktop、Microsoft Edge 和 Google Chrome。Windows 实机最终验收完成前，仍建议先在一台非生产电脑上试用。
