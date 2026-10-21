# Data Tugas 1

## Dataset yang Dipilih

| Item | Isi |
|---|---|
| Nama dataset | Indonesian News AZ |
| Sumber | [esteler-ai/idn-news-az di Hugging Face](https://huggingface.co/datasets/esteler-ai/idn-news-az) |
| Format asli | Parquet |
| Lisensi/ketentuan pakai | Halaman resmi Hugging Face mencantumkan lisensi **CC BY 4.0**. Atribusikan dataset kepada pembuatnya dan periksa ketentuan lisensi sebelum penggunaan atau distribusi. |
| Ukuran | 441 file Parquet; 1.149.789 baris; 4 kolom; 1.558.347.901 byte (sekitar 1,56 GB) |
| Rentang tanggal valid teramati | 2019-05-10 sampai 2023-10-01 |
| Unit analisis | Satu artikel berita digital berbahasa Indonesia per baris. |

Deskripsi kolom berdasarkan skema Parquet:

| Kolom | Deskripsi |
|---|---|
| `date` | Nilai tanggal yang dicatat untuk artikel. |
| `link` | URL sumber artikel. |
| `title` | Judul artikel berita. |
| `text` | Teks atau isi artikel berita. |

Profiling awal pada salinan lokal menemukan 101.421 nilai pada `date` yang gagal diparsing dengan format `%Y-%m-%d`. Ini hanya menyatakan kegagalan parsing; nilai tersebut belum dapat disebut kosong atau rusak tanpa pemeriksaan lebih lanjut. Pada profiling awal yang sama, jumlah null pada `link`, `title`, dan `text` adalah 0. Hasil pemeriksaan duplikasi dan outlier belum dicatat di sini.

## Tempat Mencari Dataset

Dataset dipublikasikan oleh EstelerAI pada [Hugging Face Datasets](https://huggingface.co/datasets/esteler-ai/idn-news-az). Halaman resmi mencantumkan format Parquet, bahasa Indonesian, sekitar 1,15 juta baris, ukuran 1,56 GB, dan lisensi CC BY 4.0. Periksa kembali halaman sumber untuk metadata dan ketentuan terbaru.

## Cara Memperoleh Data

Salinan yang digunakan dalam tugas ini berada di `data/raw/`. Untuk mengunduh ulang file Parquet dari repository dataset, jalankan perintah berikut dari root repository. `snapshot_download()` mengambil berkas Parquet pada jalur `data_files/` dan mempertahankan struktur jalurnya di bawah `data/raw/` (sehingga file berada di `data/raw/data_files/`). Perintah ini mengunduh file mentah tanpa konversi atau transformasi.

Pasang dependensi jika belum tersedia:

```bash
python -m pip install huggingface_hub polars
```

Unduh 441 file Parquet:

```python
from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="esteler-ai/idn-news-az",
    repo_type="dataset",
    local_dir="data/raw",
    allow_patterns="data_files/*.parquet",
)
```

Contoh membaca semua file secara lazy dengan Polars:

```python
from pathlib import Path
import polars as pl

parquet_files = sorted(Path("data/raw").rglob("*.parquet"))
news = pl.scan_parquet([str(path) for path in parquet_files])

# Operasi tetap lazy sampai hasil dibutuhkan.
preview = news.select("date", "title").limit(5).collect()
print(preview)
```

`scan_parquet()` membangun rencana pemrosesan lazy; data baru dibaca saat operasi seperti `collect()` dijalankan. Bila diperlukan pengunduhan yang terikat pada versi tertentu, isi parameter `revision` dengan commit ID dataset yang telah dicatat. Tanpa parameter tersebut, Hugging Face mengunduh versi terbaru.

## Aturan Penyimpanan

- Jangan commit dataset mentah atau file ZIP berukuran besar ke GitHub. Folder `data/raw/` diabaikan oleh Git sesuai `.gitignore`.
- File pada `data/raw/` adalah salinan data asli; jangan mengubah, membersihkan, atau menimpa file tersebut.
- Simpan data hasil cleaning dan transformasi yang dapat direproduksi pada `data/processed/`.
- Catat sumber, versi/commit dataset bila tersedia, dan langkah pemrosesan yang dilakukan.
