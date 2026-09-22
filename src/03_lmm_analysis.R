# =========================================================
# 03_lmm_analysis.R
# Analyse primaire : modeles lineaires mixtes (LMM)
#
# Corrige la limite methodologique identifiee sur la premiere version de
# l'article (les 40 participants sont imbriques dans 20 dyades et ne sont
# pas des observations independantes ; les tests de Friedman/Wilcoxon
# individuels ne modelisent pas cette structure). Effets aleatoires pour
# dyade et participant (imbrique dans dyade). QoM log-transforme (fortement
# asymetrique a droite, cf. Table 1).
#
# 1) Modele combine (tete + poignet empiles) avec interaction
#    Posture x Segment, pour tester directement si l'effet de la posture
#    differe selon le segment (au lieu de comparer informellement deux
#    tailles d'effet issues de deux tests separes).
# 2) Modeles par segment (tete, poignet), pour rester comparables a la
#    structure de reporting du memoire (Table 2/3).
#
# Entree : data/final/posture_qom_long.xlsx
# Sortie : data/final/lmm_results.xlsx
#          data/final/lmm_diagnostics.xlsx
# =========================================================

library(readxl)
library(dplyr)
library(tidyr)
library(lme4)
library(lmerTest)
library(emmeans)
library(writexl)

if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
library(here)

FINAL_DIR <- here("data", "final")

df <- read_excel(file.path(FINAL_DIR, "posture_qom_long.xlsx"))
df$posture <- factor(df$condition, levels = c("SEATED", "SEMI", "STANDING"))
df$dyad <- factor(df$dyad)
df$subject <- factor(df$subject)

# ---------------------------------------------------------
# 1) Modele combine : log(QoM) ~ posture * segment + (1|dyad) + (1|subject)
# ---------------------------------------------------------
long <- df %>%
  select(dyad, subject, posture, QoM_head_norm, QoM_wrist_norm) %>%
  pivot_longer(cols = c(QoM_head_norm, QoM_wrist_norm),
               names_to = "segment", values_to = "QoM") %>%
  mutate(
    segment = recode(segment, QoM_head_norm = "Head", QoM_wrist_norm = "Wrist"),
    segment = factor(segment, levels = c("Head", "Wrist")),
    logQoM = log(QoM)
  )

cat("\n=== Modele combine (interaction Posture x Segment) ===\n")
m_combined <- lmer(
  logQoM ~ posture * segment + (1 | dyad) + (1 | subject),
  data = long, REML = TRUE,
  control = lmerControl(optimizer = "bobyqa")
)
print(summary(m_combined))

anova_combined <- anova(m_combined)  # Type III, Satterthwaite df (lmerTest)
print(anova_combined)

# Composantes de variance (quantifie explicitement le poids de la dyade)
vc <- as.data.frame(VarCorr(m_combined))
vc$pct_variance <- 100 * vc$vcov / sum(vc$vcov)
cat("\nComposantes de variance :\n")
print(vc)

# ---------------------------------------------------------
# 2) Contrastes post-hoc
#    - Si interaction significative : effets simples de la posture, PAR segment
#    - Sinon : effet principal de la posture, tous segments confondus
# ---------------------------------------------------------
interaction_p <- anova_combined["posture:segment", "Pr(>F)"]
cat(sprintf("\nInteraction Posture x Segment : p = %.4f\n", interaction_p))

emm_by_segment <- emmeans(m_combined, ~ posture | segment)
posthoc_by_segment <- pairs(emm_by_segment, adjust = "bonferroni")
cat("\nContrastes post-hoc (posture, par segment) :\n")
print(posthoc_by_segment)

emm_main <- emmeans(m_combined, ~ posture)
posthoc_main <- pairs(emm_main, adjust = "bonferroni")
cat("\nContrastes post-hoc (posture, effet principal, tous segments) :\n")
print(posthoc_main)

# ---------------------------------------------------------
# 3) Modeles par segment (comparables a Table 2/3 du premier draft)
# ---------------------------------------------------------
fit_segment_model <- function(data, label) {
  cat(sprintf("\n=== Modele %s : log(QoM) ~ posture + (1|dyad) + (1|subject) ===\n", label))
  m <- lmer(log(QoM) ~ posture + (1 | dyad) + (1 | subject), data = data,
            control = lmerControl(optimizer = "bobyqa"))
  a <- anova(m)
  print(a)
  emm <- emmeans(m, ~posture)
  ph <- pairs(emm, adjust = "bonferroni")
  print(ph)
  list(model = m, anova = a, posthoc = ph)
}

head_data <- df %>% transmute(dyad, subject, posture, QoM = QoM_head_norm)
wrist_data <- df %>% transmute(dyad, subject, posture, QoM = QoM_wrist_norm)

res_head <- fit_segment_model(head_data, "Tete")
res_wrist <- fit_segment_model(wrist_data, "Poignet")

# ---------------------------------------------------------
# 4) Export
# ---------------------------------------------------------
anova_combined_df <- as.data.frame(anova_combined) %>%
  tibble::rownames_to_column("term")

posthoc_by_segment_df <- as.data.frame(posthoc_by_segment)
posthoc_main_df <- as.data.frame(posthoc_main)

anova_head_df <- as.data.frame(res_head$anova) %>% tibble::rownames_to_column("term")
anova_wrist_df <- as.data.frame(res_wrist$anova) %>% tibble::rownames_to_column("term")
posthoc_head_df <- as.data.frame(res_head$posthoc)
posthoc_wrist_df <- as.data.frame(res_wrist$posthoc)

write_xlsx(
  list(
    combined_anova = anova_combined_df,
    combined_posthoc_by_segment = posthoc_by_segment_df,
    combined_posthoc_main = posthoc_main_df,
    variance_components = vc,
    head_anova = anova_head_df,
    head_posthoc = posthoc_head_df,
    wrist_anova = anova_wrist_df,
    wrist_posthoc = posthoc_wrist_df
  ),
  file.path(FINAL_DIR, "lmm_results.xlsx")
)
cat("\nSauvegarde :", file.path(FINAL_DIR, "lmm_results.xlsx"), "\n")

# ---------------------------------------------------------
# 5) Diagnostics (normalite des residus, homoscedasticite)
# ---------------------------------------------------------
png(file.path(FINAL_DIR, "figures", "lmm_diagnostics_combined.png"), width = 1000, height = 500)
par(mfrow = c(1, 2))
qqnorm(resid(m_combined), main = "QQ-plot des residus (modele combine)")
qqline(resid(m_combined))
plot(fitted(m_combined), resid(m_combined),
     main = "Residus vs valeurs ajustees", xlab = "Valeurs ajustees", ylab = "Residus")
abline(h = 0, lty = 2)
dev.off()
cat("Diagnostics sauvegardes : data/final/figures/lmm_diagnostics_combined.png\n")
