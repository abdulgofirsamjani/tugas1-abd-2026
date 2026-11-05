# Eksplorasi dan Analisis Dataset Besar Indonesia

## Deskripsi dan tujuan

Proyek Tugas 1 Analisis Big Data ini memprofilkan, membersihkan, dan mengeksplorasi dataset **Indonesian News AZ**. Fokus analisis adalah kualitas data, perubahan jumlah berita bertanggal valid dari waktu ke waktu, panjang artikel, serta distribusi hostname sumber. Kesimpulan hanya berlaku pada cakupan dataset ini.

## Dataset

| Atribut | Informasi |
|---|---|
| Dataset | Indonesian News AZ, EstelerAI |
| Sumber | [Hugging Face: esteler-ai/idn-news-az](https://huggingface.co/datasets/esteler-ai/idn-news-az) |
| Format dan cakupan lokal yang diprofilkan | 441 file Parquet; 1.149.789 baris; 4 kolom; 1.558.347.901 byte |
| Kolom | `date`, `link`, `title`, `text` |
| Lisensi di halaman dataset | CC BY 4.0; tetap periksa kartu dataset dan atribusikan pembuat saat menggunakan atau membagikan data |
| Data mentah di Git | Tidak; unduh ke `data/raw/` sesuai petunjuk di [data/README.md](data/README.md) |

## Struktur repository

```text
.
|-- data/README.md
|-- notebooks/
|   |-- 01_data_profiling.ipynb
|   |-- 02_data_cleaning.ipynb
|   |-- 03_eda_and_insights.ipynb
|-- output/figures/          # enam HTML Plotly dan plotly.min.js lokal
|-- Dockerfile
|-- requirements.txt
|-- README.md
```

## Tools

Python, Polars (lazy Parquet scan dan transformasi), DuckDB (`SUMMARIZE` dan pembanding SQL), PyArrow, Pandas untuk jembatan ke Plotly, Plotly, JupyterLab, dan Docker.

## Milestone 1 - Data Profiling

[Notebook profiling](notebooks/01_data_profiling.ipynb) mencari file Parquet secara rekursif dari `data/raw/`, menggunakan `pl.scan_parquet()`, memeriksa schema, jumlah baris, null dan string kosong, duplikasi, parsing tanggal, panjang teks, domain, serta kandidat nilai ekstrem. Profiling yang tersimpan mencatat 1.149.789 baris dan rentang tanggal valid 2019-05-10 sampai 2023-10-01.

## Milestone 2 - Data Cleaning dan Data Quality

[Notebook cleaning](notebooks/02_data_cleaning.ipynb) menggunakan DuckDB `SUMMARIZE` dan Polars untuk transformasi. Tidak ditemukan null atau string kosong pada empat kolom sumber. Tanggal `NaT` tidak diimputasi; status tanggal dipertahankan dalam kolom terpisah. Kandidat outlier panjang judul/isi ditandai dengan aturan IQR, diperiksa, dan tidak otomatis dibuang.

Aturan deduplikasi mempertahankan satu baris per URL. Dari 1.149.789 baris, 120.304 baris URL berulang dikeluarkan sehingga tersisa 1.029.485 baris. Karena ada 86 grup URL dengan konflik isi/judul, aturan `keep='first'` dapat memilih satu versi di antara rekaman berbeda; ini merupakan keterbatasan yang perlu dipahami saat menafsirkan data. Tanggal invalid tersisa 101.403 baris dan baris bersih memiliki URL unik. Data mentah tidak ditimpa.

Output `data/processed/indonesian_news_az_clean.parquet` dipakai ulang hanya bila metadata fingerprint SHA-256 atas sumber dan versi aturan cleaning cocok. Untuk rebuild eksplisit, set `REBUILD_PROCESSED=1` sebelum menjalankan kernel/notebook. Hasil baru divalidasi sebagai file sementara sebelum menggantikan output terdahulu.

## Milestone 3 - Exploratory Data Analysis

[Notebook EDA](notebooks/03_eda_and_insights.ipynb) melakukan agregasi bulanan hanya pada tanggal valid. Data memiliki 22 bulan observasi dalam rentang kalender 54 bulan. Bulan kosong tidak disintesis. Moving average menggunakan tiga observasi bulan yang tersedia; `shift(1)` membandingkan observasi sebelumnya. Jumlah artikel di-cast ke `Int64` sebelum pengurangan agar delta penurunan tetap negatif. Perhitungan moving average Polars dan DuckDB dibandingkan dengan assert.

### Enam visualisasi interaktif

| Berkas | Isi |
|---|---|
| [01 Tren publikasi](output/figures/01_tren_publikasi.html) | Artikel per bulan observasi dan moving average tiga observasi |
| [02 Distribusi panjang artikel](output/figures/02_distribusi_panjang_artikel.html) | Histogram deterministik; tampilan sampai P99 |
| [03 Korelasi fitur](output/figures/03_korelasi_fitur.html) | Korelasi Pearson panjang judul dan isi |
| [04 Top 15 domain](output/figures/04_top_15_domain.html) | Hostname dengan artikel terbanyak |
| [05 Heatmap temporal](output/figures/05_heatmap_temporal.html) | Artikel bertanggal valid menurut bulan kalender dan hari |
| [06 Scatter multidimensi](output/figures/06_scatter_multidimensi.html) | Panjang judul dan isi pada sampel deterministik sekitar 0,5% |

Jalankan notebook 03 untuk memperbarui keenam HTML dari objek Plotly aktual. File HTML memuat referensi relatif ke `output/figures/plotly.min.js` agar bisa dibuka offline selama berkas JS tetap di folder yang sama.

### Lima insight berbasis hasil analisis

1. **Puncak publikasi teramati:** Agustus 2023 memiliki 117.163 artikel bertanggal valid, jumlah bulanan tertinggi. Moving average tiga bulan observasi Polars cocok dengan pembanding DuckDB (selisih maksimum 0).
2. **Cakupan waktu tidak merata:** hanya 22 dari 54 bulan kalender dalam rentang Mei 2019 sampai Oktober 2023 yang memiliki observasi bertanggal valid. Bulan yang tidak muncul tidak diisi nol dan tidak membuktikan tiadanya publikasi.
3. **Distribusi panjang isi berekor panjang:** median 2.134 karakter dan P99 7.145 karakter; 10.293 baris melampaui P99. Histogram hanya visualisasi sampel dan dibatasi sampai P99 agar bagian utama terbaca.
4. **Hubungan panjang judul dan isi lemah:** korelasi Pearson `r = 0,126` pada 1.029.485 baris. Korelasi ini tidak membuktikan sebab-akibat atau mutu berita.
5. **Sumber dan kualitas tanggal perlu dipantau:** `tribunnews.com` adalah hostname teratas dengan 107.817 artikel (10,47% dari 1.029.485 URL ber-hostname terdeteksi); Selasa memiliki hitungan tertinggi untuk tanggal valid (155.745). Selain itu, 101.403 baris (9,85%) tidak memiliki tanggal kalender valid dan dipertahankan tanpa imputasi.

Angka ini berasal dari eksekusi ulang notebook EDA pada output cleaning lokal. Hasil dibatasi pada cakupan dataset; hostname bukan verifikasi independen penerbit, hitungan weekday dipengaruhi cakupan sumber, dan sampel grafik tidak digunakan untuk menghitung angka populasi.

## Mendapatkan dataset

Ikuti petunjuk dan atribusi pada [data/README.md](data/README.md). Unduhan mengambil berkas Parquet sumber ke `data/raw/` dan tidak mengubahnya. Dataset mentah berukuran besar sengaja tidak dimasukkan ke Git. Commit/revision Hugging Face untuk salinan lokal yang dianalisis tidak tercatat sehingga ID revisi sumber belum dapat dibuktikan. Untuk unduhan berikutnya, catat commit/revision dan pasang nilainya pada parameter `revision`; tanpa revision, sumber default dapat berubah.

## Instalasi lokal

Gunakan Python 3.12 dan PowerShell dari root repository:

```powershell
py -3.12 -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Setelah data tersedia, jalankan notebook di urutan 01, 02, lalu 03. Notebook menemukan root project dari direktori kerja saat ini atau induknya.

## Docker dan JupyterLab

Build image:

```powershell
docker build -t tugas1-bigdata .
```

Jalankan dengan bind mount repository. Port hanya dipublikasikan ke localhost; token/password Jupyter dinonaktifkan hanya untuk pengembangan lokal. Jangan mengekspos port ini ke jaringan publik.

```powershell
docker run --rm -p 127.0.0.1:8888:8888 -v "${PWD}:/home/jovyan/work" tugas1-bigdata
```

Buka `http://localhost:8888/lab`. Folder kerja container adalah `/home/jovyan/work`, sementara notebook mencari root yang berisi folder `data/`. Notebook dijalankan satu per satu dari urutan 01, 02, lalu 03.

## Hasil validasi dan batasan

Hasil lokal yang tercatat: 1.149.789 baris mentah, 1.029.485 baris setelah deduplikasi URL, 928.082 tanggal valid, 101.403 tanggal invalid; rentang tanggal valid 2019-05-10 sampai 2023-10-01. Analisis temporal mengecualikan tanggal invalid. Grafik histogram dan scatter menggunakan sampel deterministik; angka inferensial tidak diambil dari sampel tersebut. Hostname URL tidak memverifikasi identitas penerbit, data tidak merata menurut sumber/waktu, dan korelasi panjang tidak menyatakan kausalitas atau mutu berita.

## Reproduktivitas

1. Unduh Parquet ke `data/raw/` dengan panduan data.
2. Jalankan notebook profiling.
3. Jalankan notebook cleaning; cache hanya digunakan jika fingerprint sumber dan aturan cocok. Untuk rebuild, set variabel `REBUILD_PROCESSED=1`.
4. Jalankan notebook EDA untuk menghitung ulang hasil dan mengekspor grafik.
5. Bandingkan keluaran dan perhatikan batasan tanggal invalid serta konflik URL.

## AI Disclosure Statement

**Draf yang perlu diperiksa dan dikonfirmasi oleh pemilik repository sebelum submission:** AI digunakan untuk membantu audit kode dan dokumentasi, debugging serta revisi kode, pemeriksaan kesesuaian dengan rubrik, dan penyusunan/revisi README. Pemilik repository perlu menjalankan notebook, memeriksa hasil aktual, memastikan pemahaman atas seluruh perubahan, dan menyesuaikan pernyataan ini agar tepat menggambarkan bantuan yang digunakan. Pernyataan ini tidak mengklaim verifikasi manual atas aspek yang belum diuji.

## Referensi dan atribusi

EstelerAI, [Indonesian News AZ](https://huggingface.co/datasets/esteler-ai/idn-news-az), Hugging Face Datasets, DOI: `10.57967/hf/1474`, lisensi sebagaimana dicantumkan pada kartu dataset (CC BY 4.0 saat audit dokumentasi). Sertakan atribusi pembuat dan periksa ketentuan dataset sebelum mendistribusikan ulang.
