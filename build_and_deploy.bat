@echo off
setlocal

set "ROOT_DIR=%~dp0"
set "FLUTTER_DIR=%ROOT_DIR%flutter_app"
set "BUILD_DIR=%FLUTTER_DIR%\build\web"
set "TARGET_DIR=%ROOT_DIR%backend\public"

echo [1/3] Building Flutter web release bundle...
pushd "%FLUTTER_DIR%" || goto :error
call flutter build web --release --web-renderer html
if errorlevel 1 (
	echo Detected Flutter version without --web-renderer support. Retrying without renderer flag...
	call flutter build web --release
	if errorlevel 1 goto :error_popd
)
popd

echo [2/3] Replacing backend public directory...
if exist "%TARGET_DIR%" rmdir /S /Q "%TARGET_DIR%"
mkdir "%TARGET_DIR%" || goto :error

echo [3/3] Copying build artifacts to backend\public...
xcopy "%BUILD_DIR%\*" "%TARGET_DIR%\" /E /I /Y >nul
if errorlevel 2 goto :error

echo.
echo Build and deploy complete.
echo Start backend with: cd backend ^&^& node index.js
goto :done

:error_popd
popd

:error
echo.
echo Build and deploy failed.
exit /b 1

:done
endlocal
exit /b 0
