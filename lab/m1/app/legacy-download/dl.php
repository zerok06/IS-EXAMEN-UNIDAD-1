<?php
/*
 * dl.php — descarga de plantillas del tema heredado.
 *
 * Deuda técnica intencional del laboratorio: concatena la ruta sin normalizar
 * ni restringir el directorio base. Sirve para encadenar PHP2Shell (sesión)
 * con un sink de inclusión local.
 */
$tpl  = $_GET['file'] ?? 'default.php';
$base = __DIR__ . '/templates/';
$path = $base . $tpl;

if (!is_file($path)) {
    http_response_code(404);
    header('Content-Type: text/plain');
    echo "plantilla no encontrada\n";
    exit;
}

header('Content-Type: text/html; charset=utf-8');
include $path;
