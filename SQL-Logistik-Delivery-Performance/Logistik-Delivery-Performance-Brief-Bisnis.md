# Brief — Logistik & Delivery Performance (Kirim.in)

**Level:** 2 — Intermediate
**Tools target:** SQL (schema ternormalisasi, 4 tabel, butuh JOIN)
**Mode:** Portfolio

## Latar Belakang

Kirim.in adalah startup jasa pengiriman last-mile yang bekerja sama dengan merchant online (fashion, grocery, elektronik, F&B, dll) untuk antar barang ke pelanggan di 4 kota: Jakarta, Surabaya, Bandung, dan Makassar. Model bisnisnya: merchant kirim paket ke gudang Kirim.in, lalu driver Kirim.in yang antar ke alamat pelanggan.

Kamu dihubungi oleh **Bimo**, Operations Manager Kirim.in. Dia baru pindah dari tim lain dan belum sepenuhnya pegang detail operasional harian. Dari beberapa kali chat dengannya, ini yang dia sampaikan:

> "Belakangan ada beberapa komplain merchant soal keterlambatan, tapi aku belum tahu persis di mana masalahnya — apakah di kotanya, drivernya, atau memang SLA yang kita janjikan ke merchant kebanyakan nggak realistis. Tolong bantu aku lihat data pengiriman kita, cari tahu performanya gimana, dan kasih rekomendasi."

## Data yang Tersedia

Kamu dapat 4 tabel dari sistem Kirim.in (folder `data/`):
- `merchants.csv` — daftar merchant partner, kategori bisnis, dan SLA (jam) yang dijanjikan kontrak dari pickup sampai delivered
- `drivers.csv` — daftar driver, kota penempatan, jenis kendaraan
- `orders.csv` — order dari merchant, termasuk kota tujuan pelanggan dan tanggal janji kirim ke pelanggan (`promised_delivery_date`)
- `deliveries.csv` — proses pengiriman aktual: driver yang menangani, waktu pickup, waktu delivered, status, dan nomor percobaan (`attempt_number`, karena ada pengiriman yang gagal lalu diulang)

Data ini mencakup periode November 2025 – Agustus 2026.

## Yang Perlu Kamu Gali Sendiri

Brief dari Bimo sengaja belum lengkap — di dunia kerja beneran, requirement jarang datang rapi. Beberapa hal yang perlu kamu klarifikasi sendiri (chat sama Bimo lewat mode Discovery, lihat cara kerjanya di bagian bawah):

- Bimo menyebut kata "SLA" dan "janji ke pelanggan" agak bercampur waktu ngobrol — coba gali, karena di data ada dua definisi waktu yang berbeda (SLA jam dari pickup vs tanggal janji ke pelanggan), dan itu bisa menghasilkan kesimpulan yang beda.
- Dia belum bilang jelas laporan ini nanti dipakai buat apa (bahan keputusan hire driver? renegosiasi SLA ke merchant? evaluasi performa driver individual?) — itu akan menentukan sudut analisis mana yang paling penting untuk ditekankan.
- Constraint budget/operasional (misalnya kalau harus nambah driver, apakah dia bisa nambah di semua kota atau cuma satu kota) belum disebutkan — tanyakan kalau relevan sama pertanyaan yang kamu kerjakan.

## Disclosure Data

Dataset ini adalah data simulasi, dibuat untuk keperluan portofolio, dirancang menyerupai pola bisnis logistik last-mile Indonesia agar analisisnya realistis. Bukan data perusahaan asli — nama "Kirim.in" dan semua merchant di dalamnya fiktif.

## Cara Aku Mendampingi Kamu

Aku akan ganti mode sesuai tahap kamu, tapi **kamu yang bilang eksplisit** kapan pindah tahap:

- **Discovery** (sekarang) — aku roleplay jadi Bimo. Tanya apa saja soal requirement, aku jawab sebagai stakeholder yang tahu bisnisnya tapi belum tahu jawaban analisisnya.
- **Kerja** — begitu kamu bilang "aku mulai kerja", aku bisa bantu hal teknis (debug SQL, jelasin error, review query), tapi nggak akan kasih kesimpulan insight bisnis.
- **Review** — begitu kamu bilang "aku udah selesai, cocokin dong", baru aku buka panduan insight di `_jawaban/` dan kita bandingkan sama temuan kamu. Di tahap ini juga kita isi bareng kartu portofolionya.
