"""
Konfigurasi pytest untuk ternify-fastapi.
Menambahkan root project ke sys.path agar modul ocr_service bisa diimport.
"""
import sys
import os

# Tambahkan root project ke path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
