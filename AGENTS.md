# AI Agent Guidelines & Technical Instructions — Langkah App

Dokumen ini adalah **pedoman teknis mutlak (Ground Truth)** bagi seluruh AI Agent (Antigravity/LLM) yang bekerja, menulis kode, memodifikasi arsitektur, dan merefaktor repositori aplikasi **Langkah**.

---

## 1. Aturan Peran & Batasan Mutlak AI Agent

1. **Strict 3 Pillars Navigation**:
   - **DILARANG KERAS** menambah menu/tab navigasi utama baru di luar 3 pilar yang telah disepakati:
     1. `Home` (Beranda Eksekusi & Langkah Hari Ini)
     2. `Planner` (Perencanaan Mingguan/Bulanan & Backlog)
     3. `Settings` (Profil, Streak/Statistik, Preferensi Tema)
   - Fitur baru **harus** diintegrasikan ke dalam salah satu dari ketiga pilar di atas (misal: widget Pomodoro berada di Home, target mingguan di Planner).

2. **Standard Backend & Auth Provider**:
   - Backend resmi adalah **Supabase**. Seluruh operasi autentikasi dan database wajib menggunakan `supabase_flutter`.
   - Dilarang menginstal Firebase, AWS Amplify, atau backend lain tanpa persetujuan eksplisit.

3. **Verifikasi Sebelum Mengubah**:
   - Jangan pernah menghapus file kode lama tanpa membaca isi dependensinya terlebih dahulu.
   - Jalankan `flutter analyze` dan `flutter test` setelah setiap perubahan modul besar untuk menjamin *0 error & 0 warning*.

---

## 2. Standar Arsitektur & Struktur Folder

Aplikasi menggunakan pendekatan **Feature-First Clean Architecture** yang modular, terisolasi, dan mudah di-maintain.

```
lib/
├── core/
│   ├── constants/         # AppColors, AppTextStyles, AppDimensions
│   ├── network/           # SupabaseClientInstance, API endpoints
│   ├── theme/             # Light & Dark ThemeData (Material 3)
│   ├── utils/             # Formatters, DateHelpers, Validators
│   └── widgets/           # Global reusable widgets (buttons, inputs, loaders)
├── features/
│   ├── auth/              # Login, Register OTP, Forgot Password OTP
│   │   ├── data/          # AuthRepositoryImpl, AuthRemoteDataSource
│   │   ├── domain/        # AuthRepository interface, UserModel
│   │   └── presentation/  # Screens, Widgets, AuthViewModel
│   ├── home/              # Beranda, Today's Steps, Contextual Mini Widgets
│   │   ├── data/          # DailyTasksRepository, StatsRepository
│   │   ├── domain/        # DailyTask, Category, UserStats
│   │   └── presentation/  # HomeScreen, StepCard, PomodoroWidget, HomeViewModel
│   ├── planner/           # Weekly/Monthly Planner, Backlog Pool
│   │   ├── data/          # PlannerRepository
│   │   ├── domain/        # MonthlyGoal, WeeklyTarget, BacklogItem
│   │   └── presentation/  # PlannerScreen, WeeklyBoard, BacklogSheet, PlannerViewModel
│   └── settings/          # Profile, Stats Dashboard, Theme Switcher
│       ├── data/          # ProfileRepository
│       ├── domain/        # ProfileModel, StreakData
│       └── presentation/  # SettingsScreen, SettingsViewModel
└── main.dart              # Entry point, Supabase initialization, AuthGate
```

---

## 3. Aturan Koding & Best Practices

1. **Model Imutabilitas**:
   - Semua entitas domain wajib bersifat **immutable** (`@immutable` atau menggunakan `const` constructor dan metode `copyWith`).
   - Sertakan `toMap()` dan `fromMap(Map<String, dynamic>)` yang aman terhadap nilai `null`.

2. **State Management**:
   - Gunakan `ChangeNotifier` / `Provider` yang sudah terpasang di `pubspec.yaml`.
   - Pisahkan logika bisnis dari UI. Widget tidak boleh langsung melakukan panggilan query Supabase mentah; gunakan Repository dan ViewModel.

3. **Error Handling & Feedback**:
   - Setiap operasi asinkron (login, submit task, delete) wajib menangani state: `initial`, `loading`, `success`, dan `failure`.
   - Tampilkan pesan error ramah pengguna menggunakan `SnackBar` atau `AdaptiveBanner`, hindari menampilkan raw stack trace ke pengguna.

4. **Kemandirian User (Multi-User RLS Ready)**:
   - Saat melakukan query `INSERT`, selalu pastikan `user_id` diisi dengan `supabase.auth.currentUser!.id`.
   - Jangan pernah melakukan *bypass* security check di level klien.

---

## 4. Urutan Eksekusi Bertahap (Phased Roadmap)

Setiap sesi pengembangan bersama AI Agent wajib mengikuti tahapan bertahap berikut:

### Phase 1: Inisialisasi Supabase & Alur Autentikasi
1. Pasang dependensi `supabase_flutter`.
2. Buat `core/network/supabase_config.dart` (URL & Anon Key aman).
3. Bangun `AuthGate` di `main.dart` (otomatis switch antara Auth Screen vs Main Navigation).
4. Implementasi Register Flow (Input data -> Kirim Email OTP -> Verifikasi OTP -> Auto Login).
5. Implementasi Login Flow (Email + Password) & Validasi Form.
6. Implementasi Forgot Password Flow (Input email -> OTP recovery -> Reset password).

### Phase 2: Kerangka 3 Pilar & Slicing UI
1. Buat `MainNavigationScreen` (Bottom Navigation Bar mengontrol Home, Planner, Settings).
2. Slicing **Home Screen**:
   - Header tanggal & status ringkasan harian.
   - List tugas harian dengan checkbox & badge kategori.
   - Floating Action Button (+) dengan modal input cepat.
3. Slicing **Planner Screen**:
   - Toggle tampilan Weekly / Monthly.
   - Kartu Goals & Target mingguan.
   - Bottom sheet / tab untuk Backlog Pool.
4. Slicing **Settings Screen**:
   - Ringkasan profil user aktif.
   - Statistik streak & total langkah.
   - Switcher Dark / Light mode & Tombol Logout.

### Phase 3: Integrasi Data Supabase & Interaktivitas
1. Hubungkan `daily_tasks` CRUD dengan Supabase Realtime / FutureProvider.
2. Hubungkan `categories` selector dan filter tag warna.
3. Hubungkan `monthly_goals`, `weekly_targets`, dan `backlog_items`.
4. Implementasikan auto-update streak di `user_stats` saat seluruh langkah hari ini terselesaikan.
5. Sematkan widget mikro kontekstual: Mini Pomodoro Timer di Home Screen.
