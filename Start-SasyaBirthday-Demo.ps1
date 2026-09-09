$ErrorActionPreference = "Stop"

$VM_HOST = "192.168.0.10"
$VM_USER = "ocva"
$REMOTE_PORT = 8000
$TEMP_DIR = Join-Path $env:TEMP "sasya-birthday-demo"
$STDOUT_FILE = Join-Path $TEMP_DIR "stdout.log"
$STDERR_FILE = Join-Path $TEMP_DIR "stderr.log"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "       SASYA BIRTHDAY - DEMO MODE" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Checking VM..." -ForegroundColor Yellow
if (-not (Test-Connection -ComputerName $VM_HOST -Count 1 -Quiet)) {
    throw "VM $VM_HOST tidak dapat dijangkau. Pastikan VM menyala."
}
Write-Host "VM tersedia: $VM_HOST" -ForegroundColor Green

Write-Host ""
Write-Host "[2/3] Checking website on port $REMOTE_PORT..." -ForegroundColor Yellow
$ready = Test-NetConnection -ComputerName $VM_HOST -Port $REMOTE_PORT -InformationLevel Quiet -WarningAction SilentlyContinue
if (-not $ready) {
    throw "Website belum listen di $VM_HOST`:$REMOTE_PORT. Jalankan server.py di VM."
}
Write-Host "Birthday site tersedia di port $REMOTE_PORT." -ForegroundColor Green

if (Test-Path $TEMP_DIR) {
    Remove-Item $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $TEMP_DIR | Out-Null
New-Item -ItemType File -Path $STDOUT_FILE | Out-Null
New-Item -ItemType File -Path $STDERR_FILE | Out-Null

Write-Host ""
Write-Host "[3/3] Starting Cloudflare Quick Tunnel..." -ForegroundColor Yellow

$sshArgs = @(
    "-T",
    "$VM_USER@$VM_HOST",
    "cloudflared tunnel --url http://127.0.0.1:$REMOTE_PORT"
)

$cloudflared = Start-Process `
    -FilePath "ssh.exe" `
    -ArgumentList $sshArgs `
    -RedirectStandardOutput $STDOUT_FILE `
    -RedirectStandardError $STDERR_FILE `
    -PassThru `
    -WindowStyle Hidden

$demoUrl = $null
$lastErrorLength = 0

try {
    while (-not $cloudflared.HasExited) {
        Start-Sleep -Milliseconds 500

        if (Test-Path $STDERR_FILE) {
            $err = Get-Content -Path $STDERR_FILE -Raw -ErrorAction SilentlyContinue
            if ($err.Length -gt $lastErrorLength) {
                $newErr = $err.Substring($lastErrorLength)
                $lastErrorLength = $err.Length

                foreach ($line in ($newErr -split "`r?`n")) {
                    if ($line -match 'https://[a-zA-Z0-9-]+\.trycloudflare\.com') {
                        $demoUrl = $matches[0]
                        break
                    }
                }
            }
        }

        if ($demoUrl) {
            break
        }
    }

    if (-not $demoUrl) {
        throw "Cloudflare Tunnel berhenti sebelum URL ditemukan."
    }

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "                PUBLIC URL" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host $demoUrl -ForegroundColor Yellow
    Write-Host ""
    Write-Host "URL di atas bisa dikirim ke Sasya." -ForegroundColor Cyan
    Write-Host "Jangan tutup window ini selama website dipakai." -ForegroundColor DarkGray
    Write-Host "Tekan Ctrl+C untuk menghentikan demo." -ForegroundColor DarkGray
    Write-Host ""

    while (-not $cloudflared.HasExited) {
        Start-Sleep -Seconds 1
    }
}
finally {
    if ($cloudflared -and -not $cloudflared.HasExited) {
        Stop-Process -Id $cloudflared.Id -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $TEMP_DIR) {
        Remove-Item $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    }
}
