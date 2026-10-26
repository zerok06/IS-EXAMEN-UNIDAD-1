param(
    [string]$Role = 'm5',
    [string]$Host = '10.10.10.20',
    [int]$Port = 2121,
    [string]$User = 'lab',
    [string]$Pass = 'lab123',
    [string]$Dest = "$env:TEMP\artifacts"
)

$ErrorActionPreference = 'Stop'

function Fetch([string]$Rel) {
    $out = Join-Path $Dest $Rel.Replace('/', '\')
    $dir = Split-Path -Parent $out
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-Host "GET  $Rel"
    & curl.exe -sS --fail --retry 2 -u "$User`:$Pass" -o $out "ftp://$Host`:$Port/$Rel"
    if ($LASTEXITCODE -ne 0) { throw "Falló: $Rel" }
    $size = [math]::Round((Get-Item $out).Length / 1MB, 2)
    Write-Host "OK   $Rel ($size MB)"
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

switch ($Role) {
    'm5' {
        Fetch 'vulnerable/tightvnc-2.8.90-gpl-setup-64bit.msi'
        $expected = '9693cb4cdc2e7e482e8e3f5890415b57ef87de3369fa5c337db516218a1170ce'
        $actual = (Get-FileHash -Algorithm SHA256 (Join-Path $Dest 'vulnerable\tightvnc-2.8.90-gpl-setup-64bit.msi')).Hash.ToLower()
        if ($actual -eq $expected) {
            Write-Host "PASS  SHA256 TightVNC"
        } else {
            Write-Warning "SHA256 no coincide. Esperado: $expected / Actual: $actual"
        }
    }
    'm4' {
        Write-Host "M4 no requiere artefactos de software: usa DNS, SMBv1, Spooler y legacy."
    }
    default {
        Write-Host "Roles soportados en Windows: m5, m4."
        Write-Host "Para M1–M3/M6 usar ftp/fetch-artifacts.sh en Linux."
    }
}

Write-Host ""
Write-Host "Destino: $Dest"
