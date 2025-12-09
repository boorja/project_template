#!/usr/bin/env Rscript

# -----------------------------------------------------------------------------
# Título: Proyecto1 (Análisis de Red - Raynaud Phenomenon)
# Descripción: Genera redes, clusters, enriquecimiento y TODAS LAS ESTADÍSTICAS
# -----------------------------------------------------------------------------

# 1. CARGA DE LIBRERÍAS
if (!require("pacman")) stop("Pacman no instalado. Ejecuta setup.sh primero.")
suppressPackageStartupMessages({
  pacman::p_load(STRINGdb, igraph, clusterProfiler, org.Hs.eg.db, 
                 RColorBrewer, ggplot2, ggraph, jsonlite, scales, stringr, httr)
})

cat(">>> [1/7] Librerías cargadas.\n")

# 2. OBTENCIÓN DE DATOS (HPO API)
hpo_id <- "HP:0030880"
url <- paste0("https://ontology.jax.org/api/network/annotation/", hpo_id)
cat(">>> [2/7] Consultando API HPO para:", hpo_id, "...\n")

temp_file <- tempfile(fileext = ".json")
tryCatch({
  download.file(url, destfile = temp_file, quiet = TRUE, mode = "wb")
  data_content <- fromJSON(temp_file)
  genes_api <- data_content$genes$name
  unlink(temp_file)
}, error = function(e) {
  cat("   -> [ERROR] Fallo en API. Revise conexión.\n")
  quit(status = 1)
})

genes_totales <- unique(genes_api)
cat("   -> Genes recuperados:", length(genes_totales), "\n")

# 3. CONSTRUCCIÓN DE LA RED (STRINGdb)
cat(">>> [3/7] Construyendo red con STRINGdb...\n")

string_db <- STRINGdb$new(version="12.0", species=9606, 
                          score_threshold=400, input_directory="")

genes_mapped <- string_db$map(data.frame(gene=genes_totales), "gene", removeUnmappedRows = TRUE)
g <- string_db$get_subnetwork(genes_mapped$STRING_id)

# Corrección warning is.igraph
if (!suppressWarnings(is.igraph(g))) g <- graph_from_data_frame(d=g, directed=FALSE)
g <- igraph::simplify(g, remove.multiple = TRUE, remove.loops = TRUE)

# Guardamos ID original y mapeamos nombres
V(g)$string_id <- V(g)$name
indices <- match(V(g)$name, genes_mapped$STRING_id)
V(g)$name <- genes_mapped$gene[indices]
g <- delete_vertices(g, V(g)[is.na(V(g)$name)])

# 4. TOPOLOGÍA BÁSICA
densidad <- edge_density(g)
V(g)$degree <- degree(g)
V(g)$betweenness <- betweenness(g, normalized=TRUE)

# 5. CLUSTERING (Louvain)
cat(">>> [4/7] Detectando comunidades y generando gráfico de Blobs...\n")
set.seed(123)
comunidades <- cluster_louvain(g)
V(g)$cluster <- membership(comunidades)
Q_val <- modularity(comunidades)

# Layout para visualización
set.seed(123) 
L_blobs <- layout_with_fr(g)
num_clusters <- length(unique(V(g)$cluster))

# 1. Definir paleta base sólida (para nodos y leyenda)
# Nota: brewer.pal necesita mínimo 3 colores, por eso el max(3, ...)
paleta_base <- brewer.pal(max(3, num_clusters), "Set1")[1:num_clusters]

# 2. Asignar el color sólido a cada nodo según su cluster
V(g)$color <- paleta_base[V(g)$cluster]

# 3. Crear versión transparente para el fondo (blobs)
colores_blobs <- adjustcolor(paleta_base, alpha.f = 0.3)

# GUARDAR PNG
png("../results/Clusters_Blobs.png", width = 2400, height = 2400, res = 300)
plot(comunidades, g, layout = L_blobs,
     vertex.size = 5, vertex.label = V(g)$name, vertex.label.cex = 0.6,
     vertex.label.color = "black", vertex.label.dist = 0.8,
     edge.color = "gray80", edge.width = 0.5,
     col = V(g)$color,                         # Usa el color asignado al nodo
     mark.groups = communities(comunidades),
     mark.col = colores_blobs,                 # Usa el color transparente para el blob
     mark.border = "gray50",
     main = "Detección de Comunidades (Louvain)")

legend("topleft", legend = paste("Cluster", 1:num_clusters), 
       fill = paleta_base,                     # Usa la paleta sólida para la leyenda
       bty = "n", cex=0.8, title="Grupos")
dev.off()

# 5.5. EXPORTACIÓN DE DATOS (CSV)

cat(">>> [5/7] Generando tablas de datos (CSVs)...\n")

# A) ESTADÍSTICAS GLOBALES DE LA RED (Resumen General)
global_stats <- data.frame(
  Metric = c(
    "Total Nodes", 
    "Total Edges", 
    "Network Density", 
    "Average Degree", 
    "Avg Path Length", 
    "Diameter", 
    "Clustering Coefficient", 
    "Modularity (Q)"
  ),
  Value = c(
    vcount(g),
    ecount(g),
    round(edge_density(g), 5),
    round(mean(degree(g)), 2),
    round(mean_distance(g, directed = FALSE), 2),
    diameter(g),
    round(transitivity(g, type = "global"), 4),
    round(Q_val, 4)
  )
)
write.csv(global_stats, "../results/Network_Global_Statistics.csv", row.names = FALSE)

