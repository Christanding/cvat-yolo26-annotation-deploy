Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepositoryRoot = $PSScriptRoot
$ComposePath = Join-Path $RepositoryRoot "docker-compose.yml"
$EnvironmentPath = Join-Path $RepositoryRoot ".env"

if (-not (Test-Path $EnvironmentPath)) {
    throw "尚未完成首次启动，请先运行 Start.ps1。"
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "没有找到 Docker。"
}

& docker compose --project-directory $RepositoryRoot --env-file $EnvironmentPath -f $ComposePath stop
if ($LASTEXITCODE -ne 0) {
    throw "停止服务失败。"
}

Write-Host "服务已停止，任务、标注和原始文件均已保留。"
