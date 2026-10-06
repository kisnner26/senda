<?php

use Illuminate\Support\Facades\Artisan;

Artisan::command('senda:token', function () {
    $token = bin2hex(random_bytes(32));
    $hash = password_hash($token, PASSWORD_DEFAULT);
    $path = base_path('.env');
    $env = file_get_contents($path);
    $line = 'SENDA_TOKEN_HASH="'.$hash.'"';
    $env = preg_match('/^SENDA_TOKEN_HASH=.*$/m', $env)
        ? preg_replace_callback('/^SENDA_TOKEN_HASH=.*$/m', fn () => $line, $env)
        : rtrim($env).PHP_EOL.$line.PHP_EOL;
    file_put_contents($path, $env);
    $this->callSilently('config:clear');
    $this->info('token privado; guárdalo en el iphone y úsalo para entrar a la web:');
    $this->line($token);
})->purpose('crear o rotar el token privado de senda');
