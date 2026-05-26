<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DombaController;
use App\Http\Controllers\Api\KandangController;
use Illuminate\Support\Facades\Route;

// ── Public routes (tidak perlu token) ──
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);
 
// ── Protected routes (butuh token Sanctum) ──
Route::middleware('auth:sanctum')->group(function () {
    // Auth & Profile
    Route::get('/profile',    [AuthController::class, 'profile']);
    Route::put('/profile',    [AuthController::class, 'updateProfile']);
    Route::post('/logout',    [AuthController::class, 'logout']);

    // Domba (data per user)
    Route::prefix('domba')->group(function () {
        Route::get('statistik',     [DombaController::class, 'statistik']);
        Route::get('betina/list',   [DombaController::class, 'listBetina']);
        Route::get('jantan/list',   [DombaController::class, 'listJantan']);
        Route::get('/',             [DombaController::class, 'index']);
        Route::post('/',            [DombaController::class, 'store']);
        Route::get('/{id}',         [DombaController::class, 'show']);
        Route::put('/{id}',         [DombaController::class, 'update']);
        Route::delete('/{id}',      [DombaController::class, 'destroy']);
    });

    // Kandang (data per user)
    Route::prefix('kandang')->group(function () {
        Route::get('statistik',   [KandangController::class, 'statistik']);
        Route::get('/',           [KandangController::class, 'index']);
        Route::post('/',          [KandangController::class, 'store']);
        Route::get('/{id}',       [KandangController::class, 'show']);
        Route::put('/{id}',       [KandangController::class, 'update']);
        Route::delete('/{id}',    [KandangController::class, 'destroy']);
    });
});