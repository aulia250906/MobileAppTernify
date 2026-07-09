<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DombaResource;
use App\Models\Domba;
use App\Models\RiwayatKandang;
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
        $query = Domba::with(['induk', 'pejantan', 'kandangAktif'])
            ->where('user_id', $request->user()->id)
            ->where('status_ketersediaan', 'tersedia')
            ->whereHas('kandangAktif');
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
            $query->where('ear_tag', 'like', '%'.$request->search.'%');
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
            'ear_tag' => [
                'required',
                'string',
                'max:50',
                Rule::unique('domba', 'ear_tag')
                    ->where('user_id', $request->user()->id),
            ],            'id_bangsa' => 'nullable|string|max:50',
            'jenis_kelamin' => 'required|in:jantan,betina',
            'tanggal_lahir' => 'nullable|date|before_or_equal:today',
            'id_induk' => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                function ($attribute, $value, $fail) use ($request) {
                    if ($value) {
                        $induk = Domba::where('id_domba', $value)
                            ->where('user_id', $request->user()->id)
                            ->first();
                        if (! $induk) {
                            $fail('Induk tidak ditemukan.');

                            return;
                        }
                        if ($induk->jenis_kelamin !== 'betina') {
                            $fail('Induk harus domba betina.');
                        }
                    }
                },
            ],
            'id_pejantan' => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                function ($attribute, $value, $fail) use ($request) {
                    if ($value) {
                        $pejantan = Domba::where('id_domba', $value)
                            ->where('user_id', $request->user()->id)
                            ->first();
                        if (! $pejantan) {
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
            'data' => new DombaResource($domba),
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

    public function storeFromScan(Request $request): JsonResponse
    {
        $input = $request->all();

        // Helper: treat empty strings as null for cleaner ?? chains
        $val = fn ($key) => isset($input[$key]) && trim((string) $input[$key]) !== ''
            ? trim((string) $input[$key])
            : null;

        // Mapping hasil OCR ke field database
        $input['id_bangsa'] = $val('id_bangsa')
            ?? $val('ras')
            ?? $val('jenis_domba');

        if (isset($input['jenis_kelamin'])) {
            $jk = strtolower(trim($input['jenis_kelamin']));

            if (in_array($jk, ['jantan', 'male', 'laki-laki', 'laki laki'])) {
                $input['jenis_kelamin'] = 'jantan';
            } elseif (in_array($jk, ['betina', 'female', 'perempuan'])) {
                $input['jenis_kelamin'] = 'betina';
            }
        }

        $indukReference = $val('id_induk')
            ?? $val('induk')
            ?? $val('ear_tag_induk')
            ?? $val('eartag_induk')
            ?? $val('tag_induk');
        $pejantanReference = $val('id_pejantan')
            ?? $val('pejantan')
            ?? $val('id_jantan')
            ?? $val('jantan')
            ?? $val('ear_tag_pejantan')
            ?? $val('eartag_pejantan')
            ?? $val('ear_tag_jantan')
            ?? $val('eartag_jantan')
            ?? $val('tag_pejantan')
            ?? $val('tag_jantan');

        $input['id_induk'] = $this->resolveDombaReference($request, $indukReference, 'betina');
        $input['ear_tag_induk'] = $indukReference;
        $input['id_pejantan'] = $this->resolveDombaReference($request, $pejantanReference, 'jantan');
        $input['ear_tag_pejantan'] = $pejantanReference;
        
        if (isset($input['status'])) {
            $input['status'] = ucfirst(strtolower(trim($input['status'])));
        }

        $request->merge($input);

        $validated = $request->validate([
            'ear_tag' => [
                'required',
                'string',
                'max:50',
                Rule::unique('domba', 'ear_tag')
                    ->where('user_id', $request->user()->id),
            ],
            'id_bangsa' => 'nullable|string|max:50',
            'jenis_kelamin' => 'required|in:jantan,betina',
            'tanggal_lahir' => 'nullable|date',
            'berat' => 'nullable|numeric|min:0|max:999.9',
            'status' => 'nullable|in:Sehat,Bunting,Sakit',
            'vaksinasi' => 'nullable|string|max:255',
            'ear_tag_induk' => 'nullable|string|max:50',
            'ear_tag_pejantan' => 'nullable|string|max:50',
            'id_induk' => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                function ($attribute, $value, $fail) use ($request) {
                    if ($value) {
                        $induk = Domba::where('id_domba', $value)
                            ->where('user_id', $request->user()->id)
                            ->first();
                        if (! $induk) {
                            $fail('Induk tidak ditemukan.');

                            return;
                        }
                        if ($induk->jenis_kelamin !== 'betina') {
                            $fail('Induk harus domba betina.');
                        }
                    }
                },
            ],
            'id_pejantan' => [
                'nullable',
                'string',
                Rule::exists('domba', 'id_domba'),
                function ($attribute, $value, $fail) use ($request) {
                    if ($value) {
                        $pejantan = Domba::where('id_domba', $value)
                            ->where('user_id', $request->user()->id)
                            ->first();
                        if (! $pejantan) {
                            $fail('Pejantan tidak ditemukan.');

                            return;
                        }
                        if ($pejantan->jenis_kelamin !== 'jantan') {
                            $fail('Pejantan harus domba jantan.');
                        }
                    }
                },
        ],
        ], [
        'ear_tag.unique' => 'Ear tag sudah terdaftar pada akun ini.',
    ]);

        $validated['user_id'] = $request->user()->id;
        $validated['status'] = $validated['status'] ?? 'Sehat';

        $domba = Domba::create($validated);
        $domba->load(['induk', 'pejantan']);

        return response()->json([
            'success' => true,
            'message' => 'Data domba hasil scan berhasil disimpan.',
            'data' => new DombaResource($domba),
        ], 201);
    }

    private function resolveDombaReference(Request $request, mixed $value, string $jenisKelamin): ?string
    {
        $reference = trim((string) ($value ?? ''));

        if ($reference === '') {
            return null;
        }

        // 1) Exact match on id_domba or ear_tag
        $domba = Domba::where('user_id', $request->user()->id)
            ->where('jenis_kelamin', $jenisKelamin)
            ->where(function ($query) use ($reference) {
                $query->where('id_domba', $reference)
                    ->orWhere('ear_tag', $reference);
            })
            ->first();

        if ($domba) {
            return $domba->id_domba;
        }

        // 2) Partial match — OCR often returns only digits (e.g. "001")
        //    while ear_tag in DB may be "DOM-001". Only accept if exactly
        //    one domba matches to avoid ambiguity.
        $partial = Domba::where('user_id', $request->user()->id)
            ->where('jenis_kelamin', $jenisKelamin)
            ->where('ear_tag', 'like', '%'.$reference.'%')
            ->get();

        if ($partial->count() === 1) {
            return $partial->first()->id_domba;
        }

        return null;
    }

    public function belumKandang(Request $request): AnonymousResourceCollection
    {
        $domba = Domba::with(['induk', 'pejantan'])
            ->where('user_id', $request->user()->id)
            ->where('status_ketersediaan', 'tersedia')
            ->whereDoesntHave('kandangAktif')
            ->latest()
            ->get();

        return DombaResource::collection($domba);
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
            'ear_tag' => ['sometimes', 'string', 'max:50', Rule::unique('domba', 'ear_tag')->ignore($domba->id_domba, 'id_domba')],
            'id_bangsa' => 'nullable|string|max:50',
            'jenis_kelamin' => 'sometimes|in:jantan,betina',
            'tanggal_lahir' => 'nullable|date|before_or_equal:today',
            'id_induk' => [
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
                        if (! $induk) {
                            $fail('Induk tidak ditemukan.');

                            return;
                        }
                        if ($induk->jenis_kelamin !== 'betina') {
                            $fail('Induk harus domba betina.');
                        }
                    }
                },
            ],
            'id_pejantan' => [
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
                        if (! $pejantan) {
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
            'data' => new DombaResource($domba),
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

        // Close any active kandang assignments before deleting
        RiwayatKandang::where('id_domba', $domba->id_domba)
            ->whereNull('tanggal_keluar')
            ->update(['tanggal_keluar' => now()->toDateString()]);

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

        $baseQuery = Domba::where('user_id', $userId)
            ->whereHas('kandangAktif');

        $total = (clone $baseQuery)->count();
        $totalJantan = (clone $baseQuery)->where('jenis_kelamin', 'jantan')->count();
        $totalBetina = (clone $baseQuery)->where('jenis_kelamin', 'betina')->count();

        $sehat = (clone $baseQuery)->where('status', 'Sehat')->count();
        $bunting = (clone $baseQuery)->where('status', 'Bunting')->count();
        $sakit = (clone $baseQuery)->where('status', 'Sakit')->count();

        $terbaru = Domba::with(['induk', 'pejantan'])
            ->where('user_id', $userId)
            ->whereHas('kandangAktif')
            ->latest()
            ->take(5)
            ->get();

        return response()->json([
            'data' => [
                'total_domba' => $total,
                'total_jantan' => $totalJantan,
                'total_betina' => $totalBetina,
                'status' => [
                    'sehat' => $sehat,
                    'bunting' => $bunting,
                    'sakit' => $sakit,
                ],
                'domba_terbaru' => DombaResource::collection($terbaru),
            ],
        ]);
    }
}
