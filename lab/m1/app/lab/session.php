<?php
/*
 * Harness del laboratorio (no es una aplicación real).
 * Único propósito: exponer una sesión PHP nativa, pre-auth, para PHP2Shell.
 * NO reescribe el id: deja que PHP emita su propio PHPSESSID (canal del leak).
 *
 * ?info=1 devuelve la configuración relevante (lo usa chain/00-preflight.sh).
 */
session_start();
$_SESSION['n'] = ($_SESSION['n'] ?? 0) + 1;
header('Content-Type: text/plain');

if (isset($_GET['info'])) {
    foreach ([
        'session.save_path',
        'session.upload_progress.enabled',
        'session.upload_progress.cleanup',
        'session.upload_progress.name',
        'memory_limit',
        'post_max_size',
        'open_basedir',
    ] as $k) {
        echo $k . '=' . ini_get($k) . "\n";
    }
    exit;
}

echo 'sid=' . session_id() . ' n=' . $_SESSION['n'] . "\n";
