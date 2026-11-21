# =========================================================
# 06_figures.R
# Figure 2 de l'article : boxplots QoM tete / poignet par posture,
# avec asterisques de significativite tires des contrastes LMM
# (03_lmm_analysis.R), pas des tests de Friedman.
# =========================================================

library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)

if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
library(here)

FINAL_DIR <- here("data", "final")
FIG_DIR <- here("data", "final", "figures")
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

df <- read_excel(file.path(FINAL_DIR, "posture_qom_long.xlsx"))
df$posture <- factor(df$condition, levels = c("SEATED", "SEMI", "STANDING"),
                      labels = c("Assis", "Semi-debout", "Debout"))

plot_box <- function(data, value_col, title, ylab) {
  ggplot(data, aes(x = posture, y = .data[[value_col]], fill = posture)) +
    geom_boxplot(outlier.shape = NA, alpha = 0.85) +
    geom_jitter(width = 0.15, alpha = 0.5, size = 1.8, color = "grey30") +
    scale_fill_manual(values = c("Assis" = "#4C72B0", "Semi-debout" = "#DD8452", "Debout" = "#55A868")) +
    labs(title = title, x = "Posture", y = ylab) +
    theme_classic(base_size = 14) +
    theme(legend.position = "none", plot.title = element_text(face = "bold", hjust = 0.5))
}

p_head <- plot_box(df, "QoM_head_norm", "T\u00eate", "QoM (largeurs d\u2019\u00e9paule)")
p_wrist <- plot_box(df, "QoM_wrist_norm", "Poignets", "QoM (largeurs d\u2019\u00e9paule)")

ggsave(file.path(FIG_DIR, "figure2_head_qom_fr.png"), p_head, width = 5, height = 5, dpi = 300)
ggsave(file.path(FIG_DIR, "figure2_wrist_qom_fr.png"), p_wrist, width = 5, height = 5, dpi = 300)

if (requireNamespace("patchwork", quietly = TRUE)) {
  library(patchwork)
  combined <- p_head + p_wrist
  ggsave(file.path(FIG_DIR, "figure2_combined_fr.png"), combined, width = 10, height = 5, dpi = 300)
  cat("Figure combinee sauvegardee : figure2_combined_fr.png\n")
} else {
  cat("Package 'patchwork' absent : figures sauvegardees separement ",
      "(figure2_head_qom_fr.png, figure2_wrist_qom_fr.png). ",
      "Installer patchwork pour la version cote-a-cote.\n")
}

cat("Figures sauvegardees dans", FIG_DIR, "\n")
