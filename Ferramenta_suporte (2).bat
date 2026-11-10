@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Ferramenta suporte - Wesley Gomes

rem ============================================================
rem Ferramenta suporte | Autor: Wesley Gomes | Licenca MIT
rem Requer Windows 10/11. NAO exige Administrador: opcoes [ADM] so funcionam se aberto como admin.
rem ============================================================
set "VERSAO=1.1.0-sem-adm"
set "URL_CHAMADO=https://github.com"
set "GITHUB_REPO=https://github.com"
set "DATA_DIR=%LOCALAPPDATA%\FerramentaSuporte"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" >nul 2>&1
set "LOG_FILE=%DATA_DIR%\painel_log.txt"
set "IS_ADMIN=0"
fltmc >nul 2>&1 && set "IS_ADMIN=1"
set "MODO=Usuario padrao (sem ADM)"
if "%IS_ADMIN%"=="1" set "MODO=Administrador"

color 0B
:MENU
cls
echo ============================================================
echo                 FERRAMENTA SUPORTE
echo                    Wesley Gomes
echo ============================================================
echo Versao: %VERSAO%
echo Modo: %MODO%
echo Log: %LOG_FILE%
echo Chamados: %URL_CHAMADO%
echo ------------------------------------------------------------
echo  1. Limpeza de arquivos temporarios
echo  2. Limpeza de disco ^(cleanmgr^)
echo  3. Esvaziar Lixeira
echo  4. Verificar arquivos do Windows ^(SFC^) [ADM]
echo  5. Reparar imagem do Windows ^(DISM^) [ADM]
echo  6. Verificar disco ^(CHKDSK online^) [ADM]
echo  7. Resetar Windows Update [ADM]
echo  8. Informacoes e configuracao de rede
echo  9. Reset de rede ^(Winsock/IP^) [ADM]
echo 10. Teste de conectividade ^(ping^)
echo 11. Teste de velocidade ^(navegador^)
echo 12. Informacoes do sistema ^(msinfo32^)
echo 13. Gerenciador de Dispositivos
echo 14. Processos em execucao
echo 15. Consultar servicos
echo 16. Atualizar politicas ^(gpupdate^)
echo 17. Resultado de politicas ^(gpresult^)
echo 18. Espaco livre dos discos
echo 19. Dispositivos USB conectados
echo 20. Uso de CPU
echo 21. Memoria RAM
echo 22. Status do Microsoft Defender
echo 23. Backup / limpeza de logs de eventos ^(limpar: [ADM]^)
echo 24. Atualizacoes disponiveis ^(winget^)
echo 25. Atualizar todos os pacotes ^(winget^)
echo 26. Baixar arquivo via HTTPS e calcular SHA256
echo 27. Abrir Prompt de Comando
echo 28. Submenu de memoria e processos
echo 29. Abrir interface web ^(Streamlit^)
echo ------------------------------------------------------------
echo  U. Abrir repositorio GitHub
echo 99. Trocar cor do painel
echo  0. Sair
echo ============================================================
set "OPCAO="
set /p "OPCAO=Selecione uma opcao: "
if not defined OPCAO goto MENU
if /i "%OPCAO%"=="U" goto EXP_U
if "%OPCAO%"=="0" goto SAIR
if "%OPCAO%"=="99" goto EXP_99
rem Delayed expansion evita que caracteres digitados sejam interpretados como comandos.
setlocal EnableDelayedExpansion
echo(!OPCAO!| %SystemRoot%\System32\findstr.exe /r /x "\(1\|2\|3\|4\|5\|6\|7\|8\|9\|10\|11\|12\|13\|14\|15\|16\|17\|18\|19\|20\|21\|22\|23\|24\|25\|26\|27\|28\|29\)" >nul
if errorlevel 1 (endlocal & goto INVALIDA)
endlocal
goto EXP_%OPCAO%

:INVALIDA
echo.
echo [AVISO] Entrada invalida. Use um numero do menu, U ou 99.
pause
goto MENU

:INFO
cls
echo ============================================================
echo %TITULO%
echo ============================================================
echo O que faz: %DESCRICAO%
echo Tempo estimado: %TEMPO%
echo Afeta arquivos pessoais: %PESSOAIS%
echo.
echo 1 = Sim / 0 = Voltar
set "INFO_OP="
set /p "INFO_OP=Continuar? "
if "%INFO_OP%"=="1" exit /b 0
if "%INFO_OP%"=="0" exit /b 1
echo Entrada invalida.
pause
exit /b 1

:CONFIRMAR
echo.
set "RESPOSTA="
set /p "RESPOSTA=Confirma a execucao? (S/N): "
if /i "%RESPOSTA%"=="S" exit /b 0
if /i "%RESPOSTA%"=="N" exit /b 1
echo Resposta invalida. Operacao cancelada.
exit /b 1

:LOG
>>"%LOG_FILE%" echo [%date% %time%] %~1
exit /b

:REQ_ADM
if "%IS_ADMIN%"=="1" exit /b 0
echo.
echo [AVISO] Esta opcao exige Administrador e o painel esta em modo usuario padrao.
echo Abra o painel como administrador (se autorizado) ou acione o responsavel de TI.
call :LOG "Opcao bloqueada: exige ADM"
pause
exit /b 1

:LIXEIRA_USUARIO
set "SID="
for /f "tokens=2 delims=," %%S in ('whoami /user /fo csv /nh') do set "SID=%%~S"
if not defined SID (
    echo [ERRO] Nao foi possivel identificar o usuario atual.
    exit /b 1
)
rd /s /q "%SystemDrive%\$Recycle.Bin\%SID%" >nul 2>&1
exit /b 0

:DISCO
set "LIVRE="
set "GB="
for /f "tokens=3" %%B in ('dir /-c %1:\ 2^>nul') do set "LIVRE=%%B"
if not defined LIVRE exit /b 0
set "T=0000000000%LIVRE%"
set "GBP=%T:~0,-9%"
for /f "tokens=* delims=0" %%G in ("%GBP%") do set "GB=%%G"
if not defined GB set "GB=0"
echo Unidade %1: livre aprox. %GB% GB ^(%LIVRE% bytes^)
exit /b 0

:EXP_1
set "TITULO=Limpeza de arquivos temporarios"
set "DESCRICAO=Remove o conteudo da pasta TEMP do usuario (e do Windows, somente como ADM)."
set "TEMPO=1 a 5 minutos"
set "PESSOAIS=Sim, somente arquivos temporarios; feche aplicativos antes."
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "Limpeza de temporarios confirmada"
echo Limpando %TEMP% ...
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%~fD" >nul 2>&1
if "%IS_ADMIN%"=="1" (
    echo Limpando %WINDIR%\Temp ...
    del /f /s /q "%WINDIR%\Temp\*" >nul 2>&1
    for /d %%D in ("%WINDIR%\Temp\*") do rd /s /q "%%~fD" >nul 2>&1
) else (
    echo [INFO] %WINDIR%\Temp ignorado: exige Administrador.
)
echo Concluido. Arquivos em uso podem permanecer.
pause
goto MENU

:EXP_2
set "TITULO=Limpeza de Disco"
set "DESCRICAO=Abre o utilitario nativo cleanmgr para selecionar categorias."
set "TEMPO=Variavel, normalmente 5 a 30 minutos"
set "PESSOAIS=Pode remover arquivos selecionados; revise as categorias."
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "Abertura do cleanmgr confirmada"
start "" cleanmgr.exe
goto MENU

:EXP_3
set "TITULO=Esvaziar Lixeira"
set "DESCRICAO=Remove permanentemente a Lixeira do SEU usuario no volume do sistema."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=SIM. Arquivos da Lixeira serao excluidos permanentemente."
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "Esvaziamento da Lixeira confirmado"
call :LIXEIRA_USUARIO
echo Operacao finalizada. O Windows recriara a pasta quando necessario.
pause
goto MENU

:EXP_4
set "TITULO=Verificar arquivos do Windows (SFC)"
set "DESCRICAO=Executa sfc /scannow para verificar e reparar arquivos protegidos."
set "TEMPO=10 a 60 minutos"
set "PESSOAIS=Nao"
call :REQ_ADM
if errorlevel 1 goto MENU
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "SFC scannow iniciado"
sfc /scannow
pause
goto MENU

:EXP_5
set "TITULO=Reparar imagem do Windows (DISM)"
set "DESCRICAO=Executa DISM /Online /Cleanup-Image /RestoreHealth."
set "TEMPO=10 a 60 minutos ou mais"
set "PESSOAIS=Nao"
call :REQ_ADM
if errorlevel 1 goto MENU
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "DISM RestoreHealth iniciado"
dism.exe /Online /Cleanup-Image /RestoreHealth
pause
goto MENU

:EXP_6
set "TITULO=Verificar disco (CHKDSK online)"
set "DESCRICAO=Executa chkdsk no volume do sistema sem agendar reparo offline."
set "TEMPO=1 a 20 minutos, conforme o disco"
set "PESSOAIS=Nao; apenas leitura/verificacao nesta modalidade."
call :REQ_ADM
if errorlevel 1 goto MENU
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "CHKDSK online iniciado"
chkdsk %SystemDrive%
pause
goto MENU

:EXP_7
set "TITULO=Resetar Windows Update"
set "DESCRICAO=Para wuauserv, bits e cryptSvc e renomeia caches para .old."
set "TEMPO=2 a 10 minutos"
set "PESSOAIS=Nao; atualizacoes baixadas podem precisar ser baixadas novamente."
call :REQ_ADM
if errorlevel 1 goto MENU
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "Reset Windows Update confirmado"
net stop wuauserv
net stop bits
net stop cryptSvc
if exist "%WINDIR%\SoftwareDistribution.old" rd /s /q "%WINDIR%\SoftwareDistribution.old"
if exist "%WINDIR%\System32\catroot2.old" rd /s /q "%WINDIR%\System32\catroot2.old"
if exist "%WINDIR%\SoftwareDistribution" ren "%WINDIR%\SoftwareDistribution" SoftwareDistribution.old
if exist "%WINDIR%\System32\catroot2" ren "%WINDIR%\System32\catroot2" catroot2.old
net start cryptSvc
net start bits
net start wuauserv
echo Verifique as mensagens de cada servico.
pause
goto MENU

:EXP_8
set "TITULO=Informacoes e configuracao de rede"
set "DESCRICAO=Exibe configuracao IP, DNS, gateway e adaptadores."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Consulta ipconfig"
ipconfig /all
pause
goto MENU

:EXP_9
set "TITULO=Reset de rede"
set "DESCRICAO=Limpa cache DNS e redefine Winsock e pilha TCP/IP."
set "TEMPO=1 a 3 minutos; reinicializacao pode ser necessaria"
set "PESSOAIS=Nao; configuracoes de rede podem ser redefinidas."
call :REQ_ADM
if errorlevel 1 goto MENU
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "Reset de rede confirmado"
ipconfig /flushdns
netsh winsock reset
netsh int ip reset
echo Reinicie o computador para concluir.
pause
goto MENU

:EXP_10
set "TITULO=Teste de conectividade (ping)"
set "DESCRICAO=Testa conectividade com um destino padrao ou informado."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
set "DESTINO="
set /p "DESTINO=Destino (ENTER usa 8.8.8.8): "
if not defined DESTINO set "DESTINO=8.8.8.8"
call :LOG "Teste ping solicitado"
ping -n 4 "%DESTINO%"
pause
goto MENU

:EXP_11
set "TITULO=Teste de velocidade"
set "DESCRICAO=Abre um servico de teste de velocidade no navegador padrao."
set "TEMPO=1 a 3 minutos"
set "PESSOAIS=Nao; o site pode coletar dados de conexao."
call :INFO
if errorlevel 1 goto MENU
call :LOG "Abertura do teste de velocidade"
start "" "https://www.speedtest.net/"
goto MENU

:EXP_12
set "TITULO=Informacoes do sistema"
set "DESCRICAO=Abre o resumo de hardware, componentes e ambiente de software."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Abertura do msinfo32"
start "" msinfo32.exe
goto MENU

:EXP_13
set "TITULO=Gerenciador de Dispositivos"
set "DESCRICAO=Abre o console nativo para consultar drivers e dispositivos."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Abertura do Gerenciador de Dispositivos"
start "" devmgmt.msc
goto MENU

:EXP_14
set "TITULO=Processos em execucao"
set "DESCRICAO=Lista processos e respectivos identificadores."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Consulta tasklist"
tasklist
pause
goto MENU

:EXP_15
set "TITULO=Consultar servicos"
set "DESCRICAO=Exibe o estado dos servicos do Windows."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Consulta sc query"
sc.exe query
pause
goto MENU

:EXP_16
set "TITULO=Atualizar politicas (gpupdate)"
set "DESCRICAO=Atualiza politicas de usuario e computador."
set "TEMPO=1 a 5 minutos"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "gpupdate iniciado"
if "%IS_ADMIN%"=="1" (gpupdate /force) else (gpupdate /force /target:user)
pause
goto MENU

:EXP_17
set "TITULO=Resultado de politicas (gpresult)"
set "DESCRICAO=Exibe o conjunto resultante de politicas aplicadas."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=Nao; o relatorio pode conter dados do usuario e dominio."
call :INFO
if errorlevel 1 goto MENU
call :LOG "gpresult solicitado"
if "%IS_ADMIN%"=="1" (gpresult /r) else (gpresult /r /scope user)
pause
goto MENU

:EXP_18
set "TITULO=Espaco livre dos discos"
set "DESCRICAO=Consulta espaco livre e total em cada unidade logica."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Consulta de espaco em volumes"
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%D:\ call :DISCO %%D
pause
goto MENU

:EXP_19
set "TITULO=Dispositivos USB conectados"
set "DESCRICAO=Lista dispositivos USB conectados usando pnputil."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Consulta pnputil USB"
pnputil.exe /enum-devices /connected /class USB
pause
goto MENU

:EXP_20
set "TITULO=Uso de CPU"
set "DESCRICAO=Coleta uma amostra de utilizacao total do processador."
set "TEMPO=Alguns segundos"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Coleta typeperf CPU"
where wmic >nul 2>&1
if errorlevel 1 (
    echo wmic indisponivel; tentando typeperf ^(contador em ingles, pode falhar em outro idioma^)...
    typeperf "\Processor(_Total)\%% Processor Time" -sc 1
) else (
    wmic cpu get loadpercentage
)
echo.
echo Dica: a interface web ^(opcao 29^) mede CPU e memoria sem depender do idioma.
pause
goto MENU

:EXP_21
set "TITULO=Memoria RAM"
set "DESCRICAO=Mostra memoria fisica total e disponivel (systeminfo)."
set "TEMPO=Alguns segundos"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Consulta de memoria"
echo Memoria fisica ^(systeminfo, pode levar alguns segundos^):
systeminfo | %SystemRoot%\System32\findstr.exe /i /r /c:"^Total Physical" /c:"^Available Physical" /c:"^Mem.ria F.sica"
pause
goto MENU

:EXP_22
set "TITULO=Status do Microsoft Defender"
set "DESCRICAO=Consulta o servico WinDefend. Listar outros antivirus exigiria WMI/PowerShell."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
echo.
echo Observacao: listar outros antivirus instalados exige WMI/PowerShell.
call :LOG "Consulta do servico WinDefend"
sc.exe query WinDefend
pause
goto MENU

:EXP_23
set "TITULO=Backup / limpeza de logs de eventos"
set "DESCRICAO=Faz backup EVTX; a limpeza seletiva so ocorre apos backup bem-sucedido."
set "TEMPO=1 a 5 minutos"
set "PESSOAIS=O backup pode conter informacoes de sistema e usuario."
call :INFO
if errorlevel 1 goto MENU
echo.
echo 1. Backup do log System
echo 2. Backup e limpar log System [ADM]
echo 3. Backup do log Application
echo 4. Backup e limpar log Application [ADM]
echo 0. Voltar
set "EVLOG="
set "EVOP="
set /p "EVOP=Opcao: "
if "%EVOP%"=="0" goto MENU
if "%EVOP%"=="1" set "EVLOG=System"
if "%EVOP%"=="2" set "EVLOG=System"
if "%EVOP%"=="3" set "EVLOG=Application"
if "%EVOP%"=="4" set "EVLOG=Application"
if not defined EVLOG goto INVALIDA
set "NEEDADM=0"
if "%EVOP%"=="2" set "NEEDADM=1"
if "%EVOP%"=="4" set "NEEDADM=1"
if "%NEEDADM%"=="1" if not "%IS_ADMIN%"=="1" (
    echo [AVISO] Limpar log exige Administrador. Use as opcoes 1 ou 3 ^(somente backup^).
    pause
    goto MENU
)
call :CONFIRMAR
if errorlevel 1 goto MENU
set "EVFILE=%DATA_DIR%\%EVLOG%_%RANDOM%.evtx"
call :LOG "Backup do log %EVLOG% solicitado"
wevtutil.exe epl "%EVLOG%" "%EVFILE%" /ow:true
if errorlevel 1 (
    echo [ERRO] Backup falhou. O log nao sera limpo.
    pause
    goto MENU
)
echo Backup criado: "%EVFILE%"
if "%EVOP%"=="2" goto EV_CLEAN
if "%EVOP%"=="4" goto EV_CLEAN
goto EV_DONE
:EV_CLEAN
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "Limpeza do log %EVLOG% confirmada apos backup"
wevtutil.exe cl "%EVLOG%"
if errorlevel 1 echo [ERRO] Nao foi possivel limpar o log.
:EV_DONE
pause
goto MENU

:EXP_24
set "TITULO=Listar atualizacoes (winget)"
set "DESCRICAO=Lista pacotes com atualizacoes disponiveis."
set "TEMPO=1 a 5 minutos"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "winget upgrade listado"
winget.exe upgrade
pause
goto MENU

:EXP_25
set "TITULO=Atualizar todos os pacotes (winget)"
set "DESCRICAO=Executa winget upgrade --all sem aceitar acordos automaticamente."
set "TEMPO=Variavel; depende dos pacotes"
set "PESSOAIS=Pode alterar aplicativos e configuracoes; feche seus programas."
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "winget upgrade all confirmado"
winget.exe upgrade --all
pause
goto MENU

:EXP_26
set "TITULO=Download HTTPS e SHA256"
set "DESCRICAO=Baixa um arquivo por HTTPS com curl e calcula seu hash SHA256."
set "TEMPO=Depende do tamanho e da conexao"
set "PESSOAIS=O arquivo sera gravado na pasta Downloads do usuario."
call :INFO
if errorlevel 1 goto MENU
set "URL="
set "ARQUIVO="
set /p "URL=URL HTTPS: "
if not defined URL goto INVALIDA
if /i not "%URL:~0,8%"=="https://" goto INVALIDA
rem Rejeita aspas, operadores de cmd e sinal de porcentagem na entrada.
if not "%URL%"=="%URL:"=%" goto INVALIDA
if not "%URL%"=="%URL:&=%" goto INVALIDA
if not "%URL%"=="%URL:|=%" goto INVALIDA
if not "%URL%"=="%URL:<=%" goto INVALIDA
if not "%URL%"=="%URL:>=%" goto INVALIDA
if not "%URL%"=="%URL:^=%" goto INVALIDA
if not "%URL%"=="%URL:%%=%" goto INVALIDA
set /p "ARQUIVO=Nome do arquivo de destino (ex.: pacote.zip): "
if not defined ARQUIVO goto INVALIDA
if not "%ARQUIVO%"=="%ARQUIVO:\=%" goto INVALIDA
if not "%ARQUIVO%"=="%ARQUIVO:/=%" goto INVALIDA
if not "%ARQUIVO%"=="%ARQUIVO::=%" goto INVALIDA
if not "%ARQUIVO%"=="%ARQUIVO:*=%" goto INVALIDA
if not "%ARQUIVO%"=="%ARQUIVO:?=%" goto INVALIDA
if not "%ARQUIVO%"=="%ARQUIVO:"=%" goto INVALIDA
if not "%ARQUIVO%"=="%ARQUIVO:<=%" goto INVALIDA
if not "%ARQUIVO%"=="%ARQUIVO:>=%" goto INVALIDA
if not "%ARQUIVO%"=="%ARQUIVO:|=%" goto INVALIDA
if not "%ARQUIVO%"=="%ARQUIVO:^=%" goto INVALIDA
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "Download HTTPS confirmado: %ARQUIVO%"
if not exist "%USERPROFILE%\Downloads" mkdir "%USERPROFILE%\Downloads" >nul 2>&1
curl.exe --fail --location --proto "=https" --proto-redir "=https" -o "%USERPROFILE%\Downloads\%ARQUIVO%" "%URL%"
if errorlevel 1 (
    echo [ERRO] Download falhou.
    pause
    goto MENU
)
certutil.exe -hashfile "%USERPROFILE%\Downloads\%ARQUIVO%" SHA256
pause
goto MENU

:EXP_27
set "TITULO=Abrir Prompt de Comando"
set "DESCRICAO=Abre uma nova janela do cmd.exe."
set "TEMPO=Imediato"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Abertura de Prompt de Comando"
start "" cmd.exe
goto MENU

:EXP_28
:MEM_MENU
cls
echo ============================================================
echo                 SUBMENU DE MEMORIA
echo ============================================================
echo 1. Fechar processos pesados ^(taskkill^)
echo 2. Limpar temporarios
echo 3. Esvaziar Lixeira
echo 4. Reiniciar Explorer
echo 0. Voltar
set "MEMOP="
set /p "MEMOP=Selecione: "
if "%MEMOP%"=="0" goto MENU
if "%MEMOP%"=="1" goto MEM_1
if "%MEMOP%"=="2" goto MEM_2
if "%MEMOP%"=="3" goto MEM_3
if "%MEMOP%"=="4" goto MEM_4
goto INVALIDA
:MEM_1
echo Processos comuns: msedge.exe, chrome.exe, Teams.exe, outlook.exe
set "PROC="
set /p "PROC=Nome exato do processo (ex.: chrome.exe): "
if not defined PROC goto MEM_MENU
if not "%PROC%"=="%PROC: =%" goto MEM_MENU
call :CONFIRMAR
if errorlevel 1 goto MEM_MENU
call :LOG "Taskkill confirmado para %PROC%"
taskkill /F /IM "%PROC%"
pause
goto MEM_MENU
:MEM_2
call :CONFIRMAR
if errorlevel 1 goto MEM_MENU
call :LOG "Limpeza de temporarios no submenu"
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%~fD" >nul 2>&1
pause
goto MEM_MENU
:MEM_3
call :CONFIRMAR
if errorlevel 1 goto MEM_MENU
call :LOG "Limpeza da Lixeira no submenu"
call :LIXEIRA_USUARIO
pause
goto MEM_MENU
:MEM_4
call :CONFIRMAR
if errorlevel 1 goto MEM_MENU
call :LOG "Reinicio do Explorer confirmado"
taskkill /f /im explorer.exe
start explorer.exe
goto MEM_MENU

:EXP_29
set "TITULO=Interface web (Streamlit)"
set "DESCRICAO=Abre painel_suporte.py no navegador, somente neste computador (127.0.0.1). Sem ADM."
set "TEMPO=Alguns segundos"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
if not exist "%~dp0painel_suporte.py" (
    echo [ERRO] painel_suporte.py nao encontrado na pasta deste BAT.
    pause
    goto MENU
)
set "PYCMD="
where py >nul 2>&1 && set "PYCMD=py -3"
if not defined PYCMD where python >nul 2>&1 && set "PYCMD=python"
if not defined PYCMD (
    echo [ERRO] Python nao encontrado no PATH.
    pause
    goto MENU
)
%PYCMD% -c "import streamlit" >nul 2>&1
if errorlevel 1 (
    echo Streamlit nao instalado. Sera instalado so para o seu usuario ^(pip --user^).
    call :CONFIRMAR
    if errorlevel 1 goto MENU
    call :LOG "Instalacao do streamlit --user confirmada"
    %PYCMD% -m pip install --user streamlit
    if errorlevel 1 (
        echo [ERRO] Falha na instalacao.
        pause
        goto MENU
    )
)
if not exist "%USERPROFILE%\.streamlit\credentials.toml" (
    mkdir "%USERPROFILE%\.streamlit" >nul 2>&1
    (
        echo [general]
        echo email = ""
    ) > "%USERPROFILE%\.streamlit\credentials.toml"
)
call :LOG "Abertura da interface Streamlit"
start "Streamlit" cmd /k %PYCMD% -m streamlit run "%~dp0painel_suporte.py" --server.address 127.0.0.1 --browser.gatherUsageStats false
goto MENU

:EXP_U
call :LOG "Abertura do repositorio GitHub"
start "" "%GITHUB_REPO%"
goto MENU

:EXP_99
cls
echo Escolha uma cor para o painel:
echo 1. Azul/verde  2. Verde  3. Vermelho  4. Roxo
echo 5. Branco      6. Amarelo 7. Azul escuro 0. Voltar
set "COR="
set /p "COR=Opcao: "
if "%COR%"=="0" goto MENU
if "%COR%"=="1" color 0B&goto MENU
if "%COR%"=="2" color 0A&goto MENU
if "%COR%"=="3" color 0C&goto MENU
if "%COR%"=="4" color 05&goto MENU
if "%COR%"=="5" color 07&goto MENU
if "%COR%"=="6" color 0E&goto MENU
if "%COR%"=="7" color 09&goto MENU
goto INVALIDA

:SAIR
echo Encerrando Ferramenta suporte.
exit /b 0

rem ============================================================
rem Licenca MIT
rem Copyright (c) 2026 Wesley Gomes
rem Permission is hereby granted, free of charge, to any person
rem obtaining a copy of this software and associated documentation
rem files (the "Software"), to deal in the Software without
rem restriction, including without limitation the rights to use,
rem copy, modify, merge, publish, distribute, sublicense, and/or
rem sell copies of the Software, and to permit persons to whom the
rem Software is furnished to do so, subject to the following
rem conditions:
rem The above copyright notice and this permission notice shall be
rem included in all copies or substantial portions of the Software.
rem THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
rem ============================================================
