@echo off
title Eloqua NLP Dev Environment

echo ================================
echo Cleaning old processes...
echo ================================

taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM uvicorn.exe >nul 2>&1
taskkill /F /IM ngrok.exe >nul 2>&1

timeout /t 2 >nul

echo ================================
echo Starting Main Backend (port 8000)...
echo ================================
start "Main API" cmd /k "cd /d F:\NLP - Eloqua\eloqua-backend && venv\Scripts\activate && uvicorn main:app --host 0.0.0.0 --port 8000"

timeout /t 5 >nul

echo ================================
echo Starting Body Service (port 8001)...
echo ================================
start "Body API" cmd /k "cd /d F:\NLP - Eloqua\eloqua-body && venv\Scripts\activate && uvicorn main_body:app --host 0.0.0.0 --port 8001"

timeout /t 6 >nul

echo ================================
echo Starting Ngrok tunnel...
echo ================================
start "Ngrok API" cmd /k "ngrok http 8000"

echo.
echo ================================
echo Everything is starting!
echo Copy your Ngrok URL from the terminal and update your Flutter app.
echo ================================
pause
