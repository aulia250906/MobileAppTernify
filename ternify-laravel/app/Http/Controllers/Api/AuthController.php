<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\PasswordResetOtp;
use Google_Client;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class AuthController extends Controller
{
    // ─────────────────────────────────────────────
    // REGISTER
    // ─────────────────────────────────────────────
public function register(Request $request)
{
    $request->validate([
        'nama_lengkap' => 'required|string|max:255',
        'email'        => 'required|email|unique:users,email',
        'password'     => 'required|string|min:8|confirmed',
    ]);

    $user = User::create([
        'nama_lengkap' => $request->nama_lengkap,
        'email'        => strtolower($request->email),
        'password'     => Hash::make($request->password),
    ]);

    return response()->json([
        'success' => true,
        'message' => 'Registrasi berhasil. Silakan login terlebih dahulu.',
        'user'    => $user,
    ], 201);
}

    // ─────────────────────────────────────────────
    // LOGIN
    // ─────────────────────────────────────────────
public function login(Request $request)
{
    $request->validate([
        'email'    => 'required|email',
        'password' => 'required|string',
    ]);

    $user = User::where('email', strtolower($request->email))->first();

    if ($user && is_null($user->password) && $user->google_id) {
        return response()->json([
            'success' => false,
            'message' => 'Akun ini terdaftar menggunakan Google. Silakan lanjutkan dengan akun Google.',
        ], 401);
    }

    if (!$user || !Hash::check($request->password, $user->password)) {
        return response()->json([
            'success' => false,
            'message' => 'Email atau kata sandi salah',
        ], 401);
    }

    $user->tokens()->delete();

    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'success' => true,
        'message' => 'Login berhasil',
        'token'   => $token,
        'user'    => $user,
    ]);
}

public function loginWithGoogle(Request $request)
{
    $request->validate([
        'id_token' => 'required|string',
    ]);

    $client = new Google_Client([
        'client_id' => env('GOOGLE_CLIENT_ID'),
    ]);

    $payload = $client->verifyIdToken($request->id_token);

    if (!$payload) {
        return response()->json([
            'success' => false,
            'message' => 'Token Google tidak valid',
        ], 401);
    }

    $googleId = $payload['sub'];
    $email = $payload['email'] ?? null;
    $namaLengkap = $payload['name'] ?? 'Peternak Ternify';
    $avatar = $payload['picture'] ?? null;
    $emailVerified = $payload['email_verified'] ?? false;

    if (!$email || !$emailVerified) {
        return response()->json([
            'success' => false,
            'message' => 'Email Google belum terverifikasi',
        ], 422);
    }

    $user = User::where('google_id', $googleId)
        ->orWhere('email', $email)
        ->first();

    if (!$user) {
        $user = User::create([
            'google_id' => $googleId,
            'nama_lengkap' => $namaLengkap,
            'email' => $email,
            'password' => null,
            'avatar' => $avatar,
            'email_verified_at' => now(),
        ]);
    } else {
        $user->update([
            'google_id' => $user->google_id ?? $googleId,
            'avatar' => $avatar,
            'email_verified_at' => $user->email_verified_at ?? now(),
        ]);
    }

    $user->tokens()->delete();

    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'success' => true,
        'message' => 'Login Google berhasil',
        'token' => $token,
        'user' => $user->fresh(),
    ]);
}

public function sendResetOtp(Request $request)
{
    $request->validate([
        'email' => 'required|email',
    ]);

    $email = strtolower($request->email);

    $user = User::where('email', $email)->first();

    if (!$user) {
        return response()->json([
            'success' => true,
            'message' => 'Jika email terdaftar, kode OTP akan dikirim',
        ]);
    }

    $otp = random_int(100000, 999999);

    PasswordResetOtp::where('email', $email)
        ->whereNull('used_at')
        ->update([
            'used_at' => now(),
        ]);

    PasswordResetOtp::create([
        'email' => $email,
        'otp_hash' => Hash::make($otp),
        'expires_at' => now()->addMinutes(10),
    ]);

    Mail::raw("Kode OTP reset password Ternify Anda adalah: $otp. Kode berlaku selama 10 menit.", function ($message) use ($email) {
        $message->to($email)
            ->subject('Kode OTP Reset Password Ternify');
    });

    return response()->json([
        'success' => true,
        'message' => 'Kode OTP berhasil dikirim',
    ]);
}

public function resetPassword(Request $request)
{
    $request->validate([
        'email' => 'required|email',
        'otp' => 'required|digits:6',
        'password' => 'required|string|min:8|confirmed',
    ]);

    $email = strtolower($request->email);

    $otpRecord = PasswordResetOtp::where('email', $email)
        ->whereNull('used_at')
        ->where('expires_at', '>', now())
        ->latest()
        ->first();

    if (!$otpRecord || !Hash::check($request->otp, $otpRecord->otp_hash)) {
        return response()->json([
            'success' => false,
            'message' => 'OTP tidak valid atau sudah kedaluwarsa',
        ], 422);
    }

    $user = User::where('email', $email)->first();

    if (!$user) {
        return response()->json([
            'success' => false,
            'message' => 'User tidak ditemukan',
        ], 404);
    }

    $user->update([
        'password' => Hash::make($request->password),
    ]);

    $otpRecord->update([
        'used_at' => now(),
    ]);

    return response()->json([
        'success' => true,
        'message' => 'Password berhasil diubah',
    ]);
}

public function verifyResetOtp(Request $request)
{
    $request->validate([
        'email' => 'required|email',
        'otp' => 'required|digits:6',
    ]);

    $email = strtolower($request->email);

    $otpRecord = PasswordResetOtp::where('email', $email)
        ->whereNull('used_at')
        ->where('expires_at', '>', now())
        ->latest()
        ->first();

    if (!$otpRecord || !Hash::check($request->otp, $otpRecord->otp_hash)) {
        return response()->json([
            'success' => false,
            'message' => 'OTP tidak valid atau sudah kedaluwarsa',
        ], 422);
    }

    return response()->json([
        'success' => true,
        'message' => 'OTP valid',
    ]);
}


        // Hapus token lama supaya tidak menumpuk

    // ─────────────────────────────────────────────
    // GET PROFILE (user yang sedang login)
    // ─────────────────────────────────────────────
    public function profile(Request $request)
    {
        return response()->json([
            'success' => true,
            'user'    => $request->user(),
        ]);
    }

    // ─────────────────────────────────────────────
    // UPDATE PROFILE
    // ─────────────────────────────────────────────
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'nama_lengkap'    => 'sometimes|string|max:255',
            'no_telepon'      => 'sometimes|nullable|string|max:20',
            'nama_peternakan' => 'sometimes|nullable|string|max:255',
            'lokasi'          => 'sometimes|nullable|string|max:255',
            'email'           => 'sometimes|email|unique:users,email,' . $user->id,
        ]);

        $user->update($request->only([
            'nama_lengkap',
            'email',
            'no_telepon',
            'nama_peternakan',
            'lokasi',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui',
            'user'    => $user->fresh(),
        ]);
    }

    // ─────────────────────────────────────────────
    // LOGOUT
    // ─────────────────────────────────────────────
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Berhasil keluar',
        ]);
    }
}