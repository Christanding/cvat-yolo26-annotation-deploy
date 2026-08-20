param(
    [string]$WorkspaceRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AppVersion = "0.1.0"
$RepositoryRoot = $PSScriptRoot
$ComposePath = Join-Path $RepositoryRoot "docker-compose.yml"
$EnvironmentPath = Join-Path $RepositoryRoot ".env"
$DeploymentStatePath = Join-Path $RepositoryRoot ".deploy-state.json"
$Utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "没有找到 Docker。请先安装并启动 Docker Desktop。"
}

& docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Docker Desktop 尚未启动，或当前无法连接 Docker。"
}

& docker compose version *> $null
if ($LASTEXITCODE -ne 0) {
    throw "当前 Docker Desktop 不包含 Docker Compose，请先更新 Docker Desktop。"
}

$PreviousState = $null
if (Test-Path $DeploymentStatePath) {
    try {
        $PreviousState = Get-Content $DeploymentStatePath -Raw | ConvertFrom-Json
    }
    catch {
        throw "部署状态文件损坏：$DeploymentStatePath"
    }
}

if ([string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    if ($null -ne $PreviousState -and -not [string]::IsNullOrWhiteSpace([string]$PreviousState.workspace)) {
        $WorkspaceRoot = [string]$PreviousState.workspace
    }
    else {
        $WorkspaceRoot = Join-Path $env:USERPROFILE "YOLO-Workspace"
    }
}

$WorkspaceRoot = [System.IO.Path]::GetFullPath($WorkspaceRoot)
if ($WorkspaceRoot.Contains("'") -or $WorkspaceRoot.Contains("`n") -or $WorkspaceRoot.Contains("`r")) {
    throw "工作目录不能包含单引号或换行符。"
}

$WorkspaceChanged = $null -eq $PreviousState -or -not [System.StringComparer]::OrdinalIgnoreCase.Equals(
    [string]$PreviousState.workspace,
    $WorkspaceRoot
)
$PreviousVersion = if ($null -ne $PreviousState -and $null -ne $PreviousState.version) {
    [string]$PreviousState.version
}
else {
    ""
}
$AccountName = if (-not $WorkspaceChanged -and $null -ne $PreviousState.account) {
    [string]$PreviousState.account
}
else {
    ""
}

$StateRoot = Join-Path $WorkspaceRoot ".cvat-local"
$RequiredDirectories = @(
    $WorkspaceRoot,
    (Join-Path $StateRoot "data"),
    (Join-Path $StateRoot "keys"),
    (Join-Path $StateRoot "logs"),
    (Join-Path $StateRoot "postgres"),
    (Join-Path $StateRoot "redis"),
    (Join-Path $StateRoot "kvrocks")
)
foreach ($Directory in $RequiredDirectories) {
    [System.IO.Directory]::CreateDirectory($Directory) | Out-Null
}

$WorkspaceForCompose = $WorkspaceRoot.Replace("\", "/")
$StateRootForCompose = $StateRoot.Replace("\", "/")
$EnvironmentLines = @(
    "APP_VERSION=$AppVersion",
    "CVAT_HOST=localhost",
    "CVAT_WORKSPACE_ROOT='$WorkspaceForCompose'",
    "CVAT_STATE_DIR='$StateRootForCompose'"
)
[System.IO.File]::WriteAllLines($EnvironmentPath, $EnvironmentLines, $Utf8WithoutBom)

function Invoke-Compose {
    param([string[]]$ComposeArguments)

    & docker compose --project-directory $RepositoryRoot --env-file $EnvironmentPath -f $ComposePath @ComposeArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose 执行失败。"
    }
}

if ($WorkspaceChanged -or $PreviousVersion -ne $AppVersion) {
    Write-Host "正在下载运行镜像……"
    Invoke-Compose @("pull")
}

Write-Host "正在启动标注工具……"
Invoke-Compose @("up", "-d")

$ApplicationUrl = "http://localhost:8080"
$HealthUrl = "$ApplicationUrl/api/server/health/"
$Deadline = [System.DateTime]::UtcNow.AddMinutes(3)
$Ready = $false
while ([System.DateTime]::UtcNow -lt $Deadline) {
    try {
        $Response = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 5
        if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 300) {
            $Ready = $true
            break
        }
    }
    catch {
        Start-Sleep -Seconds 2
    }
}

if (-not $Ready) {
    Invoke-Compose @("ps")
    throw "服务没有在预期时间内就绪，请查看上面的容器状态。"
}

if ([string]::IsNullOrWhiteSpace($AccountName)) {
    $AccountName = Read-Host "首次使用，请输入账户名（直接回车使用 annotator）"
    if ([string]::IsNullOrWhiteSpace($AccountName)) {
        $AccountName = "annotator"
    }
    else {
        $AccountName = $AccountName.Trim()
    }

    while ($true) {
        $Password = Read-Host "请输入密码（至少 8 个字符）" -AsSecureString
        $Confirmation = Read-Host "请再次输入密码" -AsSecureString
        $PasswordText = [System.Net.NetworkCredential]::new("", $Password).Password
        $ConfirmationText = [System.Net.NetworkCredential]::new("", $Confirmation).Password

        if ($PasswordText.Length -lt 8) {
            Write-Host "密码至少需要 8 个字符。"
            continue
        }
        if ($PasswordText -cne $ConfirmationText) {
            Write-Host "两次输入的密码不一致。"
            continue
        }
        break
    }

    try {
        $PasswordText | & docker exec -i cvat_server python manage.py create_local_account --username $AccountName
        if ($LASTEXITCODE -ne 0) {
            throw "本地账户创建失败。"
        }
    }
    finally {
        $PasswordText = $null
        $ConfirmationText = $null
    }
}

$DeploymentState = @{
    workspace = $WorkspaceRoot
    account = $AccountName
    version = $AppVersion
} | ConvertTo-Json
[System.IO.File]::WriteAllText(
    $DeploymentStatePath,
    $DeploymentState + [System.Environment]::NewLine,
    $Utf8WithoutBom
)

$EdgeCandidates = @()
$ProgramFilesX86 = [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
if (-not [string]::IsNullOrWhiteSpace($ProgramFilesX86)) {
    $EdgeCandidates += Join-Path $ProgramFilesX86 "Microsoft\Edge\Application\msedge.exe"
}
if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
    $EdgeCandidates += Join-Path $env:ProgramFiles "Microsoft\Edge\Application\msedge.exe"
}
$EdgePath = $EdgeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($null -ne $EdgePath) {
    Start-Process -FilePath $EdgePath -ArgumentList $ApplicationUrl
}
else {
    Start-Process $ApplicationUrl
}

Write-Host "标注工具已启动：$ApplicationUrl"
Write-Host "工作目录：$WorkspaceRoot"
