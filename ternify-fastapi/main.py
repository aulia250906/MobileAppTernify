from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import shutil
import os
import uuid
from ocr_service import process_form_image

app = FastAPI(
    title="Ternify OCR Microservice",
    description="API FastAPI untuk ekstraksi teks dari formulir domba menggunakan AI",
    version="1.0.0"
)

# CORS Configuration - Izinkan akses dari Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Dalam production, ganti dengan domain spesifik
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Direktori temporer untuk menyimpan gambar sementara sebelum di OCR
TEMP_DIR = "temp_images"
os.makedirs(TEMP_DIR, exist_ok=True)

@app.get("/")
def root():
    return {"message": "Ternify OCR API is running. Access /docs for Swagger UI.", "status": "online"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "Ternify OCR"}

@app.post("/api/v1/scan")
async def scan_document(file: UploadFile = File(...)):
    # 1. Validasi ekstensi
    allowed_extensions = ('.png', '.jpg', '.jpeg')
    if not file.filename.lower().endswith(allowed_extensions):
        raise HTTPException(status_code=400, detail="Format tidak didukung. Harap upload PNG atau JPG.")

    # 2. Simpan file sementara dengan nama unik (mencegah bentrok jika diakses banyak user)
    unique_filename = f"{uuid.uuid4().hex}_{file.filename}"
    file_path = os.path.join(TEMP_DIR, unique_filename)
    
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # 3. Jalankan pipeline OCR dari ocr_service.py
        ocr_result = process_form_image(file_path)

        # 4. Evaluasi hasil
        if not ocr_result["success"]:
            return JSONResponse(status_code=422, content=ocr_result)

        return JSONResponse(status_code=200, content=ocr_result)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Terjadi kesalahan di sisi server: {str(e)}")

    finally:
        # 5. Hapus file setelah selesai agar penyimpanan server tidak bocor (Memory/Disk Leak)
        if os.path.exists(file_path):
            os.remove(file_path)

if __name__ == "__main__":
    # Jalankan server
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)