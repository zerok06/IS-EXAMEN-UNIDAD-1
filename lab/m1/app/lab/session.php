<?php
/*
 * Harness del laboratorio (no es una aplicación real).
 * Único propósito: exponer una sesión PHP nativa, pre-auth, para PHP2Shell.
 * NO reescribe el id: deja que PHP emita su propio PHPSESSID (canal del leak).
 */
session_start();
$_SESSION['n'] = ($_SESSION['n'] ?? 0) + 1;
header('Content-Type: text/plain');
echo 'sid=' . session_id() . ' n=' . $_SESSION['n'] . "\n";
