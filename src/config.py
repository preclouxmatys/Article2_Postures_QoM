import os

# --- Chemins vers les données brutes (internes au repo, jamais commitées) ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VICON_CSV_DIR = os.path.join(BASE_DIR, "data", "raw", "vicon_csv")

# --- Table Vicon partagée avec Article1_MP_VICON (deja traitee, versionnee la-bas) ---
# Ce pipeline reutilise directement la sortie Vicon d'Article1_MP_VICON
# (src/02_vicon_compute_qom_shoulder.py, definition QoM tete = point milieu,
# cf. data/final/comparison_qom_long.xlsx de ce repo). Voir 01_prepare_posture_data.py.
SHARED_VICON_TABLE = os.path.join(
    BASE_DIR, "data", "raw", "comparison_qom_long.xlsx"
)

# --- Chemins internes au repo (générés automatiquement) ---
INTERMEDIATE_DIR = os.path.join(BASE_DIR, "data", "intermediate")
FINAL_DIR = os.path.join(BASE_DIR, "data", "final")
FIG_DIR = os.path.join(BASE_DIR, "data", "final", "figures")

os.makedirs(INTERMEDIATE_DIR, exist_ok=True)
os.makedirs(FINAL_DIR, exist_ok=True)
os.makedirs(FIG_DIR, exist_ok=True)

# --- Paramètres d'acquisition (identiques à Article1_MP_VICON) ---
FS_VICON = 100.0

# --- Paramètres de filtrage (Butterworth passe-bas, zero-phase) ---
BUTTER_ORDER = 4
CUTOFF_HZ = 6.0

# --- Definition du QoM tete ---
# "midpoint" (recommande, coherent avec Article1_MP_VICON) : point milieu des
# deux marqueurs de tempe calcule frame par frame, PUIS filtre et cumule une
# seule fois. "sum" (ancienne definition, memoire M2) : somme des QoM des deux
# marqueurs de tempe calcules separement (double artificiellement l'amplitude
# du signal tete par rapport a "midpoint" - cf. Article1_MP_VICON/README.md,
# section decrivant le "scale mismatch" corrige pour la comparaison a MediaPipe).
HEAD_QOM_DEFINITION = "midpoint"

# --- Reproductibilité (bootstrap, permutation) ---
RANDOM_SEED = 42
N_BOOT = 5000
