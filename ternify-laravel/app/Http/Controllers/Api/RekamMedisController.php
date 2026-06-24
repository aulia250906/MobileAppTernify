<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RekamMedis;
use App\Models\Domba;
use Illuminate\Http\Request;

class RekamMedisController extends Controller
{
    /**
     * GET /api/rekam-medis?ear_tag=xxx
     * Ambil daftar rekam medis (filter by ear_tag).
     */
    public function index(Request $request)
    {
        $userId = $request->user()->id;
        $query = RekamMedis::where('user_id', $userId)
            ->orderBy('tanggal_pemeriksaan', 'desc')
            ->orderBy('created_at', 'desc');

        if ($request->has('ear_tag') && $request->ear_tag) {
            $query->where('ear_tag', $request->ear_tag);
        }

        if ($request->has('id_domba') && $request->id_domba) {
            $query->where('id_domba', $request->id_domba);
        }

        $records = $query->get();

        return response()->json([
            'success' => true,
            'data'    => $records,
        ]);
    }

    /**
     * POST /api/rekam-medis
     * Simpan rekam medis baru (dari scan atau manual).
     */
    public function store(Request $request)
    {
        $request->validate([
            'ear_tag'              => 'required|string',
            'tanggal_pemeriksaan'  => 'required|date',
            'berat'                => 'nullable|numeric',
            'suhu_tubuh'           => 'nullable|numeric',
            'status_kesehatan'     => 'nullable|string|max:100',
            'vaksinasi'            => 'nullable|string|max:100',
            'obat'                 => 'nullable|string',
            'catatan'              => 'nullable|string',
        ]);

        $userId = $request->user()->id;

        // Try to find the associated domba by ear_tag
        $domba = Domba::where('user_id', $userId)
            ->where('ear_tag', $request->ear_tag)
            ->first();

        $record = RekamMedis::create([
            'user_id'              => $userId,
            'id_domba'             => $domba?->id_domba,
            'ear_tag'              => $request->ear_tag,
            'tanggal_pemeriksaan'  => $request->tanggal_pemeriksaan,
            'berat'                => $request->berat,
            'suhu_tubuh'           => $request->suhu_tubuh,
            'status_kesehatan'     => $request->status_kesehatan,
            'vaksinasi'            => $request->vaksinasi,
            'obat'                 => $request->obat,
            'catatan'              => $request->catatan,
        ]);

        // Also update the domba's weight and status if provided
        if ($domba) {
            $updates = [];
            if ($request->filled('berat')) {
                $updates['berat'] = $request->berat;
            }
            if ($request->filled('status_kesehatan')) {
                // Map to domba status enum
                $statusMap = [
                    'sehat'           => 'Sehat',
                    'sakit'           => 'Sakit',
                    'bunting'         => 'Bunting',
                    'dalam perawatan' => 'Sakit',
                    'perawatan'       => 'Sakit',
                    'karantina'       => 'Sakit',
                ];
                $mappedStatus = $statusMap[strtolower($request->status_kesehatan)] ?? null;
                if ($mappedStatus) {
                    $updates['status'] = $mappedStatus;
                }
            }
            if ($request->filled('vaksinasi')) {
                $updates['vaksinasi'] = $request->vaksinasi;
            }
            if (!empty($updates)) {
                $domba->update($updates);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Rekam medis berhasil disimpan.',
            'data'    => $record,
        ], 201);
    }

    /**
     * GET /api/domba/{id}/rekam-medis
     * Ambil rekam medis berdasarkan id domba.
     */
    public function byDomba(Request $request, string $idDomba)
    {
        $userId = $request->user()->id;

        $records = RekamMedis::where('user_id', $userId)
            ->where('id_domba', $idDomba)
            ->orderBy('tanggal_pemeriksaan', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $records,
        ]);
    }

    /**
     * GET /api/rekam-medis/{id}
     * Detail satu rekam medis.
     */
    public function show(Request $request, int $id)
    {
        $record = RekamMedis::where('user_id', $request->user()->id)
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $record,
        ]);
    }

    /**
     * DELETE /api/rekam-medis/{id}
     */
    public function destroy(Request $request, int $id)
    {
        $record = RekamMedis::where('user_id', $request->user()->id)
            ->findOrFail($id);

        $record->delete();

        return response()->json([
            'success' => true,
            'message' => 'Rekam medis berhasil dihapus.',
        ]);
    }
}
