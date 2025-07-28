#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
try {
    # 取得本机第一张非回环 IPv4 地址
    # 筛选条件：IPv4, 状态为“首选”, 排除环回地址(127.0.0.1)和APIPA地址(169.254.*)
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred`
        -InterfaceAlias (Get-NetConnectionProfile | Select-Object -First 1 -ExpandProperty InterfaceAlias)`
        | Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike "169.254.*" }`
        | Select-Object -First 1).IPAddress

    if (-not $localIP -or [string]::IsNullOrWhiteSpace($localIp)) {
        throw "无法获取本机 IPv4 地址，请检查网络配置！" -ForegroundColor Red
    }
    Write-Host "本机 IPv4 地址为：$localIP" -ForegroundColor Green
} catch {
    Write-Host "错误：无法自动获取本机 IPv4 地址。错误信息: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "请按 Enter 键退出"
    exit
}

# 匹配 IPv4 的正则
$ipv4Regex = '\b(?:\d{1,3}\.){3}\d{1,3}\b'
# 正则表达式，用于仅匹配 "cas.server=" 或 "cas.client=" 后面的IP地址本身
# 它使用了零宽断言 (lookaround) 来确保只替换IP，不影响端口和路径
# (?<=...) 是正向后行断言 (Positive Lookbehind): 匹配必须在 "cas.server=" 或 "cas.client=" 之后
# (?=...) 是正向前瞻断言 (Positive Lookahead): 匹配后面必须是冒号(:)、斜杠(/)、空白字符(\s)或行尾($)
$ipRegex = '(?<=cas\.(?:server|client)\s*=\s*http://)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?=\s*[:/]|$)'

# 遍历文件
Get-ChildItem -Path . -Recurse -File -Include '*.xml','*.properties' | ForEach-Object {
    $file = $_
    # 先尝试按 UTF-8 无 BOM 读取，失败则按字节读取
    $content = $null
    try {
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    } catch {
        # 如果文件不是文本或带 BOM，则按字节读取再转为文本
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $bom = $bytes[0..2]
        if ($bom[0] -eq 0xEF -and $bom[1] -eq 0xBB -and $bom[2] -eq 0xBF) {
            $content = [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
        } else {
            # 其他情况统一按 UTF-8 无 BOM 处理（如有特殊编码需自行调整）
            $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        }
    }

    # 替换逻辑  -replace 默认不区分大小写 如果需要区分大小写, 请使用 -creplace
    $newContent = $content -replace `
        "(?<=cas\.(?:server|client)\s*=\s*.*)$ipv4Regex", $localIP `
        -replace '(?i)\bOracle\b', 'postgresql'

    # 只有当内容真正发生变化时才写回，避免无意义 IO
    if ($newContent -ne $content) {
        # 先写到一个临时文件，再覆盖原文件，保证原子性
        $temp = "$($file.FullName).tmp"
        [System.IO.File]::WriteAllText($temp, $newContent, [System.Text.Encoding]::UTF8)
        Move-Item -LiteralPath $temp -Destination $file.FullName -Force
        # try {
            # 使用 Out-File 是更稳妥的写入方式，可以指定编码
            # Out-File -FilePath $file.FullName -InputObject $newContent -Encoding UTF8
            # Write-Host "  -> 已更新文件: $($file.Name)" -ForegroundColor Yellow
        # } catch {
            # Write-Host "  -> 错误：写入文件失败: $($file.FullName)。错误信息: $($_.Exception.Message)" -ForegroundColor Red
        # }
        Write-Host "已更新：$($file.FullName)"
    }
}

Write-Host "全部处理完成！" -ForegroundColor Cyan