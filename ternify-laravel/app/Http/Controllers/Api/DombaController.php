<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DombaResource;
use App\Models\Domba;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class DombaController extends Controller
{
    /**
     * GET /api/domba
     * Daftar domba milik user yang login (dengan filter opsional)
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Domba::with(['induk', 'pejantan'])
                      ->where('user_id', $request->user()->id);

        // Filter by jenis_kelamin
        if ($request->filled('jenis_kelamin')) {
            $query->where('jenis_kelamin', $request->jenis_kelamin);
        }

        // Filter by id_bangsa
        if ($request->filled('id_bangsa')) {
            $query->where('id_bangsa', $request->id_bangsa);
        }

        // Search by ear_tag
        if ($request->filled('search')) {
            $query->where('ear_tag', 'like', '%' . $request->search . '%');
        }

        $domba = $query->latest()->paginate($request->get('per_page', 15));

        return DombaResource::collection($domba);
    }

    /**
     * POST /api/domba
     * Tambah domba baru (otomatis milik user yang login)
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'ear_tag'       => 'required|string|max:50|unique:domba,ear_tag',
            'id_bangsa'     => 'nullable|string|max:50',
            'jenis_kelamin' => 'required|in:jantan,betina',
            'tanggal_lahir' => 'nullable|date|before_or_equal:today',
            'id_induk'      => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                function ($attribute, $value, $fail) use ($request) {
                    if ($value) {
                        $induk = Domba::where('id_domba', $value)
                                      ->where('user_id', $request->user()->id)
                                      ->first();
                        if (!$induk) {
                            $fail('Induk tidak ditemukan.');
                            return;
                        }
                        if ($induk->jenis_kelamin !== 'betina') {
                            $fail('Induk harus domba betina.');
                        }
                    }
                },
            ],
            'id_pejantan'   => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                function ($attribute, $value, $fail) use ($request) {
                    if ($value) {
                        $pejantan = Domba::where('id_domba', $value)
                                         ->where('user_id', $request->user()->id)
                                         ->first();
                        if (!$pejantan) {
                            $fail('Pejantan tidak ditemukan.');
                            return;
                        }
                        if ($pejantan->jenis_kelamin !== 'jantan') {
                            $fail('Pejantan harus domba jantan.');
                        }
                    }
                },
            ],
        ]);

        $validated['user_id'] = $request->user()->id;

        $domba = Domba::create($validated);
        $domba->load(['induk', 'pejantan']);

        return response()->json([
            'message' => 'Domba berhasil ditambahkan.',
            'data'    => new DombaResource($domba),
        ], 201);
    }

    /**
     * GET /api/domba/{id}
     * Detail satu domba (hanya milik user yang login)
     */
    public function show(Request $request, string $id): JsonResponse
    {
        $domba = Domba::with(['induk', 'pejantan'])
                      ->where('user_id', $request->user()->id)
                      ->findOrFail($id);

        return response()->json([
            'data' => new DombaResource($domba),
        ]);
    }

    /**
     * PUT /api/domba/{id}
     * Update data domba (hanya milik user yang login)
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $domba = Domba::where('user_id', $request->user()->id)
                      ->findOrFail($id);

        $validated = $request->validate([
            'ear_tag'       => ['sometimes', 'string', 'max:50', Rule::unique('domba', 'ear_tag')->ignore($domba->id_domba, 'id_domba')],
            'id_bangsa'     => 'nullable|string|max:50',
            'jenis_kelamin' => 'sometimes|in:jantan,betina',
            'tanggal_lahir' => 'nullable|date|before_or_equal:today',
            'id_induk'      => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                function ($attribute, $value, $fail) use ($id, $request) {
                    if ($value) {
                        if ($value === $id) {
                            $fail('Domba tidak bisa menjadi induk dirinya sendiri.');
                            return;
                        }
                        $induk = Domba::where('id_domba', $value)
                                      ->where('user_id', $request->user()->id)
                                      ->first();
                        if (!$induk) {
                            $fail('Induk tidak ditemukan.');
                            return;
                        }
                        if ($induk->jenis_kelamin !== 'betina') {
                            $fail('Induk harus domba betina.');
                        }
                    }
                },
            ],
            'id_pejantan'   => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                function ($attribute, $value, $fail) use ($id, $request) {
                    if ($value) {
                        if ($value === $id) {
                            $fail('Domba tidak bisa menjadi pejantan dirinya sendiri.');
                            return;
                        }
                        $pejantan = Domba::where('id_domba', $value)
                                         ->where('user_id', $request->user()->id)
                                         ->first();
                        if (!$pejantan) {
                            $fail('Pejantan tidak ditemukan.');
                            return;
                        }
                        if ($pejantan->jenis_kelamin !== 'jantan') {
                            $fail('Pejantan harus domba jantan.');
                        }
                    }
                },
            ],
        ]);

        $domba->update($validated);
        $domba->load(['induk', 'pejantan']);

        return response()->json([
            'message' => 'Data domba berhasil diperbarui.',
            'data'    => new DombaResource($domba),
        ]);
    }

    /**
     * DELETE /api/domba/{id}
     * Hapus domba (soft delete, hanya milik user yang login)
     */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $domba = Domba::where('user_id', $request->user()->id)
                      ->findOrFail($id);
        $domba->delete();

        return response()->json([
            'message' => 'Domba berhasil dihapus.',
        ]);
    }

    /**
     * GET /api/domba/betina/list
     * Daftar domba betina milik user (untuk pilihan induk)
     */
    public function listBetina(Request $request): AnonymousResourceCollection
    {
        $domba = Domba::where('user_id', $request->user()->id)
                      ->where('jenis_kelamin', 'betina')
                      ->select('id_domba', 'ear_tag', 'tanggal_lahir')
                      ->get();

        return DombaResource::collection($domba);
    }

    /**
     * GET /api/domba/jantan/list
     * Daftar domba jantan milik user (untuk pilihan pejantan)
     */
    public function listJantan(Request $request): AnonymousResourceCollection
    {
        $domba = Domba::where('user_id', $request->user()->id)
                      ->where('jenis_kelamin', 'jantan')
                      ->select('id_domba', 'ear_tag', 'tanggal_lahir')
                      ->get();

        return DombaResource::collection($domba);
    }

    /**
     * GET /api/domba/statistik
     * Ringkasan statistik domba milik user untuk dashboard
     */
    public function statistik(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $total       = Domba::where('user_id', $userId)->count();
        $totalJantan = Domba::where('user_id', $userId)->where('jenis_kelamin', 'jantan')->count();
        $totalBetina = Domba::where('user_id', $userId)->where('jenis_kelamin', 'betina')->count();

        // Status kesehatan
        $sehat   = Domba::where('user_id', $userId)->where('status', 'Sehat')->count();
        $bunting = Domba::where('user_id', $userId)->where('status', 'Bunting')->count();
        $sakit   = Domba::where('user_id', $userId)->where('status', 'Sakit')->count();

        // 5 domba terbaru milik user
        $terbaru = Domba::with(['induk', 'pejantan'])
                        ->where('user_id', $userId)
                        ->latest()
                        ->take(5)
                        ->get();

        return response()->json([
            'data' => [
                'total_domba'   => $total,
                'total_jantan'  => $totalJantan,
                'total_betina'  => $totalBetina,
                'status' => [
                    'sehat'   => $sehat,
                    'bunting' => $bunting,
                    'sakit'   => $sakit,
                ],
                'domba_terbaru' => DombaResource::collection($terbaru),
            ],
        ]);
    }
}