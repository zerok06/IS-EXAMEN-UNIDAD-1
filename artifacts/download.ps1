param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$dirs = @('vulnerable', 'fixed', 'pocs', 'os', 'ftp')
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path (Join-Path $root $d) | Out-Null
}

$items = @(
    # --- Versiones vulnerables ---
    [pscustomobject]@{ Dir = 'vulnerable'; Name = 'wordpress-7.0.1.zip'; Url = 'https://wordpress.org/wordpress-7.0.1.zip' },
    [pscustomobject]@{ Dir = 'vulnerable'; Name = 'php-8.4.26.tar.gz'; Url = 'https://www.php.net/distributions/php-8.4.26.tar.gz' },
    [pscustomobject]@{ Dir = 'vulnerable'; Name = 'httpd-2.4.49.tar.gz'; Url = 'https://archive.apache.org/dist/httpd/httpd-2.4.49.tar.gz' },
    [pscustomobject]@{ Dir = 'vulnerable'; Name = 'redis-6.2.6.tar.gz'; Url = 'https://download.redis.io/releases/redis-6.2.6.tar.gz' },
    [pscustomobject]@{ Dir = 'vulnerable'; Name = 'samba-4.5.9.tar.gz'; Url = 'https://download.samba.org/pub/samba/stable/samba-4.5.9.tar.gz' },
    [pscustomobject]@{ Dir = 'vulnerable'; Name = 'vsftpd-2.3.4.tar.gz'; Url = 'https://security.appspot.com/downloads/vsftpd-2.3.4.tar.gz' },
    [pscustomobject]@{ Dir = 'vulnerable'; Name = 'moodle-5.0.11.tar.gz'; Url = 'https://github.com/moodle/moodle/archive/refs/tags/v5.0.11.tar.gz' },
    [pscustomobject]@{ Dir = 'vulnerable'; Name = 'tightvnc-2.8.90-gpl-setup-64bit.msi'; Url = 'https://www.tightvnc.com/download/2.8.90/tightvnc-2.8.90-gpl-setup-64bit.msi' },

    # --- Versiones corregidas ---
    [pscustomobject]@{ Dir = 'fixed'; Name = 'wordpress-7.0.2.zip'; Url = 'https://wordpress.org/wordpress-7.0.2.zip' },
    [pscustomobject]@{ Dir = 'fixed'; Name = 'php-8.4.27.tar.gz'; Url = 'https://www.php.net/distributions/php-8.4.27.tar.gz' },
    [pscustomobject]@{ Dir = 'fixed'; Name = 'httpd-2.4.51.tar.gz'; Url = 'https://archive.apache.org/dist/httpd/httpd-2.4.51.tar.gz' },
    [pscustomobject]@{ Dir = 'fixed'; Name = 'redis-6.2.7.tar.gz'; Url = 'https://download.redis.io/releases/redis-6.2.7.tar.gz' },
    [pscustomobject]@{ Dir = 'fixed'; Name = 'samba-4.5.10.tar.gz'; Url = 'https://download.samba.org/pub/samba/stable/samba-4.5.10.tar.gz' },
    [pscustomobject]@{ Dir = 'fixed'; Name = 'vsftpd-3.0.5.tar.gz'; Url = 'https://security.appspot.com/downloads/vsftpd-3.0.5.tar.gz' },

    # --- PoCs y herramientas ---
    [pscustomobject]@{ Dir = 'pocs'; Name = 'wp2shell-vulhub-poc.py'; Url = 'https://raw.githubusercontent.com/vulhub/vulhub/master/wordpress/CVE-2026-63030/poc.py' },
    [pscustomobject]@{ Dir = 'pocs'; Name = 'wp2shell-poc-main.zip'; Url = 'https://github.com/DeadExpl0it/wp2shell-poc/archive/refs/heads/main.zip' },
    [pscustomobject]@{ Dir = 'pocs'; Name = 'php2shell-poc-main.zip'; Url = 'https://github.com/eness/php2shell-cve-2026-109618-cve-2026-109619-poc/archive/refs/heads/main.zip' },
    [pscustomobject]@{ Dir = 'pocs'; Name = 'ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz'; Url = 'https://github.com/nicocha30/ligolo-ng/releases/download/v0.9.2/ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz' },
    [pscustomobject]@{ Dir = 'pocs'; Name = 'ligolo-ng_agent_0.9.2_linux_amd64.tar.gz'; Url = 'https://github.com/nicocha30/ligolo-ng/releases/download/v0.9.2/ligolo-ng_agent_0.9.2_linux_amd64.tar.gz' }
)

foreach ($i in $items) {
    $out = Join-Path $root (Join-Path $i.Dir $i.Name)
    if ((Test-Path $out) -and -not $Force -and ((Get-Item $out).Length -gt 0)) {
        Write-Host ("SKIP  {0}" -f $i.Name)
        continue
    }

    Write-Host ("GET   {0}" -f $i.Name)
    & curl.exe -L --fail --retry 3 --retry-delay 2 --silent --show-error -o $out $i.Url
    if ($LASTEXITCODE -ne 0) {
        throw ("Falló la descarga: {0}" -f $i.Url)
    }

    $size = (Get-Item $out).Length
    Write-Host ("OK    {0} ({1:N2} MB)" -f $i.Name, ($size / 1MB))
}

$hashFile = Join-Path $root 'checksums.sha256'
$files = Get-ChildItem -Path (Join-Path $root 'vulnerable'), (Join-Path $root 'fixed'), (Join-Path $root 'pocs') -Recurse -File | Sort-Object FullName
$lines = foreach ($f in $files) {
    try {
        $h = (Get-FileHash -Algorithm SHA256 $f.FullName -ErrorAction Stop).Hash.ToLower()
        $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
        "{0}  {1}" -f $h, $rel
    } catch {
        Write-Warning ("No se pudo hashear {0}: {1}" -f $f.Name, $_.Exception.Message)
    }
}
$lines | Set-Content -Encoding ascii $hashFile

Write-Host ""
Write-Host ("Checksums: {0}" -f $hashFile)
Write-Host ("Archivos:  {0}" -f $files.Count)
