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
        ->where('status_ketersediaan', 'tersedia')
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
 * POST /api/kandang/{id}/remove-domba
 * Remove domba from kandang with reason
 * reason: 'dikeluarkan' | 'terjual' | 'mati'
 */
public function removeDomba(Request $request, string $id): JsonResponse
{
    $kandang = Kandang::where('user_id', $request->user()->id)
        ->findOrFail($id);

    $validated = $request->validate([
        'domba_ids' => 'required|array|min:1',
        'domba_ids.*' => 'required|string',
        'reason' => 'required|in:dikeluarkan,terjual,mati',
    ]);

    $dombaIds = collect($validated['domba_ids'])->unique()->values();
    $reason = $validated['reason'];

    // Close riwayat_kandang for all reasons
    $updated = RiwayatKandang::where('id_kandang', $kandang->id_kandang)
        ->whereNull('tanggal_keluar')
        ->whereIn('id_domba', $dombaIds)
        ->update(['tanggal_keluar' => now()->toDateString()]);

    // For 'terjual' and 'mati', also update domba status_ketersediaan
    if (in_array($reason, ['terjual', 'mati'])) {
        Domba::where('user_id', $request->user()->id)
            ->whereIn('id_domba', $dombaIds)
            ->update(['status_ketersediaan' => $reason]);
    }

    $messages = [
        'dikeluarkan' => "{$updated} domba berhasil dikeluarkan dari kandang.",
        'terjual' => "{$updated} domba ditandai sebagai terjual.",
        'mati' => "{$updated} domba ditandai sebagai mati.",
    ];

    return response()->json([
        'success' => true,
        'message' => $messages[$reason],
        'removed_count' => $updated,
    ]);
}

    /**
     * GET /api/kandang/statistik
     * Ringkasan kandang milik user untuk summary cards
     */
    public function statistik(Request $request): JsonResponse
    {
        $userId = $request->user()->id;
        $kandang = Kandang::where('user_id', $userId)->get();

        $totalDomba = $kandang->sum(fn($k) => $k->jumlah_domba);

        // Total semua domba milik user (termasuk terjual & mati)
        $totalDombaSemua = Domba::where('user_id', $userId)->count();

        return response()->json([
            'data' => [
                'total_kandang'     => $kandang->count(),
                'total_domba'       => $totalDomba,
                'total_domba_semua' => $totalDombaSemua,
            ]
        ]);
    }

    /**
     * GET /api/kandang/semua-domba
     * List ALL domba (tersedia, terjual, mati) for the user
     */
    public function semuaDomba(Request $request): JsonResponse
    {
        $domba = Domba::where('user_id', $request->user()->id)
            ->orderByRaw("FIELD(status_ketersediaan, 'tersedia', 'terjual', 'mati')")
            ->latest()
            ->get();

        $result = $domba->map(function ($d) {
            $item = [
                'id_domba' => $d->id_domba,
                'ear_tag' => $d->ear_tag,
                'id_bangsa' => $d->id_bangsa,
                'jenis_kelamin' => $d->jenis_kelamin,
                'status' => $d->status,
                'berat' => $d->berat,
                'status_ketersediaan' => $d->status_ketersediaan ?? 'tersedia',
                'updated_at' => $d->updated_at?->toDateString(),
            ];

            // For tersedia: include latest rekam medis
            if (($d->status_ketersediaan ?? 'tersedia') === 'tersedia') {
                $latestRekamMedis = \App\Models\RekamMedis::where('id_domba', $d->id_domba)
                    ->orderBy('tanggal_pemeriksaan', 'desc')
                    ->first();

                $item['rekam_medis_terakhir'] = $latestRekamMedis ? [
                    'tanggal' => $latestRekamMedis->tanggal_pemeriksaan?->format('Y-m-d'),
                    'status_kesehatan' => $latestRekamMedis->status_kesehatan,
                    'catatan' => $latestRekamMedis->catatan,
                ] : null;
            }

            return $item;
        });

        return response()->json([
            'success' => true,
            'data' => $result,
        ]);
    }
}