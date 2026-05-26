<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\KandangResource;
use App\Models\Kandang;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class KandangController extends Controller
{
    /**
     * GET /api/kandang
     * Daftar kandang milik user yang login
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $kandang = Kandang::where('user_id', $request->user()->id)->get();
        return KandangResource::collection($kandang);
    }

    /**
     * POST /api/kandang
     * Tambah kandang baru (otomatis milik user yang login)
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nama_kandang'  => [
                'required', 'string', 'max:100',
                Rule::unique('kandang', 'nama_kandang')->where('user_id', $request->user()->id),
            ],
            'tipe_kandang'  => 'nullable|string|max:100',
            'kapasitas'     => 'required|integer|min:1|max:9999',
        ]);

        $validated['user_id'] = $request->user()->id;

        $kandang = Kandang::create($validated);

        return response()->json([
            'message' => 'Kandang berhasil ditambahkan.',
            'data'    => new KandangResource($kandang),
        ], 201);
    }

    /**
     * GET /api/kandang/{id}
     * Detail satu kandang (hanya milik user yang login)
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $kandang = Kandang::where('user_id', $request->user()->id)
                          ->findOrFail($id);
        return response()->json(['data' => new KandangResource($kandang)]);
    }

    /**
     * PUT /api/kandang/{id}
     * Update kandang (hanya milik user yang login)
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $kandang = Kandang::where('user_id', $request->user()->id)
                          ->findOrFail($id);

        $validated = $request->validate([
            'nama_kandang'  => [
                'sometimes', 'string', 'max:100',
                Rule::unique('kandang', 'nama_kandang')
                    ->ignore($kandang->id_kandang, 'id_kandang')
                    ->where('user_id', $request->user()->id),
            ],
            'tipe_kandang'  => 'nullable|string|max:100',
            'kapasitas'     => 'sometimes|integer|min:1|max:9999',
        ]);

        $kandang->update($validated);

        return response()->json([
            'message' => 'Kandang berhasil diperbarui.',
            'data'    => new KandangResource($kandang),
        ]);
    }

    /**
     * DELETE /api/kandang/{id}
     * Hapus kandang (soft delete, hanya milik user yang login)
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $kandang = Kandang::where('user_id', $request->user()->id)
                          ->findOrFail($id);

        // Cegah hapus jika masih ada domba di kandang
        if ($kandang->jumlah_domba > 0) {
            return response()->json([
                'message' => "Tidak dapat menghapus kandang yang masih berisi {$kandang->jumlah_domba} domba.",
            ], 422);
        }

        $kandang->delete();
        return response()->json(['message' => 'Kandang berhasil dihapus.']);
    }

    /**
     * GET /api/kandang/statistik
     * Ringkasan kandang milik user untuk summary cards
     */
    public function statistik(Request $request): JsonResponse
    {
        $kandang = Kandang::where('user_id', $request->user()->id)->get();

        $totalDomba = $kandang->sum(fn($k) => $k->jumlah_domba);

        return response()->json([
            'data' => [
                'total_kandang' => $kandang->count(),
                'total_domba'   => $totalDomba,
            ]
        ]);
    }
}