# B) Tabla de Nodos (Genes individuales)
df_nodes <- data.frame(
  Gene_Symbol = V(g)$name,
  STRING_ID   = V(g)$string_id,
  Cluster     = V(g)$cluster,
  Degree      = V(g)$degree,
  Betweenness = round(V(g)$betweenness, 5)
)
df_nodes <- df_nodes[order(df_nodes$Degree, decreasing = TRUE), ]
write.csv(df_nodes, "../results/Network_Nodes_Info.csv", row.names = FALSE)

# C) Tabla de Aristas (Interacciones)
df_edges <- igraph::as_data_frame(g, what="edges")
if("from" %in% colnames(df_edges)) {
    names(df_edges)[names(df_edges) == "from"] <- "Gene_A"
    names(df_edges)[names(df_edges) == "to"]   <- "Gene_B"
}
write.csv(df_edges, "../results/Network_Edges_Info.csv", row.names = FALSE)
# -----------------------------------------------------------------------------

# 6. ENRIQUECIMIENTO FUNCIONAL
cat(">>> [6/7] Análisis de enriquecimiento...\n")
cluster_ids <- unique(V(g)$cluster)

for (i in cluster_ids) {
  genes_cluster <- V(g)$name[V(g)$cluster == i]
  
  if (length(genes_cluster) >= 5) {
    tryCatch({
      ego <- enrichGO(gene = genes_cluster, OrgDb = org.Hs.eg.db, keyType = "SYMBOL",
                      ont = "BP", pAdjustMethod = "BH", pvalueCutoff = 0.05, qvalueCutoff = 0.2)
      
      if (!is.null(ego) && nrow(ego) > 0) {
        write.csv(as.data.frame(ego), paste0("../results/Enrichment_Cluster_", i, ".csv"))
        
        p_enrich <- suppressWarnings(suppressMessages(
            dotplot(ego, showCategory=15) + 
            scale_y_discrete(labels = function(x) str_wrap(x, width = 45)) +
            ggtitle(paste("Funciones Biológicas - Cluster", i)) +
            theme_minimal(base_size = 12) +
            theme(plot.title = element_text(face="bold", hjust = 0.5),
                    axis.text.y = element_text(size = 9))
        ))
        ggsave(paste0("../results/Enrichment_Cluster_", i, ".png"), 
               p_enrich, width = 9, height = 8, dpi = 300, bg="white")
      }
    }, error = function(e) {})
  }
}

# 7. VISUALIZACIÓN
cat(">>> [7/7] Generando Red...\n")
V(g)$cluster_factor <- as.factor(V(g)$cluster)
layout_premium <- create_layout(g, layout = "fr", niter = 1000)

p <- suppressMessages(
  ggraph(layout_premium) + 
    geom_edge_arc(color = "gray85", strength = 0.1, width = 0.6, alpha = 0.7) + 
    
    # Nodos (Puntos)
    geom_node_point(aes(fill = cluster_factor, size = degree), 
                    shape = 21, color = "white", stroke = 1.5) +   
    
    # Etiquetas de texto (Genes)
    # show.legend = FALSE evita la "a" en la leyenda
    geom_node_text(aes(label = name, size = degree), 
                   repel = TRUE, color = "black", fontface = "bold", 
                   bg.color = "white", bg.r = 0.15,
                   segment.color = "gray60", segment.size = 0.3,
                   force = 2, max.overlaps = 30,
                   show.legend = FALSE) + 
    
    scale_fill_brewer(palette = "Set1", name = "Cluster") + 
    
    # --- CAMBIO AQUÍ: Aumento del rango de tamaños (Texto y Nodos) ---
    # range = c(6, 16) asegura que la letra más pequeña sea legible (6)
    scale_size_continuous(range = c(6, 16), name = "Conectividad", breaks = c(5, 10, 15, 20)) +
    
    scale_radius(range = c(3, 5), guide = "none") + 
    theme_void() + 
    
    labs(title = "Red de Interacción Génica: Raynaud Phenomenon",
         subtitle = paste0("Análisis Topológico | ", vcount(g), " Genes | Q = ", round(Q_val, 2))
         # Sin caption (fuente eliminada)
    ) +
    
    theme(plot.margin = unit(c(1, 1, 1, 1), "cm"),
          plot.title = element_text(face = "bold", size = 18, hjust = 0.5, color = "#2c3e50"),
          legend.position = "right",
          # Ajustes de tamaño de leyenda (grandes)
          legend.title = element_text(size = 16, face = "bold"),
          legend.text = element_text(size = 14),
          legend.spacing.y = unit(0.5, 'cm'),
          legend.key.size = unit(1.0, "cm")) +
    
    guides(
      fill = guide_legend(override.aes = list(size = 8), order = 1),
      size = guide_legend(override.aes = list(shape = 21, fill = "gray50", color = "white", stroke = 1), order = 2))
)

ggsave("../results/Red_Raynaud.png", p, width = 14, height = 10, dpi = 300, bg="white")

cat(">>> PROCESO FINALIZADO. Resultados en la carpeta 'results'.\n")