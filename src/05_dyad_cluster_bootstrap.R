# =========================================================
# 05_dyad_cluster_bootstrap.R
#
# Bootstrap par cluster de dyade (5000 reechantillonnages), pour obtenir des
# IC95% sur les contrastes de posture qui respectent explicitement la
# structure de dependance des donnees (les deux membres d'une dyade sont
# reechantillonnes ENSEMBLE, jamais separement), en complement du LMM
# (03_lmm_analysis.R) qui modelise cette meme dependance via des effets
# aleatoires.
#
# Meme logique que le bootstrap par dyade utilise pour les IC de r/ICC(2,1)
# dans Article1_MP_VICON (cf. son README, section "Known limitations") -
# mais, contrairement a celui-ci, le script est ici committe dans le depot
# plutot que laisse hors pipeline.
#
# Statistique reechantillonnee : difference de moyenne du log(QoM) entre
# paires de postures (Standing-Seated, Standing-Semi, Semi-Seated), par
# segment (tete, poignet). Implementation vectorisee (matrices de base R,
# pas de dplyr dans la boucle) : ~5000 reechantillonnages en quelques
# secondes plutot que plusieurs minutes.
#
# Entree : data/final/posture_qom_long.xlsx
# Sortie : data/final/dyad_bootstrap_results.xlsx
# =========================================================

library(readxl)
library(dplyr)
library(tidyr)
library(writexl)

if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
library(here)

source(here("src", "config_r.R"))  # RANDOM_SEED, N_BOOT

FINAL_DIR <- here("data", "final")

df <- read_excel(file.path(FINAL_DIR, "posture_qom_long.xlsx"))
df$posture <- factor(df$condition, levels = c("SEATED", "SEMI", "STANDING"))

dyads <- sort(unique(df$dyad))
n_dyads <- length(dyads)

# ---------------------------------------------------------
# Pour un segment donne, construit une matrice (40 sujets x 3 postures) de
# log(QoM), avec un vecteur parallele donnant la dyade de chaque ligne.
# ---------------------------------------------------------
build_subject_matrix <- function(data, value_col) {
  wide <- data %>%
    select(dyad, subject, posture, value = all_of(value_col)) %>%
    mutate(value = log(value)) %>%
    pivot_wider(names_from = posture, values_from = value) %>%
    arrange(dyad, subject)
  list(
    dyad = wide$dyad,
    mat = as.matrix(wide[, c("SEATED", "SEMI", "STANDING")])
  )
}

contrasts_from_colmeans <- function(cm) {
  c(
    Standing_minus_Seated = unname(cm["STANDING"] - cm["SEATED"]),
    Standing_minus_Semi   = unname(cm["STANDING"] - cm["SEMI"]),
    Semi_minus_Seated     = unname(cm["SEMI"] - cm["SEATED"])
  )
}

bootstrap_dyad_cluster <- function(data, value_col, label) {
  built <- build_subject_matrix(data, value_col)
  mat <- built$mat            # 40 x 3, log(QoM)
  subj_dyad <- built$dyad     # dyade de chaque ligne (longueur 40)

  # observe
  obs <- contrasts_from_colmeans(colMeans(mat))

  # index des lignes (sujets) appartenant a chaque dyade, une fois
  rows_by_dyad <- split(seq_len(nrow(mat)), subj_dyad)

  set.seed(RANDOM_SEED)
  boot_mat <- matrix(NA_real_, nrow = N_BOOT, ncol = 3,
                      dimnames = list(NULL, names(obs)))

  for (i in seq_len(N_BOOT)) {
    sampled_dyads <- sample(dyads, size = n_dyads, replace = TRUE)
    row_idx <- unlist(rows_by_dyad[sampled_dyads], use.names = FALSE)
    cm <- colMeans(mat[row_idx, , drop = FALSE])
    boot_mat[i, ] <- contrasts_from_colmeans(cm)
  }

  ci <- apply(boot_mat, 2, quantile, probs = c(.025, .975))
  se <- apply(boot_mat, 2, sd)

  out <- data.frame(
    segment = label,
    contrast = names(obs),
    estimate_logQoM_diff = unname(obs),
    boot_SE = unname(se),
    CI95_lower = ci[1, ],
    CI95_upper = ci[2, ]
  )
  out$pct_boot_same_sign <- sapply(seq_along(obs), function(k) {
    100 * mean(sign(boot_mat[, k]) == sign(obs[k]))
  })
  rownames(out) <- NULL
  out
}

cat("Bootstrap par cluster de dyade -", N_BOOT, "reechantillonnages,", n_dyads, "dyades\n")

t0 <- Sys.time()
res_head <- bootstrap_dyad_cluster(df, "QoM_head_norm", "Head")
res_wrist <- bootstrap_dyad_cluster(df, "QoM_wrist_norm", "Upper limbs")
cat("Temps ecoule :", round(as.numeric(Sys.time() - t0, units = "secs"), 1), "s\n")

cat("\n--- Tete ---\n"); print(res_head)
cat("\n--- Poignet ---\n"); print(res_wrist)

all_results <- bind_rows(res_head, res_wrist)

write_xlsx(list(dyad_bootstrap = all_results),
           file.path(FINAL_DIR, "dyad_bootstrap_results.xlsx"))
cat("\nSauvegarde :", file.path(FINAL_DIR, "dyad_bootstrap_results.xlsx"), "\n")
