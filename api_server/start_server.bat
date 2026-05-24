@echo off
echo ============================================================
echo   Forever Young ML API Server
echo   Model                 : YOLOv11m + PARSeq (CUDA/CPU)
echo   Env                   : yolo-parseq (miniconda3)
echo   Label Format Output   : DD/MM/YYYY / MM/YYYY / not detected
echo ============================================================
echo.
echo [*] Memuat YOLOv11m + PARSeq... (10-30 detik)
echo.

:: Pindah ke folder api_server (lokasi main.py ini)
cd /d "%~dp0"

:: Python dari conda env yolo-parseq
set PYTHON=C:\Users\Reynaldi\miniconda3\envs\yolo-parseq\python.exe

if not exist "%PYTHON%" (
    echo [ERROR] Python tidak ditemukan di: %PYTHON%
    echo Pastikan conda env 'yolo-parseq' sudah dibuat.
    pause
    exit /b 1
)

echo [*] Server berjalan di: http://0.0.0.0:8000
echo [*] Tekan Ctrl+C untuk menghentikan server
echo.

%PYTHON% -m uvicorn main:app --host 0.0.0.0 --port 8000

echo.
echo [*] Server berhenti.
pause
