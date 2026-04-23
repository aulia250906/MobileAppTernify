<?php

use App\Http\Controllers\Api\DombaController;
use Illuminate\Support\Facades\Route;

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