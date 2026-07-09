<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LogDigitalisasi;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ScanLogController extends Controller
{
    public function index(Request $request)
    {
        $perPage = min((int) $request->get('per_page', 10), 50);
        $search = $request->get('search');
        $filter = $request->get('filter', 'semua');

        $query = LogDigitalisasi::query()
            ->where('user_id', $request->user()->id);

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('nama_file', 'like', "%{$search}%")
                    ->orWhere('jenis_dokumen', 'like', "%{$search}%");
            });
        }

        if ($filter === 'tinggi') {
            $query->where('akurasi_score', '>', 85);
        } elseif ($filter === 'sedang') {
            $query->whereBetween('akurasi_score', [60, 85]);
        } elseif ($filter === 'rendah') {
            $query->where('akurasi_score', '<', 60);
        }

        if ($dateFrom = $request->get('date_from')) {
            $query->whereDate('tanggal_scan', '>=', $dateFrom);
        }

        if ($dateTo = $request->get('date_to')) {
            $query->whereDate('tanggal_scan', '<=', $dateTo);
        }

        $logs = $query
            ->orderByDesc('tanggal_scan')
            ->orderByDesc('created_at')
            ->paginate($perPage);

        $items = collect($logs->items())
            ->map(fn ($log) => $this->formatLog($log))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Riwayat scan berhasil diambil',
            'total' => $logs->total(),
            'data' => $items,
            'pagination' => [
                'current_page' => $logs->currentPage(),
                'last_page' => $logs->lastPage(),
                'per_page' => $logs->perPage(),
                'has_more' => $logs->hasMorePages(),
            ],
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama_file' => ['nullable', 'string', 'max:255'],
            'jenis_dokumen' => ['required', 'string', 'max:100'],
            'tanggal_scan' => ['nullable', 'date'],
            'akurasi_score' => ['required', 'numeric', 'min:0', 'max:100'],
            'hasil_ocr' => ['nullable', 'string'],
            'detail_data' => ['nullable', 'array'],
        ]);

        $score = (float) $validated['akurasi_score'];

        // Jika OCR mengirim 0.92, ubah menjadi 92
        if ($score <= 1) {
            $score *= 100;
        }

        $score = (int) round(max(0, min(100, $score)));

        $log = LogDigitalisasi::create([
            'id_scan' => 'SCAN-' . now()->format('YmdHis') . '-' . Str::upper(Str::random(5)),
            'user_id' => $request->user()->id,
            'nama_file' => $validated['nama_file'] ?? null,
            'jenis_dokumen' => $validated['jenis_dokumen'],
            'tanggal_scan' => $validated['tanggal_scan'] ?? now()->toDateString(),
            'akurasi_score' => $score,
            'hasil_ocr' => $validated['hasil_ocr'] ?? null,
            'detail_data' => $validated['detail_data'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Riwayat scan berhasil disimpan',
            'data' => $this->formatLog($log),
        ], 201);
    }

    public function show(Request $request, string $id)
    {
        $log = LogDigitalisasi::where('user_id', $request->user()->id)
            ->where('id_scan', $id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Riwayat scan tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->formatLog($log),
        ]);
    }

    public function destroy(Request $request, string $id)
    {
        $log = LogDigitalisasi::where('user_id', $request->user()->id)
            ->where('id_scan', $id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Riwayat scan tidak ditemukan',
            ], 404);
        }

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Riwayat scan berhasil dihapus',
        ]);
    }

    private function formatLog(LogDigitalisasi $log): array
    {
        return [
            'id_scan' => $log->id_scan,
            'nama_file' => $log->nama_file,
            'jenis_dokumen' => $log->jenis_dokumen,
            'tanggal_scan' => optional($log->tanggal_scan)->format('Y-m-d'),
            'tanggal_scan_display' => optional($log->tanggal_scan)->format('d M Y'),
            'akurasi_score' => $log->akurasi_score,
            'hasil_ocr' => $log->hasil_ocr,
            'detail_data' => $log->detail_data,

            // Format tambahan agar mudah dipakai oleh Flutter
            'name' => $log->nama_file ?? $log->jenis_dokumen,
            'sub' => $log->jenis_dokumen,
            'date' => optional($log->tanggal_scan)->format('d M Y'),
            'confidence' => $log->akurasi_score,

            'created_at' => optional($log->created_at)->toDateTimeString(),
            'updated_at' => optional($log->updated_at)->toDateTimeString(),
        ];
    }
}