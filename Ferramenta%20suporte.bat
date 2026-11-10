@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Ferramenta suporte - Wesley Gomes

rem ============================================================
rem Ferramenta suporte | Autor: Wesley Gomes | Licenca MIT
rem Requer Windows 10/11 e execucao como Administrador.
rem ============================================================
set "VERSAO=1.0.0"
set "URL_CHAMADO=https://github.com"
set "GITHUB_REPO=https://github.com"
set "LOG_FILE=%~dp0painel_log.txt"

net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERRO] Execute este arquivo como Administrador.
    echo Clique com o botao direito e escolha "Executar como administrador".
    pause
    exit /b 1
)

color 0B
:MENU
cls
echo ============================================================
echo                 FERRAMENTA SUPORTE
echo                    Wesley Gomes
echo ============================================================
echo Versao: %VERSAO%
echo Log: %LOG_FILE%
echo Chamados: %URL_CHAMADO%
echo ------------------------------------------------------------
echo  1. Limpeza de arquivos temporarios
echo  2. Limpeza de disco ^(cleanmgr^)
echo  3. Esvaziar Lixeira
echo  4. Verificar arquivos do Windows ^(SFC^)
echo  5. Reparar imagem do Windows ^(DISM^)
echo  6. Verificar disco ^(CHKDSK online^)
echo  7. Resetar Windows Update
echo  8. Informacoes e configuracao de rede
echo  9. Reset de rede ^(Winsock/IP^)
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
echo 23. Backup / limpeza de logs de eventos
echo 24. Atualizacoes disponiveis ^(winget^)
echo 25. Atualizar todos os pacotes ^(winget^)
echo 26. Baixar arquivo via HTTPS e calcular SHA256
echo 27. Abrir Prompt de Comando
echo 28. Submenu de memoria e processos
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
echo(!OPCAO!| %SystemRoot%\System32\findstr.exe /r /x "\(1\|2\|3\|4\|5\|6\|7\|8\|9\|10\|11\|12\|13\|14\|15\|16\|17\|18\|19\|20\|21\|22\|23\|24\|25\|26\|27\|28\)" >nul
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

:EXP_1
set "TITULO=Limpeza de arquivos temporarios"
set "DESCRICAO=Remove o conteudo das pastas TEMP do usuario e do Windows."
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
echo Limpando %WINDIR%\Temp ...
del /f /s /q "%WINDIR%\Temp\*" >nul 2>&1
for /d %%D in ("%WINDIR%\Temp\*") do rd /s /q "%%~fD" >nul 2>&1
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
set "DESCRICAO=Remove permanentemente o conteudo de $Recycle.Bin do volume do sistema."
set "TEMPO=Menos de 1 minuto"
set "PESSOAIS=SIM. Arquivos da Lixeira serao excluidos permanentemente."
call :INFO
if errorlevel 1 goto MENU
call :CONFIRMAR
if errorlevel 1 goto MENU
call :LOG "Esvaziamento da Lixeira confirmado"
rd /s /q "%SystemDrive%\$Recycle.Bin"
echo Operacao finalizada. O Windows recriara a pasta quando necessario.
pause
goto MENU

:EXP_4
set "TITULO=Verificar arquivos do Windows (SFC)"
set "DESCRICAO=Executa sfc /scannow para verificar e reparar arquivos protegidos."
set "TEMPO=10 a 60 minutos"
set "PESSOAIS=Nao"
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
gpupdate /force
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
gpresult /r
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
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%D:\ fsutil volume diskfree %%D:
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
typeperf "\Processor(_Total)\%% Processor Time" -sc 1
pause
goto MENU

:EXP_21
set "TITULO=Memoria RAM"
set "DESCRICAO=Mostra memoria disponivel e memoria fisica total (systeminfo)."
set "TEMPO=Alguns segundos"
set "PESSOAIS=Nao"
call :INFO
if errorlevel 1 goto MENU
call :LOG "Consulta de memoria"
typeperf "\Memory\Available MBytes" -sc 1
echo.
echo Memoria fisica total (linha varia conforme idioma do Windows):
systeminfo | %SystemRoot%\System32\findstr.exe /i /c:"Total Physical Memory" /c:"Memoria fisica total" /c:"Memória física total"
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
echo 2. Backup e limpar log System
echo 3. Backup do log Application
echo 4. Backup e limpar log Application
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
call :CONFIRMAR
if errorlevel 1 goto MENU
set "EVFILE=%~dp0%EVLOG%_%RANDOM%.evtx"
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
set "PESSOAIS=O arquivo sera gravado na pasta deste BAT."
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
curl.exe --fail --location --proto "=https" -o "%~dp0%ARQUIVO%" "%URL%"
if errorlevel 1 (
    echo [ERRO] Download falhou.
    pause
    goto MENU
)
certutil.exe -hashfile "%~dp0%ARQUIVO%" SHA256
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
rd /s /q "%SystemDrive%\$Recycle.Bin"
pause
goto MEM_MENU
:MEM_4
call :CONFIRMAR
if errorlevel 1 goto MEM_MENU
call :LOG "Reinicio do Explorer confirmado"
taskkill /f /im explorer.exe
start explorer.exe
goto MEM_MENU

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
