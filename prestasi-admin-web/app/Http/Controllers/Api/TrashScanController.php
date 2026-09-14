<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class TrashScanController extends Controller
{
    public function scan(Request $request)
    {
        $request->validate([
            'image' => 'required|image|max:10240', // max 10MB
        ]);

        $apiKey = config('services.gemini.api_key');

        if (empty($apiKey)) {
            return response()->json(['error' => 'Gemini API key belum dikonfigurasi'], 500);
        }

        $imageData = base64_encode(file_get_contents($request->file('image')->getRealPath()));

        $prompt = <<<PROMPT
Kamu adalah sistem klasifikasi sampah untuk aplikasi kampus hijau.
Lihat gambar ini dan tentukan jenis sampah yang paling dominan (contoh: Plastik, Kertas, Organik, Logam, Kaca, Elektronik, atau Tidak Terdeteksi jika bukan sampah).
Berikan juga poin yang pantas (rentang 5-20) berdasarkan seberapa jelas dan valid sampahnya.

Balas HANYA dengan JSON murni tanpa markdown, format persis seperti ini:
{"detected_item": "nama_jenis_sampah", "points_awarded": angka}
PROMPT;

        try {
            $response = Http::timeout(20)->post(
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={$apiKey}",
                [
                    'contents' => [
                        [
                            'parts' => [
                                ['text' => $prompt],
                                [
                                    'inline_data' => [
                                        'mime_type' => $request->file('image')->getMimeType(),
                                        'data' => $imageData,
                                    ],
                                ],
                            ],
                        ],
                    ],
                ]
            );

            if (!$response->successful()) {
                Log::error('Gemini API error', ['status' => $response->status(), 'body' => $response->body()]);
                return response()->json([
                    'error' => 'Gagal memproses gambar',
                    'status' => $response->status(),
                ], $response->status());
            }

            $rawText = $response->json('candidates.0.content.parts.0.text', '');
            $rawText = trim($rawText);
            $rawText = preg_replace('/```json|```/', '', $rawText);
            $rawText = trim($rawText);

            $result = json_decode($rawText, true);

            if (!$result || !isset($result['detected_item'])) {
                Log::error('Gagal parse response Gemini', ['raw' => $rawText]);
                return response()->json(['error' => 'Format respons AI tidak valid'], 502);
            }

            return response()->json([
                'detected_item' => $result['detected_item'],
                'points_awarded' => $result['points_awarded'] ?? 10,
            ]);
        } catch (\Exception $e) {
            Log::error('Exception saat scan', ['message' => $e->getMessage()]);
            return response()->json(['error' => 'Terjadi kesalahan server'], 500);
        }
    }
}