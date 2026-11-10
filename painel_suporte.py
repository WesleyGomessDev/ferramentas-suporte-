# -*- coding: utf-8 -*-
"""
Ferramenta Suporte - interface web (Streamlit)

Funciona SEM administrador e sem PowerShell. Acoes que exigem ADM ficam
bloqueadas (so liberam se o painel for aberto como administrador).

Executar:
    python -m streamlit run painel_suporte.py --server.address 127.0.0.1
Requer Streamlit >= 1.31.
"""
import ctypes
import hashlib
import os
import platform
import re
import shutil
import subprocess
import tempfile
import time
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

import streamlit as st

VERSAO = "1.1.0"
IS_WIN = os.name == "nt"
SYS32 = Path(os.environ.get("SystemRoot", r"C:\Windows")) / "System32"
DATA_DIR = Path(os.environ.get("LOCALAPPDATA") or Path.home()) / "FerramentaSuporte"
LOG_FILE = DATA_DIR / "painel_log.txt"  # mesmo log do .bat
TEXTOS_DIR = DATA_DIR / "textos"
DOWNLOADS = Path.home() / "Downloads"
ENC = "oem" if IS_WIN else "utf-8"
NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)
NEW_CONSOLE = getattr(subprocess, "CREATE_NEW_CONSOLE", 0)

MODELOS_PADRAO = {
    "saudacao": "Olá, {NOME}! Aqui é {TECNICO} do suporte técnico.\n"
                "Vou ajudar com o chamado {CHAMADO}.",
    "pedido_informacoes": "Olá, {NOME}. Para avançar no chamado {CHAMADO}, preciso de:\n"
                          "- print ou foto da mensagem de erro;\n"
                          "- horário aproximado em que o problema começou;\n"
                          "- se ele acontece em outros aplicativos.\n"
                          "Obrigado! {TECNICO}",
    "solucao_aplicada": "Olá, {NOME}! Sobre o chamado {CHAMADO}: o problema foi corrigido.\n"
                        "Se voltar a acontecer, é só nos avisar. {TECNICO}",
    "encerramento": "Olá, {NOME}. Estamos encerrando o chamado {CHAMADO}.\n"
                    "Caso precise de algo mais, abra um novo chamado. {TECNICO}",
}


# ------------------------------------------------------------------ helpers
def s32(nome):
    """Caminho completo em System32 (evita executar programa da pasta atual)."""
    return str(SYS32 / nome)


def is_admin():
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin()) if IS_WIN else False
    except Exception:
        return False


def log(msg):
    try:
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{datetime.now():%d/%m/%Y %H:%M:%S}] (web) {msg}\n")
    except OSError:
        pass


def ler_log(n=25):
    try:
        linhas = LOG_FILE.read_text(encoding="utf-8", errors="replace").splitlines()
        return "\n".join(linhas[-n:]) or "(vazio)"
    except OSError:
        return "(sem log ainda)"


def run(cmd, timeout=120):
    """Executa sem shell (cmd = lista). Retorna (codigo, saida)."""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, encoding=ENC, errors="replace",
                           timeout=timeout, stdin=subprocess.DEVNULL, creationflags=NO_WINDOW)
        return p.returncode, ((p.stdout or "") + (p.stderr or "")).strip() or "(sem saída)"
    except FileNotFoundError:
        return 127, f"Comando não encontrado: {cmd[0]}"
    except subprocess.TimeoutExpired:
        return 124, f"Tempo esgotado ({timeout}s)."
    except OSError as e:
        return 126, f"Falha ao executar: {e}"


def abrir(cmd, console=False):
    """Abre programa/janela sem bloquear a interface."""
    try:
        if console:
            subprocess.Popen(["cmd.exe", "/k"] + cmd, creationflags=NEW_CONSOLE)
        else:
            subprocess.Popen(cmd)
        return True
    except OSError as e:
        st.error(f"Falha ao abrir: {e}")
        return False


