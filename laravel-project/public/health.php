<?php
/**
 * Health Check Endpoint for Docker
 * 
 * This file provides a simple health check endpoint for Docker health monitoring.
 * It returns a 200 OK response with basic system information.
 */

header('Content-Type: application/json');

// Simple check that PHP is functioning
$status = 'healthy';
$memoryUsage = round(memory_get_usage() / 1024 / 1024, 2);
$maxMemory = ini_get('memory_limit');
$loadAvg = function_exists('sys_getloadavg') ? sys_getloadavg() : [0, 0, 0];
$timestamp = date('Y-m-d H:i:s');

echo json_encode([
    'status' => $status,
    'timestamp' => $timestamp,
    'memory_usage' => $memoryUsage . 'MB',
    'memory_limit' => $maxMemory,
    'load_average' => $loadAvg,
    'server' => 'maryDock - FrankenPHP'
], JSON_PRETTY_PRINT);

exit(0);