#!/bin/bash

# --- CONFIGURACIÓN VISUAL ---
LOG_FILE="setup.log"
RCol='\e[0m'
Blu='\e[0;34m'
Gre='\e[0;32m'
Yel='\e[0;33m'
Red='\e[0;31m'

# --- CONFIGURACIÓN C++ (PARCHEADO PARA FGSEA/BOOST) ---
# Forzamos a que todo, incluido lo que pida C++11 o C++14, use C++17
mkdir -p ~/.R
cat <<EOF > ~/.R/Makevars
CXX = g++
CXXSTD = -std=gnu++17
CXX11 = g++
CXX11STD = -std=gnu++17
CXX14 = g++
CXX14STD = -std=gnu++17
CXX17 = g++
CXX17STD = -std=gnu++17
MAKEFLAGS = -j$(nproc)
EOF

# Ocultar cursor
tput civis 2>/dev/null || echo -ne "\e[?25l"
trap 'tput cnorm 2>/dev/null || echo -ne "\e[?25h"; exit' INT TERM EXIT

draw_progress_bar() {
    local percent=$1
    local title=$2
    local status=$3
    local width=20 
    local filled=$(($width * $percent / 100))
    local empty=$(($width - $filled))
    local term_width=$(tput cols 2>/dev/null || echo 80)
    local max_len=$((term_width - 45))
    if [ $max_len -lt 10 ]; then max_len=10; fi
    printf "\r${Blu}[${RCol}"
    printf "%0.s#" $(seq 1 $filled)
    printf "%0.s." $(seq 1 $empty)
    printf "${Blu}]${RCol} %d%% - %s ${Yel}%.*s${RCol}\033[K" "$percent" "$title" "$max_len" "$status"
}

run_step() {
    local percent=$1
    local title=$2
    local cmd=$3
    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    while kill -0 $pid 2>/dev/null; do
        local current_action=$(tail -n 5 "$LOG_FILE" | grep -iE "installing|compiling|building|unpacking" | tail -n 1 | sed 's/^[ \t]*//')
        if [ -z "$current_action" ]; then current_action="Procesando..."; fi
        draw_progress_bar $percent "$title" "($current_action)"
        sleep 0.5
    done
    wait $pid
    local ret=$?
    if [ $ret -ne 0 ]; then
        tput cnorm 2>/dev/null || echo -ne "\e[?25h"
        echo -e "\n${Red}[ERROR] Fallo en: $title. Mira $LOG_FILE${RCol}"
        exit 1
    fi
}

# --- INICIO ---
clear
echo ">>> Iniciando instalación (FIX: C++17 y ggtree patch)..."
echo "" > "$LOG_FILE"

# PASO 1: Carpetas
run_step 10 "Configurando entorno" '
    mkdir -p "../software/R_LIBS"
    sleep 1
'
export R_LIBS_USER=$(readlink -f "../software/R_LIBS")

# PASO 2: Instaladores base
run_step 25 "Instalando núcleo" '
    Rscript -e "
    lib_loc <- Sys.getenv(\"R_LIBS_USER\")
    .libPaths(c(lib_loc, .libPaths()))
    r <- getOption(\"repos\"); r[\"CRAN\"] <- \"https://cloud.r-project.org\"; options(repos = r)
    
    cores <- parallel::detectCores()
    
    if (!require(\"BiocManager\", quietly=TRUE)) install.packages(\"BiocManager\", lib=lib_loc, quiet=TRUE, Ncpus=cores)
    if (!require(\"pacman\", quietly=TRUE)) install.packages(\"pacman\", lib=lib_loc, quiet=TRUE, Ncpus=cores)
    if (!require(\"remotes\", quietly=TRUE)) install.packages(\"remotes\", lib=lib_loc, quiet=TRUE, Ncpus=cores)
    "
'

# PASO 3: Utilidades y parche ggtree
# Aquí instalamos ggtree desde GitHub ANTES que el resto para evitar que BiocManager intente poner la versión vieja rota
run_step 50 "Parcheando ggtree" '
    Rscript -e "
    lib_loc <- Sys.getenv(\"R_LIBS_USER\")
    .libPaths(c(lib_loc, .libPaths()))
    
    # 1. Instalar dependencias básicas de CRAN
    pkgs <- c(\"jsonlite\", \"scales\", \"stringr\", \"httr\", \"curl\", \"openssl\", \"RColorBrewer\", \"ggplot2\", \"aplot\")
    cores <- parallel::detectCores()
    BiocManager::install(pkgs, lib=lib_loc, update=FALSE, ask=FALSE, quiet=FALSE, Ncpus=cores)
    
    # 2. Instalar ggtree desde GitHub para compatibilidad con ggplot2 > 3.5
    # Necesitamos aplot instalado antes (hecho arriba)
    tryCatch({
        remotes::install_github(\"YuLab-SMU/ggtree\", lib=lib_loc, upgrade=\"never\", quiet=TRUE)
    }, error=function(e) {
        message(\"Aviso: Fallo descarga GitHub, se intentara version Bioc normal\")
    })
    "
'

# PASO 4: Bioinformática (El resto)
run_step 80 "Instalando Bioinfo" '
    Rscript -e "
    lib_loc <- Sys.getenv(\"R_LIBS_USER\")
    .libPaths(c(lib_loc, .libPaths()))
    
    # fgsea ahora debería compilar gracias al Makevars C++17
    # ggtree ya debería estar instalado, así que clusterProfiler no fallará
    pkgs <- c(\"STRINGdb\", \"igraph\", \"clusterProfiler\", \"org.Hs.eg.db\", \"ggraph\", 
            \"DOSE\", \"fgsea\", \"enrichplot\")
    cores <- parallel::detectCores()
    
    BiocManager::install(pkgs, lib=lib_loc, update=FALSE, ask=FALSE, quiet=FALSE, Ncpus=cores)
    "
'

# FIN
draw_progress_bar 100 "Completado" ""
echo -e "\n\n${Gre}>>> Instalación finalizada.${RCol}\n"