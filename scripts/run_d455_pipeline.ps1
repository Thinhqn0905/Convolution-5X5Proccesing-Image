$ErrorActionPreference = 'Stop'

$workspace = Split-Path -Parent $PSScriptRoot
Set-Location $workspace

$pythonExe = "C:/Users/ADMIN/AppData/Local/Programs/Python/Python310/python.exe"
$kernels = @('gaussian5', 'sharpen5', 'laplacian5')

foreach ($k in $kernels) {
    Write-Host "=== D455 stream kernel: $k ==="
    & $pythonExe .\python\d455_stream_process.py --width 640 --height 480 --fps 30 --kernel $k --duration_sec 8 --max_frames 240 --save_every 20 --out_dir ".\captures\d455\$k"
    if ($LASTEXITCODE -ne 0) {
        throw "D455 stream failed for kernel $k"
    }
}

Write-Host "=== Running RTL regression test cases ==="
.\scripts\run_regression.ps1
if ($LASTEXITCODE -ne 0) {
    throw "Regression failed"
}

Write-Host "Pipeline complete. Check captures/d455 and sim outputs."
