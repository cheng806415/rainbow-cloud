$ErrorActionPreference = "Continue"
$OutputFile = "d:\Develop\weihu\flutter_build_output.txt"

"Starting Flutter setup..." | Tee-Object -FilePath $OutputFile

Set-Location d:\Develop\weihu\client

$env:Path = "C:\flutter\bin;$env:Path"

"Running flutter --version..." | Tee-Object -FilePath $OutputFile -Append
flutter --version 2>&1 | Tee-Object -FilePath $OutputFile -Append

"Running flutter pub get..." | Tee-Object -FilePath $OutputFile -Append
flutter pub get 2>&1 | Tee-Object -FilePath $OutputFile -Append

"Done." | Tee-Object -FilePath $OutputFile -Append