def mostrar(rc, out):
    (st.success if rc == 0 else st.error)(f"Código de saída: {rc}")
    st.code(out, language="text")


def gb(b):
    return f"{b / 1024 ** 3:.1f} GB"


# validacoes (entrada do usuario)
def host_valido(h):
    return bool(re.fullmatch(r"[A-Za-z0-9.:\-]{1,253}", h)) and not h.startswith("-")


def processo_valido(n):
    return bool(re.fullmatch(r"[A-Za-z0-9_.\-]{1,60}\.exe", n, re.I))


def arquivo_valido(n):
    return bool(re.fullmatch(r"[\w.\- ()]{1,100}", n)) and n.strip(". ") == n and not n.startswith("-")


def url_valida(u):
    p = urlparse(u)
    return p.scheme == "https" and bool(p.netloc) and not any(c in u for c in ' "\'<>|^\r\n\t')


def modelo_valido(n):
    return bool(re.fullmatch(r"[A-Za-z0-9_-]{1,40}", n))


# textos prontos
def garantir_modelos():
    try:
        TEXTOS_DIR.mkdir(parents=True, exist_ok=True)
        if not any(TEXTOS_DIR.glob("*.txt")):
            for nome, txt in MODELOS_PADRAO.items():
                (TEXTOS_DIR / f"{nome}.txt").write_text(txt, encoding="utf-8")
    except OSError:
        pass


def listar_modelos():
    try:
        return sorted(p.stem for p in TEXTOS_DIR.glob("*.txt") if modelo_valido(p.stem))
    except OSError:
        return []


def preencher(texto, valores):
    """Troca {VARIAVEL}; se o valor estiver vazio, mantem o marcador visivel."""
    return re.sub(r"\{([A-Z0-9_]+)\}", lambda m: valores.get(m.group(1)) or m.group(0), texto)


# leituras do sistema (APIs do Windows via ctypes: sem ADM, sem WMI, sem idioma)
class _MEMSTAT(ctypes.Structure):
    _fields_ = [("dwLength", ctypes.c_ulong), ("dwMemoryLoad", ctypes.c_ulong),
                ("ullTotalPhys", ctypes.c_ulonglong), ("ullAvailPhys", ctypes.c_ulonglong),
                ("ullTotalPageFile", ctypes.c_ulonglong), ("ullAvailPageFile", ctypes.c_ulonglong),
                ("ullTotalVirtual", ctypes.c_ulonglong), ("ullAvailVirtual", ctypes.c_ulonglong),
                ("ullAvailExtendedVirtual", ctypes.c_ulonglong)]


class _FILETIME(ctypes.Structure):
    _fields_ = [("lo", ctypes.c_ulong), ("hi", ctypes.c_ulong)]


def _ft(x):
    return (x.hi << 32) | x.lo


def memoria():
    if not IS_WIN:
        return None
    s = _MEMSTAT()
    s.dwLength = ctypes.sizeof(s)
    ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(s))
    return s.ullTotalPhys, s.ullAvailPhys, s.dwMemoryLoad


def cpu_percent(intervalo=0.5):
    if not IS_WIN:
        return None
    f = ctypes.windll.kernel32.GetSystemTimes

    def amostra():
        i, k, u = _FILETIME(), _FILETIME(), _FILETIME()
        f(ctypes.byref(i), ctypes.byref(k), ctypes.byref(u))
        return _ft(i), _ft(k), _ft(u)

    a = amostra()
    time.sleep(intervalo)
    b = amostra()
    ocioso, total = b[0] - a[0], (b[1] - a[1]) + (b[2] - a[2])  # kernel ja inclui o ocioso
    return 0.0 if total <= 0 else round(100 * (total - ocioso) / total, 1)


