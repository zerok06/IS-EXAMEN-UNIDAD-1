<?php
/*
 * Harness de entry-a (CVE-2026-109618): perfil de memoria bajo (8M) para que
 * el cuerpo OOM del PoC caiga donde el exploit espera.
 */
session_start();
header('Content-Type: text/plain');
echo 'sid=' . session_id() . ' mem=' . ini_get('memory_limit') . "\n";
