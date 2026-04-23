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
     * Daftar semua domba (dengan filter opsional)
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Domba::with(['induk', 'pejantan']);

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
     * Tambah domba baru
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
                // Induk harus betina
                function ($attribute, $value, $fail) {
                    if ($value) {
                        $induk = Domba::find($value);
                        if ($induk && $induk->jenis_kelamin !== 'betina') {
                            $fail('Induk harus domba betina.');
                        }
                    }
                },
            ],
            'id_pejantan'   => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                // Pejantan harus jantan
                function ($attribute, $value, $fail) {
                    if ($value) {
                        $pejantan = Domba::find($value);
                        if ($pejantan && $pejantan->jenis_kelamin !== 'jantan') {
                            $fail('Pejantan harus domba jantan.');
                        }
                    }
                },
            ],
        ]);

        $domba = Domba::create($validated);
        $domba->load(['induk', 'pejantan']);

        return response()->json([
            'message' => 'Domba berhasil ditambahkan.',
            'data'    => new DombaResource($domba),
        ], 201);
    }

    /**
     * GET /api/domba/{id}
     * Detail satu domba
     */
    public function show(string $id): JsonResponse
    {
        $domba = Domba::with(['induk', 'pejantan'])->findOrFail($id);

        return response()->json([
            'data' => new DombaResource($domba),
        ]);
    }

    /**
     * PUT /api/domba/{id}
     * Update data domba
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $domba = Domba::findOrFail($id);

        $validated = $request->validate([
            'ear_tag'       => ['sometimes', 'string', 'max:50', Rule::unique('domba', 'ear_tag')->ignore($domba->id_domba, 'id_domba')],
            'id_bangsa'     => 'nullable|string|max:50',
            'jenis_kelamin' => 'sometimes|in:jantan,betina',
            'tanggal_lahir' => 'nullable|date|before_or_equal:today',
            'id_induk'      => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                function ($attribute, $value, $fail) use ($id) {
                    if ($value) {
                        if ($value === $id) {
                            $fail('Domba tidak bisa menjadi induk dirinya sendiri.');
                            return;
                        }
                        $induk = Domba::find($value);
                        if ($induk && $induk->jenis_kelamin !== 'betina') {
                            $fail('Induk harus domba betina.');
                        }
                    }
                },
            ],
            'id_pejantan'   => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                function ($attribute, $value, $fail) use ($id) {
                    if ($value) {
                        if ($value === $id) {
                            $fail('Domba tidak bisa menjadi pejantan dirinya sendiri.');
                            return;
                        }
                        $pejantan = Domba::find($value);
                        if ($pejantan && $pejantan->jenis_kelamin !== 'jantan') {
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
     * Hapus domba (soft delete)
     */
    public function destroy(string $id): JsonResponse
    {
        $domba = Domba::findOrFail($id);
        $domba->delete();

        return response()->json([
            'message' => 'Domba berhasil dihapus.',
        ]);
    }

    /**
     * GET /api/domba/betina/list
     * Daftar domba betina saja (untuk pilihan induk)
     */
    public function listBetina(): AnonymousResourceCollection
    {
        $domba = Domba::where('jenis_kelamin', 'betina')
                      ->select('id_domba', 'ear_tag', 'tanggal_lahir')
                      ->get();

        return DombaResource::collection($domba);
    }

    /**
     * GET /api/domba/jantan/list
     * Daftar domba jantan saja (untuk pilihan pejantan)
     */
    public function listJantan(): AnonymousResourceCollection
    {
        $domba = Domba::where('jenis_kelamin', 'jantan')
                      ->select('id_domba', 'ear_tag', 'tanggal_lahir')
                      ->get();

        return DombaResource::collection($domba);
    }
}