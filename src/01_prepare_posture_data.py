"""
01_prepare_posture_data.py

Prepare le jeu de donnees Vicon pour l'article "posture" a partir de la table
deja construite et versionnee dans Article1_MP_VICON (memes 20 dyades, meme
protocole, meme filtrage Butterworth 4e ordre / 6 Hz - cf. config.py).

Ce script ne recalcule PAS le QoM depuis les CSV Vicon bruts : il reutilise
la colonne Vicon (QDM_*_VICON_*) de la table de comparaison MediaPipe vs
Vicon, en ignorant les colonnes MediaPipe, qui ne concernent pas cet article.
Les deux articles partagent donc une seule source de verite pour le QoM
Vicon, au lieu d'avoir deux implementations paralleles du meme calcul.

Entree : data/raw/comparison_qom_long.xlsx
         (copie manuelle de Article1_MP_VICON/data/final/comparison_qom_long.xlsx -
          voir README.md, section "Donnees partagees avec Article1_MP_VICON")
Sortie : data/final/posture_qom_long.xlsx
         format long, 120 lignes (20 dyades x 3 conditions x 2 participants)
"""

from pathlib import Path

import pandas as pd

import config

INPUT_PATH = Path(config.SHARED_VICON_TABLE)
OUTPUT_PATH = Path(config.FINAL_DIR) / "posture_qom_long.xlsx"

POSTURE_ORDER = ["SEATED", "SEMI", "STANDING"]


def main():
    if not INPUT_PATH.exists():
        raise FileNotFoundError(
            f"{INPUT_PATH} introuvable.\n"
            "Copiez Article1_MP_VICON/data/final/comparison_qom_long.xlsx vers "
            f"{INPUT_PATH} avant de lancer ce script (voir README.md)."
        )

    src = pd.read_excel(INPUT_PATH)

    required = [
        "dyad", "condition", "pid", "shoulder_width_vicon_mm",
        "QDM_WRIST_VICON_mm", "QDM_HEAD_VICON_mm",
        "QDM_WRIST_VICON_norm", "QDM_HEAD_VICON_norm",
    ]
    missing = [c for c in required if c not in src.columns]
    if missing:
        raise ValueError(f"Colonnes manquantes dans {INPUT_PATH} : {missing}")

    df = src[required].rename(columns={
        "shoulder_width_vicon_mm": "shoulder_width_mm",
        "QDM_WRIST_VICON_mm": "QoM_wrist_mm",
        "QDM_HEAD_VICON_mm": "QoM_head_mm",
        "QDM_WRIST_VICON_norm": "QoM_wrist_norm",
        "QDM_HEAD_VICON_norm": "QoM_head_norm",
    }).copy()

    df["posture"] = pd.Categorical(df["condition"], categories=POSTURE_ORDER, ordered=True)
    df["subject"] = df["dyad"].astype(str) + "_" + df["pid"].astype(str)

    n_dyads = df["dyad"].nunique()
    n_subjects = df["subject"].nunique()
    print(f"Dyades : {n_dyads} | Sujets : {n_subjects} | Lignes : {len(df)}")
    assert n_dyads == 20, f"Attendu 20 dyades, trouve {n_dyads}"
    assert n_subjects == 40, f"Attendu 40 sujets, trouve {n_subjects}"
    assert len(df) == 120, f"Attendu 120 lignes, trouve {len(df)}"

    n_missing = df[["QoM_wrist_norm", "QoM_head_norm"]].isna().any(axis=1).sum()
    print(f"Lignes avec une valeur manquante : {n_missing}/{len(df)}")
    if n_missing:
        print(df.loc[df[["QoM_wrist_norm", "QoM_head_norm"]].isna().any(axis=1), ["subject", "condition"]])

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_excel(OUTPUT_PATH, index=False)
    print(f"Sauvegarde : {OUTPUT_PATH} ({len(df)} lignes)")


if __name__ == "__main__":
    main()
