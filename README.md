# Proyecto de Biología de Sistemas
## Análisis de Red de Interacción Génica - Fenómeno de Raynaud

Este proyecto realiza un análisis de redes de interacción proteína-proteína para genes asociados al **Fenómeno de Raynaud** (HPO: HP:0030880), utilizando datos de la Human Phenotype Ontology (HPO) y STRINGdb.

---

## 📁 Estructura del Proyecto

```
project_template/
├── code/               # Scripts de ejecución
├── report/             # Documentación y memoria del proyecto
├── results/            # Resultados generados (tablas y figuras)
└── software/           # Librerías de R instaladas localmente
```

---

## 📂 Descripción de Carpetas

### `code/`
Contiene los scripts ejecutables del análisis. **Ver sección detallada más abajo.**

### `report/`
Contiene la memoria del proyecto en formato LaTeX:
- `report.tex` - Documento principal
- `bibliography/` - Referencias bibliográficas (.bib)
- `figures/` - Figuras para el informe
- `tex_files/` - Secciones del documento (introducción, métodos, resultados, discusión, conclusiones, anexo)

### `results/`
Carpeta donde se almacenan todos los resultados generados:
- **Tablas CSV:**
  - `Network_Global_Statistics.csv` - Estadísticas globales de la red (nodos, aristas, densidad, modularidad, etc.)
  - `Network_Nodes_Info.csv` - Información de cada gen (cluster, grado, betweenness)
  - `Network_Edges_Info.csv` - Lista de interacciones entre genes
  - `Enrichment_Cluster_X.csv` - Enriquecimiento funcional por cluster
- **Figuras PNG:**
  - `Red_Raynaud.png` - Visualización de la red de interacción
  - `Clusters_Blobs.png` - Detección de comunidades (Louvain)
  - `Enrichment_Cluster_X.png` - Gráficos de enriquecimiento GO

### `software/`
Contiene la carpeta `R_LIBS/` donde se instalan localmente todas las librerías de R necesarias. Esto permite ejecutar el proyecto sin necesidad de permisos de administrador para las librerías de R.

---

## 🖥️ Carpeta `code/` - Detalle

### Archivos

| Archivo | Descripción |
|---------|-------------|
| `setup.sh` | Script de configuración inicial. Instala todas las dependencias de R |
| `launch.sh` | Script de lanzamiento del análisis principal |
| `analyse_raynaud.R` | Script R con todo el pipeline de análisis |

### `setup.sh` - Instalación de dependencias

Este script configura el entorno e instala todas las librerías de R necesarias:
- Crea la carpeta `software/R_LIBS` para instalación local
- Utiliza binarios precompilados de Posit Package Manager (evita compilación)
- Instala: `STRINGdb`, `igraph`, `clusterProfiler`, `org.Hs.eg.db`, `ggplot2`, `ggraph`, y más

**Ejecución:**
```bash
cd code
chmod +x setup.sh
./setup.sh
```

### `launch.sh` - Ejecución del análisis

Script que configura las variables de entorno y ejecuta el análisis:
- Define `R_LIBS_USER` apuntando a las librerías locales
- Ejecuta `analyse_raynaud.R`

**Ejecución:**
```bash
cd code
chmod +x launch.sh
./launch.sh
```

### `analyse_raynaud.R` - Pipeline de análisis

Script R que realiza todo el análisis bioinformático:

1. **Obtención de datos** - Consulta la API de HPO para obtener genes asociados al Fenómeno de Raynaud
2. **Construcción de red** - Usa STRINGdb para crear la red de interacción proteína-proteína
3. **Preprocesamiento** - Limpieza de la red (elimina nodos aislados)
4. **Análisis topológico** - Calcula métricas: densidad, grado, betweenness, etc.
5. **Detección de comunidades** - Algoritmo de Louvain para identificar clusters
6. **Análisis de enriquecimiento** - Gene Ontology (GO) para cada cluster
7. **Visualización** - Genera gráficos de la red y enriquecimiento

---

## 🚀 Guía de Uso Rápido

### 1. Requisitos previos
- Sistema operativo: Linux/Ubuntu (o WSL en Windows)
- R instalado (versión 4.0+)
- Conexión a internet (para descargar datos de HPO y STRINGdb)

### 2. Instalación
```bash
cd code
chmod +x setup.sh launch.sh
./setup.sh
```

