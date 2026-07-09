<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Perkawinan;
use App\Models\Domba;
use Illuminate\Http\Request;

class PerkawinanController extends Controller
{
    /**
     * GET /api/perkawinan?ear_tag=xxx
     * Daftar perkawinan (bisa filter by ear_tag betina atau jantan)
     */
    public function index(Request $request)
    {
        $userId = $request->user()->id;
        $query = Perkawinan::where('user_id', $userId)
            ->with(['betina:id_domba,ear_tag,id_bangsa', 'jantan:id_domba,ear_tag,id_bangsa'])
            ->orderBy('tanggal_kawin', 'desc');

        if ($request->has('ear_tag') && $request->ear_tag) {
            $earTag = $request->ear_tag;
            $query->where(function ($q) use ($earTag) {
                $q->where('ear_tag_betina', $earTag)
                  ->orWhere('ear_tag_jantan', $earTag);
            });
        }

        if ($request->has('status') && $request->status) {
            $query->where('status_perkawinan', $request->status);
        }

        $records = $query->get();

        return response()->json([
            'success' => true,
            'data'    => $records,
        ]);
    }

    /**
     * POST /api/perkawinan
     * Simpan data perkawinan baru
     */
    public function store(Request $request)
    {
        $request->validate([
            'ear_tag_betina'         => 'required|string',
            'ear_tag_jantan'         => 'required|string',
            'tanggal_kawin'          => 'required|date',
            'metode_kawin'           => 'nullable|string|max:50',
            'tanggal_perkiraan_lahir' => 'nullable|date',
            'status_perkawinan'      => 'nullable|string|max:50',
            'jumlah_anak'            => 'nullable|integer|min:0',
            'catatan'                => 'nullable|string',
        ]);

        $userId = $request->user()->id;

        // Cari domba betina & jantan by ear_tag
        $betina = Domba::where('user_id', $userId)
            ->where('ear_tag', $request->ear_tag_betina)
            ->first();

        $jantan = Domba::where('user_id', $userId)
            ->where('ear_tag', $request->ear_tag_jantan)
            ->first();

        $record = Perkawinan::create([
            'user_id'                => $userId,
            'id_domba_betina'        => $betina?->id_domba,
            'id_domba_jantan'        => $jantan?->id_domba,
            'ear_tag_betina'         => $request->ear_tag_betina,
            'ear_tag_jantan'         => $request->ear_tag_jantan,
            'tanggal_kawin'          => $request->tanggal_kawin,
            'metode_kawin'           => $request->metode_kawin ?? 'alami',
            'tanggal_perkiraan_lahir' => $request->tanggal_perkiraan_lahir,
            'status_perkawinan'      => $request->status_perkawinan ?? 'kawin',
            'jumlah_anak'            => $request->jumlah_anak,
            'catatan'                => $request->catatan,
        ]);

        // Update status domba betina menjadi bunting jika perlu
        $statusKawinStr = strtolower($request->status_perkawinan ?? 'kawin');
        if ($betina && \Illuminate\Support\Str::contains($statusKawinStr, 'bunting')) {
            $betina->update(['status' => 'Bunting']);
        }

        $record->load(['betina:id_domba,ear_tag,id_bangsa', 'jantan:id_domba,ear_tag,id_bangsa']);

        return response()->json([
            'success' => true,
            'message' => 'Data perkawinan berhasil disimpan.',
            'data'    => $record,
        ], 201);
    }

    /**
     * PUT /api/perkawinan/{id}
     * Update data perkawinan (status, jumlah anak, dll)
     */
    public function update(Request $request, int $id)
    {
        $record = Perkawinan::where('user_id', $request->user()->id)
            ->findOrFail($id);

        $request->validate([
            'status_perkawinan'      => 'nullable|string|max:50',
            'jumlah_anak'            => 'nullable|integer|min:0',
            'tanggal_perkiraan_lahir' => 'nullable|date',
            'catatan'                => 'nullable|string',
        ]);

        $record->update($request->only([
            'status_perkawinan',
            'jumlah_anak',
            'tanggal_perkiraan_lahir',
            'catatan',
        ]));

        // Sync status betina
        if ($request->filled('status_perkawinan') && $record->id_domba_betina) {
            $betina = Domba::find($record->id_domba_betina);
            if ($betina) {
                $statusReq = strtolower($request->status_perkawinan);
                if (\Illuminate\Support\Str::contains($statusReq, 'bunting')) {
                    $betina->update(['status' => 'Bunting']);
                } elseif (\Illuminate\Support\Str::contains($statusReq, ['lahir', 'gagal', 'kawin'])) {
                    $betina->update(['status' => 'Sehat']);
                }
            }
        }

        $record->load(['betina:id_domba,ear_tag,id_bangsa', 'jantan:id_domba,ear_tag,id_bangsa']);

        return response()->json([
            'success' => true,
            'message' => 'Data perkawinan berhasil diperbarui.',
            'data'    => $record,
        ]);
    }

    /**
     * GET /api/domba/{id}/perkawinan
     * Riwayat perkawinan berdasarkan id domba
     */
    public function byDomba(Request $request, string $idDomba)
    {
        $userId = $request->user()->id;

        $records = Perkawinan::where('user_id', $userId)
            ->where(function ($q) use ($idDomba) {
                $q->where('id_domba_betina', $idDomba)
                  ->orWhere('id_domba_jantan', $idDomba);
            })
            ->with(['betina:id_domba,ear_tag,id_bangsa', 'jantan:id_domba,ear_tag,id_bangsa'])
            ->orderBy('tanggal_kawin', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $records,
        ]);
    }

    /**
     * GET /api/perkawinan/{id}
     */
    public function show(Request $request, int $id)
    {
        $record = Perkawinan::where('user_id', $request->user()->id)
            ->with(['betina:id_domba,ear_tag,id_bangsa', 'jantan:id_domba,ear_tag,id_bangsa'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => $record,
        ]);
    }

    /**
     * DELETE /api/perkawinan/{id}
     */
    public function destroy(Request $request, int $id)
    {
        $record = Perkawinan::where('user_id', $request->user()->id)
            ->findOrFail($id);

        $record->delete();

        return response()->json([
            'success' => true,
            'message' => 'Data perkawinan berhasil dihapus.',
        ]);
    }
}