def uptime():
    if not IS_WIN:
        return "n/d"
    k = ctypes.windll.kernel32
    k.GetTickCount64.restype = ctypes.c_ulonglong
    s = int(k.GetTickCount64() // 1000)
    return f"{s // 86400}d {s % 86400 // 3600}h {s % 3600 // 60}min"


def discos():
    saida = []
    for letra in "CDEFGHIJKLMNOPQRSTUVWXYZ":
        raiz = f"{letra}:\\"
        if os.path.exists(raiz):
            try:
                u = shutil.disk_usage(raiz)
                saida.append((letra, u.total, u.used, u.free))
            except OSError:
                pass
    return saida


@st.cache_data(ttl=3, show_spinner=False)
def leitura_rapida():
    return cpu_percent(), memoria(), uptime(), discos()


# acoes de manutencao
def limpar_temp():
    base = Path(tempfile.gettempdir()).resolve()
    if len(base.parts) < 3 or base.name.lower() not in ("temp", "tmp"):
        return 0, 0, f"Pasta TEMP inesperada ({base}); nada foi removido."
    ok = falha = 0
    for item in base.iterdir():
        try:
            if item.is_dir() and not item.is_symlink():
                shutil.rmtree(item)
            else:
                item.unlink()
            ok += 1
        except OSError:
            falha += 1  # arquivo em uso
    return ok, falha, str(base)


def esvaziar_lixeira():
    """API do Windows: esvazia a Lixeira do usuario atual, sem ADM."""
    if not IS_WIN:
        return None
    # SHERB_NOCONFIRMATION | SHERB_NOPROGRESSUI | SHERB_NOSOUND
    return ctypes.windll.shell32.SHEmptyRecycleBinW(None, None, 0x7)


def baixar(url, nome):
    destino = DOWNLOADS / nome
    if destino.exists():
        return 1, f"{destino} já existe. Escolha outro nome."
    DOWNLOADS.mkdir(parents=True, exist_ok=True)
    rc, out = run([s32("curl.exe"), "--fail", "--location", "--proto", "=https",
                   "--proto-redir", "=https", "-o", str(destino), url], timeout=3600)
    if rc != 0:
        return rc, out
    h = hashlib.sha256()
    with open(destino, "rb") as f:
        for bloco in iter(lambda: f.read(1024 * 1024), b""):
            h.update(bloco)
    return 0, f"Arquivo: {destino}\nTamanho: {destino.stat().st_size} bytes\nSHA256: {h.hexdigest()}"


# ------------------------------------------------------------------ interface
def acao(chave, titulo, desc, cmd, adm=False, confirmar=False, console=False, timeout=120):
    """Cartao com descricao + botao. 'adm' bloqueia se nao for administrador."""
    with st.container(border=True):
        st.markdown(f"**{titulo}**" + ("  🔒 ADM" if adm else ""))
        st.caption(desc)
        if adm and not ADMIN:
            st.button("Executar", key=f"b_{chave}", disabled=True)
            st.caption("Exige administrador — indisponível neste modo.")
            return
        ok = st.checkbox("Confirmo a execução", key=f"c_{chave}") if confirmar else True
        if st.button("Executar", key=f"b_{chave}", disabled=not ok):
            log(f"acao {chave}")
            if console:
                if abrir(cmd, console=True):
                    st.info("Aberto em uma nova janela (acompanhe o progresso por lá).")
            else:
                with st.spinner("Executando..."):
                    rc, out = run(cmd, timeout)
                mostrar(rc, out)


def aba_geral():
    cpu, mem, up, ds = leitura_rapida()
    c1, c2, c3 = st.columns(3)
    c1.metric("CPU", f"{cpu}%" if cpu is not None else "n/d")
    if mem:
        total, livre, carga = mem
        c2.metric("RAM em uso", f"{carga}%", f"{gb(total - livre)} de {gb(total)}", delta_color="off")
    else:
        c2.metric("RAM em uso", "n/d")
    c3.metric("Ligado há", up)
    st.subheader("Discos")
    for letra, total, usado, livre in ds:
        st.progress(min(usado / total, 1.0) if total else 0.0,
                    text=f"{letra}: — {gb(livre)} livres de {gb(total)}")
    if st.button("🔄 Atualizar"):
        st.cache_data.clear()
        st.rerun()


def aba_rede():
    acao("ipconfig", "Configuração de rede", "Exibe IP, DNS, gateway e adaptadores.",
         [s32("ipconfig.exe"), "/all"])
    with st.container(border=True):
        st.markdown("**Teste de conectividade (ping)**")
        host = st.text_input("Destino", value="8.8.8.8", key="ping_host").strip()
        if st.button("Executar ping", key="b_ping"):
            if not host_valido(host):
                st.error("Destino inválido. Use apenas letras, números, ponto, dois-pontos e hífen.")
            else:
                log("acao ping")
                with st.spinner("Testando..."):
                    mostrar(*run([s32("ping.exe"), "-n", "4", host], 30))
    st.link_button("🌐 Abrir teste de velocidade (navegador)", "https://www.speedtest.net/")


def aba_manutencao():
    with st.container(border=True):
        st.markdown("**Limpar TEMP do usuário**")
        st.caption("Remove o conteúdo da sua pasta TEMP. Arquivos em uso são ignorados. "
                   "Feche os aplicativos antes.")
        if st.button("Limpar TEMP", key="b_temp", disabled=not st.checkbox("Confirmo", key="c_temp")):
            log("acao limpar temp")
            ok, falha, pasta = limpar_temp()
            st.success(f"Removidos: {ok} | Ignorados (em uso): {falha}") if ok or falha else st.warning(pasta)
            st.caption(pasta)
    with st.container(border=True):
        st.markdown("**Esvaziar a Lixeira (seu usuário)**")
        st.caption("Exclui permanentemente os arquivos da SUA Lixeira.")
        if st.button("Esvaziar Lixeira", key="b_lix", disabled=not st.checkbox("Confirmo", key="c_lix")):
            log("acao esvaziar lixeira")
            r = esvaziar_lixeira()
            st.success("Operação finalizada.") if r in (0, None) else st.warning(f"Código do Windows: {r:#x}")
    with st.container(border=True):
        st.markdown("**Limpeza de Disco (cleanmgr)**")
        st.caption("Abre o utilitário do Windows. Sem ADM, categorias de sistema não aparecem.")
        if st.button("Abrir cleanmgr", key="b_clean"):
            log("acao cleanmgr")
            abrir([s32("cleanmgr.exe")])
    acao("gpupdate", "Atualizar políticas (gpupdate)",
         "Atualiza as políticas" + ("." if ADMIN else " do usuário (modo sem ADM)."),
         [s32("gpupdate.exe"), "/force"] + ([] if ADMIN else ["/target:user"]), confirmar=True, timeout=180)
    acao("gpresult", "Resultado de políticas (gpresult)",
         "Pode conter dados do usuário e do domínio.",
         [s32("gpresult.exe"), "/r"] + ([] if ADMIN else ["/scope", "user"]))


def aba_sistema():
    acao("systeminfo", "Informações do sistema (systeminfo)", "Pode levar alguns segundos.",
         [s32("systeminfo.exe")], timeout=180)
    acao("tasklist", "Processos em execução", "Lista processos e identificadores.", [s32("tasklist.exe")])
    acao("sc", "Serviços", "Estado dos serviços do Windows.", [s32("sc.exe"), "query"])
    acao("defender", "Status do Microsoft Defender", "Consulta o serviço WinDefend.",
         [s32("sc.exe"), "query", "WinDefend"])
    acao("usb", "Dispositivos USB conectados", "Usa pnputil.",
         [s32("pnputil.exe"), "/enum-devices", "/connected", "/class", "USB"])
    with st.container(border=True):
        st.markdown("**Abrir ferramentas do Windows**")
        c1, c2 = st.columns(2)
        if c1.button("msinfo32", key="b_msinfo"):
            log("abrir msinfo32")
            abrir([s32("msinfo32.exe")])
        if c2.button("Gerenciador de Dispositivos", key="b_devmgmt"):
            log("abrir devmgmt")
            abrir([s32("mmc.exe"), "devmgmt.msc"])
    with st.container(border=True):
        st.markdown("**Encerrar processo**")
        st.caption("Fecha à força e pode causar perda de trabalho não salvo. Sem ADM, só processos seus.")
        nome = st.text_input("Nome exato (ex.: chrome.exe)", key="kill_nome").strip()
        ok = st.checkbox("Confirmo", key="c_kill")
        if st.button("Encerrar", key="b_kill", disabled=not ok):
            if not processo_valido(nome):
                st.error("Nome inválido. Use algo como chrome.exe.")
            else:
                log(f"taskkill {nome}")
                mostrar(*run([s32("taskkill.exe"), "/F", "/IM", nome], 30))
    with st.container(border=True):
        st.markdown("**Reiniciar o Windows Explorer**")
        if st.button("Reiniciar Explorer", key="b_expl", disabled=not st.checkbox("Confirmo", key="c_expl")):
            log("reiniciar explorer")
            run([s32("taskkill.exe"), "/F", "/IM", "explorer.exe"], 15)
            abrir([str(SYS32.parent / "explorer.exe")])
            st.success("Explorer reiniciado.")


def aba_programas():
    acao("winget_list", "Atualizações disponíveis (winget)", "Lista pacotes com atualização.",
         ["winget", "upgrade"], timeout=180)
    acao("winget_all", "Atualizar todos os pacotes (winget)",
         "Abre em nova janela. Pacotes que exigem ADM podem pedir elevação ou falhar neste modo.",
         ["winget", "upgrade", "--all"], confirmar=True, console=True)


def aba_download():
    with st.container(border=True):
        st.markdown("**Download HTTPS + SHA256**")
        st.caption(f"O arquivo é gravado em {DOWNLOADS}. Confira a origem e o hash antes de executar.")
        url = st.text_input("URL (https://...)", key="dl_url").strip()
        nome = st.text_input("Nome do arquivo (ex.: pacote.zip)", key="dl_nome").strip()
        if st.button("Baixar", key="b_dl", disabled=not st.checkbox("Confirmo", key="c_dl")):
            if not url_valida(url):
                st.error("URL inválida: use https:// e não use aspas ou símbolos de comando.")
            elif not arquivo_valido(nome):
                st.error("Nome de arquivo inválido (sem pastas, : * ? \" < > | e sem começar com hífen).")
            else:
                log(f"download confirmado: {nome}")
                with st.spinner("Baixando..."):
                    mostrar(*baixar(url, nome))


def aba_textos():
    st.caption("Escolha um modelo, preencha as variáveis e use o botão de copiar no canto do texto.")
    modelos = listar_modelos()
    if modelos:
        escolhido = st.selectbox("Modelo", modelos, key="modelo")
        texto = (TEXTOS_DIR / f"{escolhido}.txt").read_text(encoding="utf-8", errors="replace")
        valores = {}
        for var in dict.fromkeys(re.findall(r"\{([A-Z0-9_]+)\}", texto)):
            valores[var] = st.text_input(var.capitalize(), key=f"var_{var}")
        st.code(preencher(texto, valores), language="text")
        with st.expander("Editar este modelo"):
            novo = st.text_area("Texto (use {NOME}, {CHAMADO}, {TECNICO}...)", value=texto,
                                height=180, key=f"edit_{escolhido}")
            c1, c2 = st.columns(2)
            if c1.button("Salvar alterações", key="b_salvar"):
                (TEXTOS_DIR / f"{escolhido}.txt").write_text(novo, encoding="utf-8")
                st.success("Modelo salvo.")
            if c2.button("Excluir modelo", key="b_excluir", disabled=not st.checkbox("Confirmo", key="c_excl")):
                (TEXTOS_DIR / f"{escolhido}.txt").unlink(missing_ok=True)
                st.rerun()
    else:
        st.info("Nenhum modelo ainda. Crie o primeiro abaixo.")
    with st.expander("Novo modelo"):
        nome = st.text_input("Nome (letras, números, _ e -)", key="novo_nome").strip()
        corpo = st.text_area("Texto", height=150, key="novo_corpo")
        if st.button("Criar modelo", key="b_criar"):
            alvo = TEXTOS_DIR / f"{nome}.txt"
            if not modelo_valido(nome):
                st.error("Nome inválido.")
            elif alvo.exists():
                st.error("Já existe um modelo com esse nome.")
            elif not corpo.strip():
                st.error("O texto está vazio.")
            else:
                alvo.write_text(corpo, encoding="utf-8")
                st.rerun()


def aba_adm():
    if ADMIN:
        st.warning("Painel aberto como administrador: estas ações estão liberadas.")
    else:
        st.info("Estas ações exigem administrador e ficam bloqueadas neste modo. "
                "Para usá-las, abra o painel como administrador (se autorizado pela TI).")
    unidade = os.environ.get("SystemDrive", "C:")
    acao("sfc", "Verificar arquivos do Windows (SFC)", "sfc /scannow. Pode levar de 10 a 60 minutos.",
         [s32("sfc.exe"), "/scannow"], adm=True, confirmar=True, console=True)
    acao("dism", "Reparar imagem do Windows (DISM)", "DISM /Online /Cleanup-Image /RestoreHealth.",
         [s32("dism.exe"), "/Online", "/Cleanup-Image", "/RestoreHealth"], adm=True, confirmar=True, console=True)
    acao("chkdsk", "Verificar disco (CHKDSK online)", f"chkdsk {unidade} sem agendar reparo offline.",
         [s32("chkdsk.exe"), unidade], adm=True, confirmar=True, console=True)
    acao("flushdns", "Limpar cache DNS", "ipconfig /flushdns.",
         [s32("ipconfig.exe"), "/flushdns"], adm=True, confirmar=True)
    acao("winsock", "Reset do Winsock", "netsh winsock reset. Reinicie o computador depois.",
         [s32("netsh.exe"), "winsock", "reset"], adm=True, confirmar=True)
    acao("iprst", "Reset da pilha TCP/IP", "netsh int ip reset. Reinicie o computador depois.",
         [s32("netsh.exe"), "int", "ip", "reset"], adm=True, confirmar=True)
    st.caption("Reset do Windows Update e limpeza de logs de eventos ficam só no .bat (opções 7 e 23), como administrador.")


def main():
    global ADMIN
    ADMIN = is_admin()
    st.set_page_config(page_title="Ferramenta Suporte", page_icon="🛠️", layout="wide")
    garantir_modelos()
    with st.sidebar:
        st.title("🛠️ Ferramenta Suporte")
        st.caption(f"Versão {VERSAO}")
        (st.warning if ADMIN else st.success)("Modo: Administrador" if ADMIN else "Modo: Usuário padrão (sem ADM)")
        st.text(f"Host: {platform.node()}\nUsuário: {os.environ.get('USERNAME', '?')}")
        st.caption(f"Log: {LOG_FILE}")
        with st.expander("Últimas linhas do log"):
            st.code(ler_log(), language="text")
    abas = st.tabs(["📊 Geral", "🌐 Rede", "🧹 Manutenção", "⚙️ Sistema", "📦 Programas",
                    "⬇️ Download", "💬 Textos prontos", "🔒 Requer ADM"])
    for aba, funcao in zip(abas, (aba_geral, aba_rede, aba_manutencao, aba_sistema, aba_programas,
                                  aba_download, aba_textos, aba_adm)):
        with aba:
            funcao()


ADMIN = False

if __name__ == "__main__":
    main()
