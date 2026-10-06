<?php

use App\Http\Controllers\TripController;
use App\Http\Middleware\PrivateAccess;
use Illuminate\Support\Facades\Route;

Route::middleware(['throttle:60,1', PrivateAccess::class])->group(function () {
    Route::post('/trips', [TripController::class, 'store']);
    Route::get('/trips', [TripController::class, 'index']);
    Route::get('/trips/{id}', [TripController::class, 'show'])->whereUuid('id');
});