### 3. Ejecución
```bash
cd code
./launch.sh
```

### 4. Resultados
Los resultados se generarán en la carpeta `results/`

---

## ⚠️ Solución de Errores de Dependencias

Si durante la instalación (`setup.sh`) aparecen errores de compilación o dependencias faltantes, es probable que falten **librerías del sistema** que requieren permisos de administrador.

### ¿Por qué no están incluidas en `setup.sh`?

Estas librerías son **dependencias del sistema operativo** (no de R) y su instalación requiere permisos de **superusuario (sudo)**. El script `setup.sh` está diseñado para ejecutarse **sin permisos de administrador**, instalando únicamente las librerías de R en una carpeta local (`software/R_LIBS`).

No es posible automatizar la instalación de estas dependencias en `setup.sh` porque:
1. Requieren `sudo` (permisos de root)
2. Modifican directorios del sistema (`/usr/lib`, `/usr/include`)
3. El script debe poder ejecutarse por cualquier usuario sin privilegios especiales

### ¿Por qué normalmente no debería ser necesario instalarlas?

Estas librerías son **componentes básicos de desarrollo** que suelen venir preinstalados en la mayoría de distribuciones Linux o se instalan automáticamente al configurar un entorno de desarrollo. En sistemas con:
- **Ubuntu Desktop**: Muchas ya están incluidas
- **Entornos de desarrollo configurados**: Si ya has compilado software en C/C++ o usado R anteriormente, probablemente las tengas
- **Servidores o instalaciones mínimas**: Es más común que falten, ya que se omiten para reducir el tamaño del sistema

Si tu sistema es una instalación limpia o mínima (como WSL recién instalado), es posible que necesites instalarlas manualmente.

### Ejecutar los siguientes comandos (solo si hay errores):

```bash
sudo apt --fix-broken install
sudo apt-get install -y build-essential gfortran \
    libblas-dev liblapack-dev \
    libfontconfig1-dev libfreetype-dev \
    libpng-dev libtiff-dev libjpeg-dev \
    libxml2-dev libssl-dev libcurl4-openssl-dev \
    libharfbuzz-dev libfribidi-dev \
    libglpk-dev \
    libcairo2-dev
```

### ¿Para qué sirve cada librería?

| Librería | Uso |
|----------|-----|
| `build-essential`, `gfortran` | Compilación de paquetes R desde código fuente |
| `libblas-dev`, `liblapack-dev` | Álgebra lineal (usado por igraph, matrices) |
| `libfontconfig1-dev`, `libfreetype-dev` | Renderizado de texto en gráficos |
| `libpng-dev`, `libtiff-dev`, `libjpeg-dev` | Generación de imágenes PNG/TIFF/JPEG |
| `libxml2-dev` | Parsing XML (usado por AnnotationDbi) |
| `libssl-dev`, `libcurl4-openssl-dev` | Conexiones HTTPS (descargas de API) |
| `libharfbuzz-dev`, `libfribidi-dev` | Renderizado de texto avanzado |
| `libglpk-dev` | Optimización (usado por igraph) |

Después de instalar estas dependencias, vuelve a ejecutar `./setup.sh`.

---

## 📊 Métricas Calculadas

El análisis genera las siguientes métricas de red:

- **Nodos totales** - Número de genes en la red
- **Aristas totales** - Número de interacciones
- **Densidad** - Proporción de conexiones existentes vs posibles
- **Grado medio** - Promedio de conexiones por gen
- **Longitud media de camino** - Distancia promedio entre nodos
- **Diámetro** - Distancia máxima entre dos nodos
- **Coeficiente de clustering** - Tendencia a formar grupos
- **Modularidad (Q)** - Calidad de la partición en comunidades

---

## 📚 Tecnologías Utilizadas

- **R** - Lenguaje de análisis estadístico
- **STRINGdb** - Base de datos de interacciones proteína-proteína
- **igraph** - Análisis y visualización de redes
- **clusterProfiler** - Análisis de enriquecimiento funcional
- **ggplot2/ggraph** - Visualización de datos y redes
- **HPO API** - Human Phenotype Ontology

---

## 👤 Autor

Proyecto realizado para la asignatura de **Biología de Sistemas**.

---

## 📄 Licencia

Proyecto académico - Uso educativo.
