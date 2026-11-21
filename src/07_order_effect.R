# =========================================================
# 07_order_effect.R
# Effet exploratoire du rang de presentation (1er, 2e, 3e) sur la QoM,
# test de Friedman par segment (meme logique que 04_friedman_robustness.R).
#
# Ordre des postures (carre latin a 3 ordres qui tournent d'une dyade a l'autre) :
#   D01, D04, D07, ... : SEATED, SEMI, STANDING
#   D02, D05, D08, ... : SEMI, STANDING, SEATED
#   D03, D06, D09, ... : STANDING, SEATED, SEMI
# Les scenarios de conversation etant toujours presentes dans le meme ordre,
# le rang de presentation est confondu avec le scenario.
# =========================================================

library(readxl)
library(dplyr)
library(tidyr)
library(writexl)
library(here)

FINAL_DIR <- here("data", "final")
df <- read_excel(file.path(FINAL_DIR, "posture_qom_long.xlsx"))

orders <- list(c("SEATED", "SEMI", "STANDING"),
               c("SEMI", "STANDING", "SEATED"),
               c("STANDING", "SEATED", "SEMI"))

df <- df %>%
  mutate(dyad_num = as.integer(sub("D", "", dyad)),
         order_id = (dyad_num - 1) %% 3 + 1) %>%
  rowwise() %>%
  mutate(rank = match(condition, orders[[order_id]])) %>%
  ungroup()

cat("Nombre de dyades par ordre :\n")
print(df %>% distinct(dyad, order_id) %>% count(order_id))

run_order <- function(col, label) {
  mat <- df %>%
    select(subject, rank, value = all_of(col)) %>%
    pivot_wider(names_from = rank, values_from = value) %>%
    arrange(subject)
  m <- as.matrix(mat[, c("1", "2", "3")])
  ft <- friedman.test(m)
  w <- unname(ft$statistic) / (nrow(m) * (ncol(m) - 1))
  cat(sprintf("\n=== Effet d'ordre : %s (n=%d) ===\n", label, nrow(m)))
  print(ft)
  cat(sprintf("Kendall's W = %.3f\n", w))
  cat("Medianes par rang :", round(apply(m, 2, median), 1), "\n")
  data.frame(label = label, n = nrow(m), chi2 = unname(ft$statistic),
             df = unname(ft$parameter), p = ft$p.value, kendall_w = w,
             median_rank1 = median(m[, 1]), median_rank2 = median(m[, 2]),
             median_rank3 = median(m[, 3]))
}

res <- bind_rows(run_order("QoM_head_norm", "Head"),
                 run_order("QoM_wrist_norm", "Upper limbs"))
write_xlsx(list(order_effect = res), file.path(FINAL_DIR, "order_effect_results.xlsx"))
cat("\nSauvegarde :", file.path(FINAL_DIR, "order_effect_results.xlsx"), "\n")
