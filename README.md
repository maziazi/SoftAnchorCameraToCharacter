# Sistem Kamera Soft Anchor

Sistem kamera pintar yang mengikuti karakter dengan interpolasi halus dan kontrol gesture yang mudah.

## Gambaran Umum

Sistem ini menyediakan 2 mode kamera dengan sudut pandang dari depan karakter (0 derajat):

- Mode Follow: Kamera mengikuti karakter secara otomatis
- Mode Overview: Kamera bebas untuk melihat keseluruhan scene

## Kontrol Gesture

### Gesture Dasar

| Gesture | Fungsi | Penjelasan |
|---------|--------|------------|
| Tap Sekali | Pilih objek | Tap karakter untuk set sebagai target |
| Tap Dua Kali | Ganti mode kamera | Follow ke Overview atau sebaliknya |
| Pan 1 Jari | Putar kamera | Rotasi horizontal dan vertikal |
| Pan 2 Jari | Geser kamera | Pindah posisi kamera |
| Pinch | Zoom | Perbesar atau perkecil view |
| Rotate | Putar objek | Putar objek yang dipilih |

### Kontrol Per Mode

#### Mode Follow
- Pan 1 Jari: Kontrol manual sementara (auto-resume 2 detik)
- Pan 2 Jari: Geser posisi follow
- Pinch: Zoom (1-20 unit)

#### Mode Overview
- Pan 1 Jari: Rotasi bebas
- Pan 2 Jari: Geser kamera bebas
- Pinch: Zoom (2-50 unit)

## Teknologi Soft Anchor

### Cara Kerja
Kamera mengikuti karakter dengan interpolasi halus menggunakan formula:
```
Posisi Baru = Posisi Sekarang + (Target - Sekarang) x Smoothness
```

### Parameter Utama

#### Smoothness (Kelembutan)
| Nilai | Kecepatan | Penggunaan |
|-------|-----------|------------|
| 0.01 | Sangat halus | Film, sinematik |
| 0.03 | Halus | Presentasi |
| 0.05 | Seimbang (Default) | Penggunaan umum |
| 0.08 | Responsif | Game aksi |
| 0.1+ | Sangat cepat | Real-time |

#### Offset (Posisi Relatif)
```swift
SIMD3<Float>(X, Y, Z)
```
- X: Kiri (negatif) / Kanan (positif)
- Y: Bawah (negatif) / Atas (positif)
- Z: Negatif = Depan karakter (untuk front view)

## Konfigurasi

### Setting Aktif
```swift
// Mode Follow - Depan karakter
private let followSmoothness: Float = 0.05
private let followOffset: SIMD3<Float> = SIMD3<Float>(0, 3, -4)
```

### Preset Siap Pakai

#### Default (Aktif)
```swift
smoothness: 0.05, offset: (0, 3, -4)
// View depan seimbang, sedikit tinggi
```

#### Close-up
```swift
smoothness: 0.08, offset: (0, 2, -2.5)
// Dekat dan responsif
```

#### Sinematik
```swift
smoothness: 0.03, offset: (0, 4, -5)
// Halus dan tinggi
```

### Cara Ganti Preset
1. Buka CanvasView.swift
2. Comment preset aktif
3. Uncomment preset yang diinginkan
4. Build ulang

## Penggunaan Cepat

### Untuk Film/Presentasi
```swift
private let followSmoothness: Float = 0.01
private let followOffset: SIMD3<Float> = SIMD3<Float>(0, 4, -6)
```

### Untuk Game
```swift
private let followSmoothness: Float = 0.08
private let followOffset: SIMD3<Float> = SIMD3<Float>(0, 2, -3)
```

### Untuk Tur Virtual
```swift
private let followSmoothness: Float = 0.03
private let followOffset: SIMD3<Float> = SIMD3<Float>(0, 3, -4)
```

## Panduan Offset

### Posisi Kamera (Z Negatif = Depan)

| Offset | Posisi | Penggunaan |
|--------|--------|------------|
| (0, 2, -2) | Depan dekat | Detail view |
| (0, 3, -4) | Depan standard (Default) | Penggunaan umum |
| (0, 4, -6) | Depan jauh | Wide view |
| (-2, 3, -3) | Depan kiri | Angle view |
| (0, 6, -3) | Depan atas | Overhead |

## Mode Kamera Detail

### Mode Follow (Mengikuti)
- Sudut: 0 derajat (Depan karakter)
- Behavior: Auto-follow dengan soft anchor
- Kontrol: Gesture sementara, auto-resume
- Zoom Range: 1-20 unit

### Mode Overview (Bebas)
- Sudut: Kontrol manual penuh
- Behavior: Free camera movement
- Kontrol: Manual rotasi dan posisi
- Zoom Range: 2-50 unit

## Troubleshooting

### Kamera Tidak Mengikuti
- Cek target: Tap karakter untuk set target
- Cek mode: Double-tap untuk switch ke Follow
- Cek enable: Pastikan follow aktif

### Gerakan Patah-patah
- Naikkan smoothness (0.03 ke 0.05)
- Kurangi update frequency
- Restart aplikasi

### Sudut Salah
- Double-tap untuk reset mode
- Cek offset configuration
- Pastikan Z negatif untuk depan

## Shortcut Penting

| Aksi | Cara |
|------|------|
| Ganti mode | Double-tap layar |
| Set target | Tap karakter |
| Zoom | Pinch gesture |
| Rotasi | Pan 1 jari |
| Geser | Pan 2 jari |

## Kesimpulan

Sistem kamera ini memberikan:
- 2 mode kamera dengan kontrol mudah
- Smooth following dengan teknologi soft anchor
- Gesture intuitif untuk semua kontrol
- Konfigurasi fleksibel via preset
- Performance optimal untuk semua device
- Sudut depan konsisten (0 derajat) untuk pengalaman natural

Tips: Mulai dengan setting default (smoothness 0.05, offset (0,3,-4)) lalu sesuaikan berdasarkan kebutuhan content Anda.

---

Untuk support teknis, lihat dokumentasi project atau buat issue di repository.
