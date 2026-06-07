# 百度搜索资源平台 - URL推送脚本
# 用法: .\push-to-baidu.ps1
#      .\push-to-baidu.ps1 "https://fc-simulator.com/some-page"
# 每次 git push 部署后运行此脚本通知百度爬虫

param(
  [string[]]$Urls = @("https://fc-simulator.com/")
)

$Site = "https://fc-simulator.com"
$Token = "McuOYtzVkKLyegtO"
$ApiUrl = "http://data.zz.baidu.com/urls?site=$Site&token=$Token"

Write-Host "========== 百度推送 ==========" -ForegroundColor Cyan
Write-Host "推送 URL 数量: $($Urls.Count)" -ForegroundColor Yellow
foreach ($url in $Urls) {
  Write-Host "  → $url" -ForegroundColor Gray
}

try {
  $body = $Urls -join "`n"
  $response = Invoke-WebRequest -Uri $ApiUrl -Method Post -Body $body -ContentType "text/plain" -UseBasicParsing
  $result = $response.Content | ConvertFrom-Json

  Write-Host ""
  Write-Host "推送结果:" -ForegroundColor Green
  Write-Host "  成功: $($result.success) 条" -ForegroundColor Green
  Write-Host "  剩余配额: $($result.remain) 条/天" -ForegroundColor Cyan

  if ($result.not_same_site -and $result.not_same_site.Count -gt 0) {
    Write-Host "  非本站URL (未处理): $($result.not_same_site -join ', ')" -ForegroundColor Magenta
  }
  if ($result.not_valid -and $result.not_valid.Count -gt 0) {
    Write-Host "  不合法URL (未处理): $($result.not_valid -join ', ')" -ForegroundColor Red
  }
} catch {
  Write-Host "推送失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "==============================" -ForegroundColor Cyan
