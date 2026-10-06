<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class PrivateAccess
{
    public function handle(Request $request, Closure $next): Response
    {
        $hash = config('senda.token_hash');
        abort_unless(is_string($hash) && $hash !== '', 503, 'configura el token privado del servidor');
        if ($request->is('api/*')) {
            $token = $request->bearerToken() ?? '';
            abort_unless(strlen($token) <= 128 && password_verify($token, $hash), 401, 'token inválido');
        } elseif (! hash_equals(hash('sha256', $hash), (string) $request->session()->get('senda_auth', ''))) {
            return redirect()->route('login');
        }

        $response = $next($request);
        $response->headers->set('Cache-Control', 'private, no-store');
        $response->headers->set('X-Robots-Tag', 'noindex, nofollow');

        return $response;
    }
}
