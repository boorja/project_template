#!/bin/bash

# --- 1. Configurar la ruta de las librerías (CRÍTICO) ---
# Esto debe apuntar exactamente a la misma carpeta que usaste en setup.sh
export R_LIBS_USER=$(readlink -f "../software/R_LIBS")

# Comprobación visual para el log (opcional, pero útil para depurar)
echo ">>> Usando librerías en: $R_LIBS_USER"
echo ">>> Comprobando si pacman existe: $(ls $R_LIBS_USER/pacman/DESCRIPTION 2>/dev/null)"

# --- 2. Cargar Módulos (Si estás en un cluster) ---
# Si tu sistema no usa modules, puedes comentar esto, pero en tu log original parecía usarlos.
if command -v module &> /dev/null; then
    module load R/4.1.0-foss-2020b
fi

# 3. Ejecutar el script R
# El script ya guarda todo en ../results, así que solo hay que ejecutarlo
Rscript analyse_raynaud.R

echo ">>> [LAUNCH] Fin. Revisa la carpeta 'results'."