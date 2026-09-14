<?php
use App\Http\Controllers\Api\TrashScanController;

Route::post('/scan-trash', [TrashScanController::class, 'scan']);