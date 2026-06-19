<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DombaController;
use App\Http\Controllers\Api\KandangController;
use App\Http\Controllers\Api\ScanLogController;
use Illuminate\Support\Facades\Route;

// ── Public routes (tidak perlu token) ──
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/login/google', [AuthController::class, 'loginWithGoogle']);

Route::post('/forgot-password/send-otp', [AuthController::class, 'sendResetOtp']);
Route::post('/forgot-password/verify-otp', [AuthController::class, 'verifyResetOtp']);
Route::post('/forgot-password/reset', [AuthController::class, 'resetPassword']); 
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
        Route::get('belum-kandang', [DombaController::class, 'belumKandang']);
Route::post('from-scan',    [DombaController::class, 'storeFromScan']);
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
        Route::get('/{id}/domba',         [KandangController::class, 'domba']);
Route::post('/{id}/assign-domba', [KandangController::class, 'assignDomba']);
        Route::get('/{id}',       [KandangController::class, 'show']);
        Route::put('/{id}',       [KandangController::class, 'update']);
        Route::delete('/{id}',    [KandangController::class, 'destroy']);
    });

    Route::prefix('scan-logs')->group(function () {
    Route::get('/',        [ScanLogController::class, 'index']);
    Route::post('/',       [ScanLogController::class, 'store']);
    Route::get('/{id}',    [ScanLogController::class, 'show']);
    Route::delete('/{id}', [ScanLogController::class, 'destroy']);
});
});