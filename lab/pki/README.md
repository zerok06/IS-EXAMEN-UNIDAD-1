# PKI del laboratorio · `uni.lab`

> CA propia **`Lab Root CA`** (RSA 4096, 10 años) + certificado de servidor para
> **M1** con el SAN que cubre los tres nombres de la aplicación.
> Todo se genera en local con `openssl`: **nada se descarga de Internet**.

```
pki/
├── gen-ca.sh      # CA raíz (idempotente)
├── issue-m1.sh    # certificado de app.uni.lab firmado por la CA
├── out/           # material generado (no se versiona)
│   ├── ca.key        0600  clave de la CA (SOLO laboratorio)
│   ├── ca.crt        0644  CA raíz → se instala en M5 y M6
│   ├── app.key       0600  clave privada del servidor (M1)
│   ├── app.crt       0644  certificado del servidor
│   └── app-chain.crt 0644  app.crt + ca.crt (cadena para nginx)
└── README.md
```

## 1. Generar

En **M6**, en la raíz del repo (`/srv/lab` después de `lab/m6/install.sh`):

```bash
cd /srv/lab                 # o el checkout del repo
bash lab/pki/gen-ca.sh      # CA: CN=Lab Root CA, RSA 4096, 3650 días
bash lab/pki/issue-m1.sh    # leaf: CN=app.uni.lab, RSA 2048, 825 días
ls -l lab/pki/out
```

Salida esperada de `issue-m1.sh`:

```
subject=CN = app.uni.lab, OU = Laboratorio, O = uni.lab, C = EC
issuer=CN = Lab Root CA, OU = Laboratorio, O = uni.lab, C = EC
X509v3 Subject Alternative Name:
    DNS:app.uni.lab, DNS:wp.uni.lab, DNS:moodle.uni.lab, IP Address:10.10.10.11
```

Ambos scripts son **idempotentes**: si el material existente sigue siendo válido
(firma, pareja clave/cert, SAN completo, más de 30 días de vida) no se toca.
Para rotar: `bash lab/pki/gen-ca.sh --force && bash lab/pki/issue-m1.sh --force`
(la CA nueva invalida todos los certificados emitidos antes).

> Generar **antes** de `lab/m6/install.sh` si se quiere que `lab.tar.gz` lleve
> `pki/out` dentro. Si se genera después, hay que reempaquetar:
> `sudo tar czf /srv/lab.tar.gz -C /srv/lab .`

## 2. Instalar el certificado en M1 (nginx)

El material viaja ya en `/opt/lab` (o `/opt/lab/lab`, según el layout del
paquete). Desde M6 se copia a M1 y se instala en `/etc/ssl/lab`:

```bash
# en M6
scp lab/pki/out/app-chain.crt lab/pki/out/app.key ubuntu@10.10.10.11:/tmp/

# en M1
sudo install -d -m 0755 /etc/ssl/lab
sudo install -m 0644 /tmp/app-chain.crt /etc/ssl/lab/app-chain.crt
sudo install -m 0600 /tmp/app.key       /etc/ssl/lab/app.key
sudo rm -f /tmp/app-chain.crt /tmp/app.key
```

nginx termina TLS en 443 y pasa a Apache/mod_php en 8080 (ver `lab/README.md §2`):

```nginx
server {
    listen 443 ssl http2;          # nginx 1.18: "http2" va en el listen
    server_name app.uni.lab wp.uni.lab moodle.uni.lab;

    ssl_certificate     /etc/ssl/lab/app-chain.crt;
    ssl_certificate_key /etc/ssl/lab/app.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_session_cache   shared:SSL:10m;

    client_max_body_size 64m;      # el PoC de PHP2Shell manda cuerpos grandes

    location / {
        proxy_pass         http://127.0.0.1:8080;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto https;
        proxy_read_timeout 120s;   # los requests del PoC tardan
    }
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx
```

Verificación desde M6 (sin `-k`, validando contra la CA):

```bash
openssl s_client -connect 10.10.10.11:443 -servername wp.uni.lab \
  -CAfile lab/pki/out/ca.crt </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -ext subjectAltName

curl --cacert lab/pki/out/ca.crt -o /dev/null -w '%{http_code}\n' https://wp.uni.lab/
```

`wp.uni.lab` y `moodle.uni.lab` deben resolver (DNS de M4 o línea en
`/etc/hosts`, que `lab/m6/install.sh` ya escribe).

## 3. Instalar la CA en M6 (Kali)

Para que `curl`/`wget`/navegador acepten el certificado sin `-k`:

```bash
sudo install -m 0644 /srv/lab/lab/pki/out/ca.crt \
  /usr/local/share/ca-certificates/uni-lab-root-ca.crt
sudo update-ca-certificates
curl -o /dev/null -w '%{http_code}\n' https://wp.uni.lab/    # sin -k
```

## 4. Instalar la CA en M5 (Windows 10)

Copiar `ca.crt` a la VM (SMB desde M6, o el propio `lab.zip`) y añadirla al
almacén **Equipo local → Entidades de certificación raíz de confianza**:

```powershell
# consola elevada
Import-Certificate -FilePath C:\lab\pki\out\ca.crt `
  -CertStoreLocation Cert:\LocalMachine\Root

# alternativa equivalente
certutil -addstore -f Root C:\lab\pki\out\ca.crt
```

Si la demo no usa el DNS de M4, añadir los nombres al archivo `hosts`:

```powershell
Add-Content C:\Windows\System32\drivers\etc\hosts `
  '10.10.10.11 app.uni.lab wp.uni.lab moodle.uni.lab'
```

Verificar (PowerShell 5.1 valida contra el almacén de la máquina):

```powershell
(Invoke-WebRequest https://wp.uni.lab/ -UseBasicParsing).StatusCode
```

En Firefox (si se usa para la demo) hay que importar la CA aparte, en
*Preferencias → Privacidad y seguridad → Certificados → Autoridades*.

## 5. Notas y límites

- El certificado cubre **solo M1** (`app/wp/moodle`). M2–M5 no tienen TLS en el
  escenario; no se emiten certificados para ellos.
- `IP:10.10.10.11` está en el SAN para las pruebas por IP, pero nginx elige el
  vhost por `Host`, así que la demo debe usar los nombres (`wp.uni.lab`).
- `ca.key` es material sensible **del laboratorio**: no se versiona, no sale de
  la red `10.10.10.0/24` y se rota al cerrar la práctica.
- Compatibilidad: el SAN con `-addext` requiere OpenSSL ≥ 1.1.1 (Ubuntu 22.04 y
  Kali lo cumplen). En clientes muy antiguos, 825 días es el máximo práctico
  aceptado por algunos stacks; por eso no se emiten a 10 años.
- Los scripts de la cadena usan `curl -k` para no depender de la CA instalada;
  la validación con CA es la prueba "correcta" y se muestra en la §2.
