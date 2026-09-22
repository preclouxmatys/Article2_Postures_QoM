# Posture and Movement Dynamics in Spontaneous Dyadic Conversation

This repository contains the full, reproducible analysis pipeline for the study
of how postural condition (seated, semi-standing, standing) affects head and
upper-limb Quantity of Movement (QoM) during spontaneous face-to-face dyadic
conversation.

Twenty dyads (N = 40 participants) were recorded with a Vicon optoelectronic
motion capture system (100 Hz, 8 cameras) across the three postural conditions,
giving 120 participant x condition observations. This is the companion
repository to [`Article1_MP_VICON`](https://github.com/preclouxmatys/Article1_MP_VICON)
(the MediaPipe vs Vicon concurrent-validity study), with which it **shares its
Vicon data and QoM computation** rather than duplicating it — see
"Data availability" below.

## Repository structure

```
Article2_Posture_QoM/
├── src/
│   ├── config.py                        # paths and processing parameters (Python)
│   ├── config_r.R                       # same constants, R side
│   ├── 01_prepare_posture_data.py       # extracts the Vicon-only columns needed here from Article1's shared table
│   ├── 02_descriptive_stats.R           # Table 1: median/Q1-Q3/mean/SD by segment x posture
│   ├── 03_lmm_analysis.R                # PRIMARY ANALYSIS: linear mixed models (see below)
│   ├── 04_friedman_robustness.R         # Friedman/Wilcoxon non-parametric robustness check
│   ├── 05_dyad_cluster_bootstrap.R      # dyad-cluster bootstrap (5,000 resamples) for the posture contrasts
│   └── 06_figures.R                     # Figure 2: head/wrist QoM boxplots by posture
├── data/
│   ├── raw/            # comparison_qom_long.xlsx: copied from Article1_MP_VICON (see below)
│   ├── intermediate/   # generated automatically, not versioned
│   └── final/           # final tables, statistics, and figures (versioned)
├── Article2_Posture_QoM.Rproj
├── requirements.txt
└── README.md
```

## Why a mixed-model pipeline

The original analysis (in the M2 thesis this article is drawn from) tested each
of the 40 participants as an independent observation with Friedman/Wilcoxon
tests. This ignores that the 40 participants are not independent: they are
nested in 20 dyads, and the two members of a dyad share the interaction context
(same partner, same conversation). This pipeline instead treats posture as a
fixed effect in a linear mixed model with random intercepts for **dyad** and
**participant** (nested in dyad), on log-transformed QoM (right-skewed, see
Table 1). It also tests the Posture x Segment interaction directly in a single
combined model, rather than informally comparing two separate per-segment
effect sizes. The Friedman/Wilcoxon analysis is retained as a robustness check
(`04_friedman_robustness.R`), run alongside the primary model rather than
replaced by it, and a dyad-cluster bootstrap (`05_dyad_cluster_bootstrap.R`)
gives a third, model-free look at the same dependency structure — the same
logic used for the r/ICC confidence intervals in `Article1_MP_VICON`, but
committed here as an actual script rather than left as an undocumented,
unreproducible step (see "Known limitations" in that repo's README, which
references this bootstrap without a corresponding committed script).

## Setup

R (>= 4.0) is required. Packages used across the pipeline: `readxl`, `dplyr`,
`tidyr`, `writexl`, `lme4`, `lmerTest`, `emmeans`, `ggplot2`, `here`
(optionally `patchwork`, for the combined side-by-side figure). Python 3 with
`pandas` and `openpyxl` is required for `01_prepare_posture_data.py`.

```bash
pip install -r requirements.txt
Rscript -e 'install.packages(c("readxl","dplyr","tidyr","writexl","lme4","lmerTest","emmeans","ggplot2","here","patchwork"))'
```

## Data availability

Raw Vicon marker trajectories and videos are **not** included in this repository,
nor in `Article1_MP_VICON` (identifiable participant data, ethics approval CER-UM,
avis n° UM 2025-101bis) — this is the one layer of the data that stays private in
both repositories, for ethics reasons, and that a reader cannot regenerate from
scratch. Everything derived from it that this pipeline actually needs, however,
**is** included and versioned here: `data/raw/comparison_qom_long.xlsx` is the
already-anonymized, already-derived long-format QoM table (dyad ID, condition,
participant ID, shoulder width, QoM values — no video, no marker trajectories, no
names), computed once in `Article1_MP_VICON` (`src/02_vicon_compute_qom_shoulder.py`)
and shipped as-is in this repository's own `data/raw/`. A clone of this repository
therefore reproduces the full analysis end to end on its own, with no dependency
on `Article1_MP_VICON` at runtime — that repository is credited as the origin of
this table, not required to use this one.

**Note on what is versioned here.** Unlike `Article1_MP_VICON` — where `data/raw/`
(the actual raw videos and Vicon CSVs) is git-ignored and only `data/final/` is
committed — this repository commits both `data/raw/comparison_qom_long.xlsx` and
`data/final/`, because, as described above, nothing in this repository's `data/raw/`
is itself raw identifiable data; it is one step further downstream already.
`.gitignore` here only excludes `data/intermediate/` (unused
by this pipeline, kept only for structural parity with Article1) and standard
junk (`__pycache__/`, `.Rhistory`, etc.).

**Head QoM definition.** This pipeline uses the "midpoint" head QoM definition
established in `Article1_MP_VICON` (midpoint of the two temple markers computed
per frame, then filtered and cumulated once), not the "sum" definition
originally used in the M2 thesis (the two temple markers filtered and cumulated
separately, then summed). The "sum" definition roughly doubles the head QoM
magnitude relative to "midpoint" as an artifact of combining two independently
noisy signals rather than one — see `Article1_MP_VICON/README.md` for the
"scale mismatch" this was found to cause. **This means the head QoM values
reported here differ from the ones in the original M2 thesis**; wrist/upper-limb
values are unaffected, since the wrist QoM definition did not change. `posture`
is ordered `SEATED < SEMI < STANDING` throughout.

## Reproducing the analysis

Run the scripts in order from the `src/` directory:

```bash
cd src
python3 01_prepare_posture_data.py
Rscript 02_descriptive_stats.R
Rscript 03_lmm_analysis.R
Rscript 04_friedman_robustness.R
Rscript 05_dyad_cluster_bootstrap.R
Rscript 06_figures.R
```

`01_prepare_posture_data.py` asserts 20 dyads / 40 subjects / 120 rows on load,
so any mismatch with the shared Article1 table is caught immediately. The R
scripts rely on the `here` package for path resolution; `.here` and
`Article2_Posture_QoM.Rproj` at the repository root anchor it, so scripts must
be run with the repository (not `src/`) reachable as an ancestor directory —
running them from `src/` as shown above works correctly.

## Main results

**Table 1 — Descriptives (QoM, shoulder-width-normalized units)**

| Segment | Posture | n | Median | Q1–Q3 | Mean (SD) |
|---|---|---|---|---|---|
| Head | Seated | 40 | 21.86 | 18.18–29.58 | 23.89 (9.73) |
| Head | Semi-standing | 40 | 22.07 | 19.19–28.81 | 23.46 (8.02) |
| Head | Standing | 40 | 27.51 | 19.87–34.06 | 27.56 (9.81) |
| Upper limbs | Seated | 40 | 61.26 | 37.92–75.80 | 65.71 (51.78) |
| Upper limbs | Semi-standing | 40 | 58.29 | 33.15–82.97 | 67.48 (47.40) |
| Upper limbs | Standing | 40 | 122.74 | 82.03–154.51 | 126.01 (68.16) |

**Combined LMM — log(QoM) ~ posture * segment + (1|dyad) + (1|subject)**

| Term | F | df | p |
|---|---|---|---|
| Posture | 34.85 | 2, 195 | 1.15e-13 |
| Segment | 404.77 | 1, 195 | 1.84e-49 |
| Posture x Segment | 14.79 | 2, 195 | **1.05e-06** |

The Posture x Segment interaction is significant: the postural effect is not
uniform across segments, directly confirming (rather than informally inferring
from two separate effect sizes) that posture affects the upper limbs more than
the head. Variance decomposition of the combined model: dyad 31.2%, participant
22.4%, residual 46.4% — dyad membership alone accounts for close to a third of
total variance, confirming that treating the 40 participants as independent
(as in the Friedman-only analysis) would have been inappropriate.

**Per-segment models — log(QoM) ~ posture + (1|dyad) + (1|subject)**

| Segment | Posture F | df | p | Standing vs Seated | Standing vs Semi | Semi vs Seated |
|---|---|---|---|---|---|---|
| Head | 6.34 | 2, 78 | .0028 | p=.0079 | p=.0091 | n.s. |
| Upper limbs | 42.09 | 2, 78 | 4.0e-13 | p=2.1e-11 | p=6.3e-11 | n.s. |

**Dyad-cluster bootstrap (5,000 resamples, 95% CI on log(QoM) contrasts)**

| Segment | Contrast | Estimate | 95% CI | % resamples same sign |
|---|---|---|---|---|
| Head | Standing − Seated | 0.160 | [0.064, 0.270] | 99.9% |
| Head | Standing − Semi | 0.158 | [0.077, 0.236] | 100% |
| Head | Semi − Seated | 0.002 | [-0.119, 0.136] | 51.0% |
| Upper limbs | Standing − Seated | 0.766 | [0.610, 0.938] | 100% |
| Upper limbs | Standing − Semi | 0.743 | [0.488, 1.024] | 100% |
| Upper limbs | Semi − Seated | 0.023 | [-0.193, 0.230] | 58.9% |

**Friedman robustness check** (non-parametric, no dyad-clustering correction):
Head, chi2(2)=14.55, p=.0007, Kendall's W=.182; Upper limbs, chi2(2)=38.85,
p=3.7e-09, W=.486. Both segments show the same seated≈semi < standing pattern
as the LMM and bootstrap (post-hoc: Seated vs Semi n.s. for both segments;
Standing differs from both seated and semi, all p_bonferroni < .006).

Full results tables are in `data/final/*.xlsx`, figures in
`data/final/figures/`.

## A note on the head-segment post-hoc discrepancy

Three independent analyses (the per-segment LMM, the Friedman test, and the
dyad-cluster bootstrap) all agree that head QoM is elevated in standing versus
both seated and semi-standing. However, the **segment-specific post-hoc
contrasts extracted from the combined interaction model** (`emmeans(m_combined,
~ posture | segment)`, Bonferroni-corrected across all 6 posture x segment
comparisons rather than 3) come out non-significant for head (Standing vs
Seated p=.223, Standing vs Semi p=.236), even though the same contrasts are
clearly significant in the standalone per-segment head model above. This is
not a contradiction in the data: it reflects (1) a stricter multiple-comparison
correction in the combined model (6 comparisons instead of 3) and (2) pooling
residual variance across both segments, which is appropriate for testing the
interaction itself but is a more conservative basis for a segment-specific
post-hoc than a model fit to that segment alone. In other words, the head
effect is real and directionally consistent everywhere it is tested, but is
smaller than the upper-limb effect and does not survive the more conservative
correction used for the combined model's own post-hoc contrasts — which is
itself part of the Posture x Segment interaction story (the effect is weaker
for the head, and this weakness is precisely what the significant interaction
term detects).

## Known limitations

- This pipeline reuses Article1_MP_VICON's Vicon-derived QoM rather than
  recomputing it, so any correction to that upstream computation must be
  propagated manually (see `01_prepare_posture_data.py`).
- The mixed models and dyad-cluster bootstrap correct for non-independence
  from dyad membership and repeated participant measures, but the design still
  has only 20 dyads; random-effect variance estimates at the dyad level should
  be interpreted with that in mind.
- Head QoM values differ from the M2 thesis this article was originally drawn
  from, due to the midpoint-vs-sum definition change described above under
  "Data availability". Upper-limb (wrist) values are unchanged.

## Citation

*To be completed upon submission.*

## Contact

Matys Precloux — EuroMov, University of Montpellier.
