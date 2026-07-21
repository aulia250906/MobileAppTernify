# 1. Gunakan image Python versi 3.10 yang ringan sebagai sistem operasi dasar
FROM python:3.10-slim

# 2. Instal Tesseract OCR, paket bahasa Indonesia, dan dependensi sistem untuk OpenCV
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    tesseract-ocr-ind \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 3. Tentukan folder kerja utama di dalam server
WORKDIR /app

# 4. Salin file requirements.txt dari komputer Anda ke server
COPY requirements.txt .

# 5. Instal semua library Python yang dibutuhkan (FastAPI, pytesseract, opencv, dll)
RUN pip install --no-cache-dir -r requirements.txt

# 6. Salin seluruh file kode Python/FastAPI Anda ke dalam server
COPY . .

# 7. Jalankan server Uvicorn dengan port dinamis dari Railway
CMD sh -c "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"