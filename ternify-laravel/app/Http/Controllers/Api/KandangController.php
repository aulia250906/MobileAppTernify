<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\KandangResource;
use App\Models\Kandang;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;
use App\Models\RiwayatKandang;
use App\Models\Domba;
use Illuminate\Support\Facades\DB;
use App\Http\Resources\DombaResource;

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

    public function domba(Request $request, string $id): AnonymousResourceCollection
{
    $kandang = Kandang::where('user_id', $request->user()->id)
        ->findOrFail($id);

    $domba = Domba::with(['induk', 'pejantan'])
        ->where('user_id', $request->user()->id)
        ->whereHas('kandangAktif', function ($q) use ($kandang) {
            $q->where('id_kandang', $kandang->id_kandang);
        })
        ->latest()
        ->get();

    return DombaResource::collection($domba);
}

public function assignDomba(Request $request, string $id): JsonResponse
{
    $kandang = Kandang::where('user_id', $request->user()->id)
        ->findOrFail($id);

    $validated = $request->validate([
        'domba_ids' => 'required|array|min:1',
        'domba_ids.*' => 'required|string',
        'tanggal_masuk' => 'nullable|date',
    ]);

    $userId = $request->user()->id;
    $tanggalMasuk = $validated['tanggal_masuk'] ?? now()->toDateString();

    $dombaIds = collect($validated['domba_ids'])
        ->unique()
        ->values();

    $validDombaCount = Domba::where('user_id', $userId)
        ->whereIn('id_domba', $dombaIds)
        ->count();

    if ($validDombaCount !== $dombaIds->count()) {
        return response()->json([
            'message' => 'Ada data domba yang tidak valid atau bukan milik akun ini.',
        ], 422);
    }

    $jumlahAktifSaatIni = RiwayatKandang::where('id_kandang', $kandang->id_kandang)
        ->whereNull('tanggal_keluar')
        ->count();

    $sudahDiKandangIni = RiwayatKandang::where('id_kandang', $kandang->id_kandang)
        ->whereNull('tanggal_keluar')
        ->whereIn('id_domba', $dombaIds)
        ->pluck('id_domba');

    $jumlahDombaBaru = $dombaIds->diff($sudahDiKandangIni)->count();

    if (($jumlahAktifSaatIni + $jumlahDombaBaru) > $kandang->kapasitas) {
        return response()->json([
            'message' => 'Kapasitas kandang tidak mencukupi.',
        ], 422);
    }

    DB::transaction(function () use ($dombaIds, $userId, $kandang, $tanggalMasuk) {
        foreach ($dombaIds as $idDomba) {
            // Tutup kandang aktif sebelumnya.
            // Ini membuat domba bisa pindah kandang.
            RiwayatKandang::where('user_id', $userId)
                ->where('id_domba', $idDomba)
                ->whereNull('tanggal_keluar')
                ->update([
                    'tanggal_keluar' => now()->toDateString(),
                ]);

            // Buat kandang aktif baru
            RiwayatKandang::create([
                'user_id' => $userId,
                'id_kandang' => $kandang->id_kandang,
                'id_domba' => $idDomba,
                'tanggal_masuk' => $tanggalMasuk,
                'tanggal_keluar' => null,
            ]);
        }
    });

    return response()->json([
        'success' => true,
        'message' => 'Domba berhasil dimasukkan ke kandang.',
    ]);
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