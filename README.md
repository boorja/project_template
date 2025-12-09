# Proyecto de Biología de Sistemas
## Análisis de Red de Interacción Génica del Fenómeno de Raynaud

[![R](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-Academic-green.svg)](#licencia)

Este proyecto implementa un análisis de redes de interacción proteína-proteína (PPI) para genes asociados al **Fenómeno de Raynaud** (HPO: HP:0030880), utilizando datos de la Human Phenotype Ontology (HPO) y STRINGdb. El análisis integra detección de comunidades, métricas topológicas y enriquecimiento funcional mediante Gene Ontology.

---

## 📋 Tabla de Contenidos

- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación](#-instalación)
- [Uso](#-uso)
- [Pipeline de Análisis](#-pipeline-de-análisis)
- [Resultados Generados](#-resultados-generados)
- [Solución de Problemas](#-solución-de-problemas)
- [Autores](#-autores)

---

## 📁 Estructura del Proyecto

```
project_template/
├── code/                   # Scripts de ejecución
│   ├── setup.sh           # Configuración e instalación de dependencias R
│   ├── launch.sh          # Lanzador del análisis
│   └── analyse_raynaud.R  # Pipeline principal de análisis
├── report/                 # Documentación y memoria LaTeX
│   ├── report.tex         # Documento principal
│   ├── bibliography/      # Referencias bibliográficas (.bib)
│   ├── figures/           # Figuras para el informe
│   └── tex_files/         # Secciones del documento
├── results/                # Resultados generados (CSVs y PNGs)
├── software/               # Librerías R instaladas localmente
└── README.md
```

---

## 💻 Requisitos Previos

### Sistema Operativo
- **Linux/Ubuntu** (recomendado) o WSL en Windows
- **macOS** (con Homebrew para dependencias)

### Software Base
- **R** versión 4.0 o superior
- **Conexión a internet** (para descargar datos de HPO y STRINGdb)

### Dependencias del Sistema (solo si hay errores)

> **Nota:** En la mayoría de sistemas con R ya configurado, estas dependencias ya están instaladas. Solo necesitas ejecutar este paso si `setup.sh` falla con errores de compilación.

<details>
<summary><b>¿Por qué no están incluidas en setup.sh?</b> (click para expandir)</summary>

Estas librerías son **dependencias del sistema operativo** (no de R) y requieren permisos de **superusuario (sudo)**. El script `setup.sh` está diseñado para ejecutarse **sin privilegios de administrador**, instalando únicamente paquetes de R en una carpeta local (`software/R_LIBS`).

**¿Cuándo necesitas instalarlas?**
- En instalaciones limpias de Linux/WSL recién configuradas
- En sistemas mínimos (servidores, contenedores Docker base)
- Si nunca has compilado paquetes de R desde código fuente

**¿Por qué normalmente no hace falta?**
- **Ubuntu Desktop**: Muchas vienen preinstaladas
- **Entornos de desarrollo**: Si ya usaste R o compilaste software C/C++, probablemente las tengas
- **R preconfigurado**: Distribuciones como RStudio suelen instalarlas automáticamente

</details>

Si `setup.sh` falla, instala las dependencias del sistema:

```bash
sudo apt-get update && sudo apt-get install -y \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libcairo2-dev \
    libgmp-dev \
    libglpk-dev
```

<details>
<summary><b>¿Para qué sirve cada librería?</b> (click para expandir)</summary>

| Librería | Paquete R que la requiere | Función |
|----------|---------------------------|---------|
| `build-essential` | Todos (compilación) | Compiladores GCC/G++ para paquetes desde código fuente |
| `libcurl4-openssl-dev` | httr, curl | Conexiones HTTP/HTTPS para APIs (HPO, STRINGdb) |
| `libssl-dev` | openssl, httr | Encriptación SSL para conexiones seguras |
| `libxml2-dev` | XML, xml2, AnnotationDbi | Parsing de archivos XML (datos de Bioconductor) |
| `libfontconfig1-dev` | systemfonts, ragg | Configuración de fuentes para gráficos |
| `libfreetype6-dev` | ragg, systemfonts | Renderizado de texto en figuras PNG |
| `libharfbuzz-dev` | textshaping | Renderizado avanzado de texto (ggplot2) |
| `libfribidi-dev` | textshaping | Soporte para texto bidireccional |
| `libpng-dev` | png, ragg | Generación de imágenes PNG |
| `libtiff5-dev` | tiff | Soporte para imágenes TIFF |
| `libjpeg-dev` | jpeg | Soporte para imágenes JPEG |
| `libcairo2-dev` | cairo, ggraph | Gráficos vectoriales de alta calidad |
| `libgmp-dev` | gmp | Aritmética de precisión múltiple (igraph) |
| `libglpk-dev` | igraph | Optimización lineal para algoritmos de grafos |

</details>

---

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/boorja/project_template.git
cd project_template
```

### 2. Instalar dependencias de R

```bash
cd code
chmod 755 setup.sh launch.sh
./setup.sh
```

> **¿Errores de compilación?** Vuelve a la sección [Dependencias del Sistema](#dependencias-del-sistema-solo-si-hay-errores) e instala las librerías faltantes, luego ejecuta `./setup.sh` de nuevo.

El script `setup.sh`:
- Crea la carpeta `software/R_LIBS` para instalación local (sin permisos de administrador)
- Configura C++17 para compatibilidad con paquetes modernos
- Instala automáticamente todos los paquetes de R y Bioconductor necesarios

---

## 📊 Uso

### Ejecutar el análisis completo

```bash
cd code
./launch.sh
```

Los resultados se generarán en la carpeta `results/`.

---

## 🔬 Pipeline de Análisis

El script `analyse_raynaud.R` ejecuta el siguiente flujo de trabajo:

```
┌─────────────────────────────────────────────────────────────────┐
│  1. OBTENCIÓN DE DATOS                                          │
│     └─> Consulta API HPO (HP:0030880 - Raynaud Phenomenon)     │
│         └─> Extrae genes asociados al fenotipo                  │
├─────────────────────────────────────────────────────────────────┤
│  2. CONSTRUCCIÓN DE RED                                         │
│     └─> Mapeo de genes a STRINGdb (Homo sapiens, score > 700)  │
│         └─> Genera grafo no dirigido con igraph                 │
├─────────────────────────────────────────────────────────────────┤
│  3. PREPROCESAMIENTO                                            │
│     └─> Elimina nodos aislados (grado = 0)                     │
│         └─> Simplifica red (quita loops y aristas múltiples)   │
├─────────────────────────────────────────────────────────────────┤
│  4. ANÁLISIS TOPOLÓGICO                                         │
│     └─> Calcula métricas: densidad, grado, betweenness         │
│         └─> Identifica hubs y bottlenecks                       │
├─────────────────────────────────────────────────────────────────┤
│  5. DETECCIÓN DE COMUNIDADES                                    │
│     └─> Algoritmo de Louvain                                    │
│         └─> Calcula modularidad (Q)                             │
├─────────────────────────────────────────────────────────────────┤
│  6. ENRIQUECIMIENTO FUNCIONAL                                   │
│     └─> Gene Ontology (Biological Process) por cluster         │
│         └─> Corrección Benjamini-Hochberg (FDR < 0.05)         │
├─────────────────────────────────────────────────────────────────┤
│  7. VISUALIZACIÓN Y EXPORTACIÓN                                 │
│     └─> Genera figuras PNG (red, clusters, enriquecimiento)    │
│         └─> Exporta tablas CSV con todas las métricas          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📈 Resultados Generados

### Tablas (CSV)

| Archivo | Descripción |
|---------|-------------|
| `Network_Global_Statistics.csv` | Estadísticas globales: nodos, aristas, densidad, modularidad, clustering, diámetro |
| `Network_Nodes_Info.csv` | Información por gen: cluster, grado, betweenness, STRING_ID |
| `Network_Edges_Info.csv` | Lista de interacciones entre genes |
| `Enrichment_Cluster_X.csv` | Términos GO enriquecidos por cluster |

### Figuras (PNG)

| Archivo | Descripción |
|---------|-------------|
| `Red_Raynaud.png` | Visualización principal de la red PPI |
| `Clusters_Blobs.png` | Detección de comunidades con algoritmo de Louvain |
| `Enrichment_Cluster_X.png` | Dotplots de enriquecimiento GO por cluster |

### Métricas Calculadas

| Métrica | Descripción |
|---------|-------------|
| **Nodos totales** | Número de genes en la red |
| **Aristas totales** | Número de interacciones proteína-proteína |
| **Densidad (ρ)** | Proporción de conexiones existentes vs posibles |
| **Grado medio (k̄)** | Promedio de conexiones por gen |
| **Longitud de camino (L̄)** | Distancia promedio entre nodos |
| **Diámetro (d)** | Distancia máxima entre dos nodos |
| **Coeficiente de clustering (C)** | Tendencia a formar triángulos |
| **Modularidad (Q)** | Calidad de la partición en comunidades |

---

## ⚠️ Solución de Problemas

### Error: Fallo en compilación de paquetes

**Causa:** Faltan librerías del sistema.

**Solución:**
```bash
sudo apt-get update && sudo apt-get install -y \
    build-essential libcurl4-openssl-dev libssl-dev libxml2-dev \
    libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libfribidi-dev \
    libpng-dev libtiff5-dev libjpeg-dev libcairo2-dev libgmp-dev libglpk-dev
```

### Error: "Pacman no instalado"

**Causa:** No se ejecutó `setup.sh` o falló.

**Solución:**
```bash
cd code
./setup.sh
# Revisar setup.log si hay errores
```

### Error: Conexión a API HPO

**Causa:** Problemas de red o API temporalmente no disponible.

**Solución:**
- Verificar conexión a internet
- Intentar nuevamente más tarde
- Comprobar que `https://ontology.jax.org` está accesible

### Error: igraph/GLPK

**Causa:** Falta `libglpk-dev`.

**Solución:**
```bash
sudo apt-get install libglpk-dev
```

---

## 👥 Autores

Proyecto realizado para la asignatura de **Biología de Sistemas** - Universidad de Málaga.

| Autor | Contribución |
|-------|--------------|
| **Borja Pérez Herencia** | Desarrollo código R, análisis topológico, scripts de automatización |
| **Rubén Manuel Rodríguez Chamorro** | Desarrollo código R, consultas API, enriquecimiento funcional |
| **Martina Cebolla Salas** | Visualización, redacción introducción y discusión |
| **Emilio Sancho Carrera** | Funciones auxiliares, redacción conclusiones |


