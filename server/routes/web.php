<?php

use App\Http\Controllers\TripController;
use App\Http\Middleware\PrivateAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/login', fn () => view('login'))->name('login');
Route::post('/login', function (Request $request) {
    $request->validate(['token' => 'required|string|max:128']);
    $hash = config('senda.token_hash');
    if (! $hash || ! password_verify($request->string('token'), $hash)) {
        return back()->withErrors(['token' => 'el token no es válido o el servidor todavía no está configurado']);
    }
    $request->session()->regenerate();
    $request->session()->put('senda_auth', hash('sha256', $hash));

    return redirect('/');
})->middleware('throttle:5,1');
Route::post('/logout', function (Request $request) {
    $request->session()->invalidate();
    $request->session()->regenerateToken();

    return redirect('/login');
});
Route::middleware(PrivateAccess::class)->group(function () {
    Route::get('/', fn () => view('dashboard'));
    Route::get('/data/trips', [TripController::class, 'index']);
    Route::get('/data/trips/{id}', [TripController::class, 'show'])->whereUuid('id');
    Route::get('/data/trips/{id}/export', [TripController::class, 'export'])->whereUuid('id');
});
