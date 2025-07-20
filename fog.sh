#!/bin/bash

# Script fog - Processus caché dans le brouillard
# Hack#3 - Processus invisible et persistant

# Configuration
TRACE_FILE="$HOME/.cache/fog_trace"
DB_FILE="$HOME/.local/share/fog.db"
PROC_NAME="[kworker/0:0-events]"
DELAY=30

# Créer les répertoires nécessaires
mkdir -p "$(dirname "$TRACE_FILE")" "$(dirname "$DB_FILE")"

# --- Fonctions utilisées par le script principal ---
# Initialiser la base de données SQLite
init_db() {
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        pid INTEGER,
        status TEXT
    );"
}

# Fonction pour se cacher
hide_process() {
    local sqlite_path="$1" # Récupérer le chemin complet de sqlite3
    # Le script enfant est défini dans une variable. C'est plus robuste que `export -f`.
    # Les variables sont passées en arguments ($1, $2, $3, $4) au lieu d'être exportées.
    local child_script='
        # Fonctions redéfinies pour le contexte du fils
        log_trace() {
            # $1: DB_FILE, $2: TRACE_FILE, $4: SQLITE_PATH
            echo "[$(date "+%Y-%m-%d %H:%M:%S")] Processus actif - PID: $$" >> "$2"
            "$4" "$1" "INSERT INTO logs (timestamp, pid, status) VALUES (datetime('\''now'\''), $$, '\''active'\'');"
        }

        # Boucle principale du processus fils
        while true; do
            log_trace "$1" "$2" "$3" "$4" || exit 1 # Passer les arguments à la fonction
            sleep "$3"
        done
    '

    # Lancer le processus fils détaché avec un nom masqué.
    # La sortie est redirigée vers un fichier de log pour le débogage.
    local child_log_file="/tmp/fog_child.log"
    
    # `setsid` ne peut pas exécuter `exec` directement car `exec` est un builtin du shell.
    # Nous devons donc lancer un shell qui, lui, utilisera `exec`.
    # Les arguments sont passés au shell externe, puis à l'interne.
    setsid /bin/bash -c 'exec -a "$1" /bin/bash -c "$2" -- "$3" "$4" "$5" "$6"' -- \
        "$PROC_NAME" \
        "$child_script" \
        "$DB_FILE" \
        "$TRACE_FILE" \
        "$DELAY" \
        "$sqlite_path" >"$child_log_file" 2>&1 &

    # Laisser une seconde au processus fils pour démarrer (et potentiellement échouer)
    # avant de supprimer son fichier de log pour ne laisser aucune trace de notre passage.
    # Une fois le débogage terminé, vous pouvez réactiver ces lignes pour le nettoyage.
    sleep 1
    rm -f "$child_log_file"
}

# Fonction principale
main() {
    # Initialiser la DB depuis le parent pour s'assurer que les fichiers existent
    init_db

    # Trouver le chemin complet de sqlite3 pour le rendre indépendant du PATH
    local sqlite_path=$(which sqlite3)
    if [ -z "$sqlite_path" ]; then
        echo "Erreur : La commande 'sqlite3' est introuvable. Veuillez l'installer." >&2
        exit 1
    fi

    # Vérifier si un processus avec le nom camouflé est déjà actif
    local search_pattern=$(echo "$PROC_NAME" | sed 's/\[/\\[/g; s/\]/\\]/g')
    if pgrep -f "$search_pattern" > /dev/null; then
        echo "Le processus semble déjà actif sous le nom: $PROC_NAME"
        exit 1
    fi

    # Se cacher et démarrer
    hide_process "$sqlite_path"
    
    echo "Processus lancé en arrière-plan sous le nom: $PROC_NAME"
    exit 0
}

# Lancer le processus
main "$@"