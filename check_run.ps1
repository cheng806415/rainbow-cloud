Start-Sleep -Seconds 360
Set-Location d:\Develop\weihu\client

$result1 = gh run view 26318181189 --json status,conclusion -q '.status + " " + .conclusion'
Write-Host "=== 状态和结论 ==="
Write-Host $result1

$result2 = gh run view 26318181189 --json jobs -q '.jobs[] | .name + " " + .conclusion'
Write-Host "`n=== Jobs 状态 ==="
Write-Host $result2

if ($result2 -match "failure") {
    Write-Host "`n=== 失败日志 (前100行) ==="
    $logOutput = gh run view 26318181189 --log-failed 2>&1
    $logOutput | Select-Object -First 100
}
