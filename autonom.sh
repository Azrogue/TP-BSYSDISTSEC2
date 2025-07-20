#!/bin/bash

# Gérer un argument pour savoir si le script a "atterri"
if [ "$1" == "--landed" ]; then
    echo "[$(date)] Processus atterri sur $(hostname). PID: $$. En attente." >> "$HOME/.autonom_trace"
    # Le processus reste en vie mais ne fait rien d'autre.
    sleep infinity
    exit 0
fi

# Script autonom - Auto-propulsion sécurisée d'un processus
# Hack#6 - Processus totalement autonome

# Configuration
REMOTE_HOST="${1:-localhost}"
REMOTE_USER="${2:-$USER}"
REMOTE_PORT="${3:-22}"
DELAY_MIN=20
DELAY_MAX=40
KEY_FILE="$HOME/.ssh/autonom_key"
TRACE_FILE="$HOME/.autonom_trace"

# Fonction de journalisation
log_trace() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$TRACE_FILE"
}

# Générer une paire de clés SSH temporaire
generate_keys() {
    # On ne génère la clé que si elle n'existe pas.
    # L'utilisateur doit copier la clé publique sur la cible une seule fois.
    if [ ! -f "$KEY_FILE" ]; then
        log_trace "Génération d'une nouvelle clé SSH persistante : $KEY_FILE"
        ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -q
        echo "----------------------------------------------------------------"
        echo "ACTION REQUISE : Ajoutez cette clé publique au fichier ~/.ssh/authorized_keys sur la machine distante ($REMOTE_USER@$REMOTE_HOST) :"
        cat "$KEY_FILE.pub"
        echo "----------------------------------------------------------------"
        echo "Utilisez 'ssh-copy-id -i $KEY_FILE.pub $REMOTE_USER@$REMOTE_HOST' dans un autre terminal."
        read -p "Appuyez sur Entrée pour continuer une fois la clé copiée..."
    fi
}

# Préparer le transfert sécurisé
prepare_transfer() {
    # Le script de démarrage distant est maintenant une simple commande
    # car nous copions le script principal directement.
    # Pas besoin de préparer des fichiers locaux.
    log_trace "Préparation du transfert (rien à faire localement)."
}

# Le script qui sera exécuté sur la cible
get_remote_command() {
    # Note: Le script se copie lui-même sous le nom autonom.sh dans /tmp/
    echo "chmod +x /tmp/autonom.sh && nohup /tmp/autonom.sh --landed > /dev/null 2>&1 &"
}

# Attendre un délai aléatoire
random_delay() {
    local delay=$((RANDOM % (DELAY_MAX - DELAY_MIN + 1) + DELAY_MIN))
    log_trace "Attente de ${delay} secondes avant transfert"
    sleep "$delay"
}

# Transférer vers la machine distante
transfer_remote() {
    log_trace "Début du transfert vers $REMOTE_USER@$REMOTE_HOST"
    
    # Options communes pour ssh et scp
    local common_opts="-i $KEY_FILE -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    # scp utilise -P (majuscule) pour le port
    local scp_opts="$common_opts -P $REMOTE_PORT"
    
    # Copier le script lui-même
    scp $scp_opts "$0" "$REMOTE_USER@$REMOTE_HOST:/tmp/autonom.sh"
    
    if [ $? -eq 0 ]; then
        log_trace "Transfert réussi, lancement distant"
        # Lancer le script sur la machine distante
        local ssh_opts="$common_opts -p $REMOTE_PORT -f" # ssh utilise -p (minuscule), -f pour forcer le passage en arrière-plan
        local remote_cmd=$(get_remote_command)
        ssh $ssh_opts "$REMOTE_USER@$REMOTE_HOST" "$remote_cmd"
        
        return $?
    else
        log_trace "Échec du transfert"
        return 1
    fi
}

# Nettoyer les traces locales
cleanup_local() {
    log_trace "Nettoyage des traces locales"
    
    # Ne pas supprimer la clé pour permettre de futurs sauts.
    # Effacer l'historique bash pour la session courante
    history -c 2>/dev/null || true
    
    # Supprimer le script lui-même pour effacer la présence
    rm -f "$0"
}

# Vérifier l'atterrissage
verify_landing() {
    log_trace "Vérification de l'atterrissage sur $REMOTE_HOST"
    
    # Options SSH pour la vérification
    local ssh_opts="-i $KEY_FILE -p $REMOTE_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

    # Vérifier si le processus tourne sur la machine distante avec le bon argument
    local remote_pid=$(ssh $ssh_opts "$REMOTE_USER@$REMOTE_HOST" \
        "pgrep -f 'autonom.sh --landed' | head -1" 2>/dev/null)
    
    if [ -n "$remote_pid" ]; then
        # Vérifier que le UID n'est pas 0
        local remote_uid=$(ssh $ssh_opts "$REMOTE_USER@$REMOTE_HOST" "id -u")
        log_trace "Processus actif sur la machine distante - PID: $remote_pid, UID: $remote_uid"
        if [ "$remote_uid" -ne 0 ]; then
            log_trace "Vérification réussie: UID distant est $remote_uid (pas root)."
            return 0
        else
            log_trace "ERREUR: Le processus distant tourne en tant que root (UID 0)!"
            return 1
        fi
    else
        log_trace "Processus non trouvé sur la machine distante"
        return 1
    fi
}

# Fonction principale
main() {
    # Vérifier les arguments
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: $0 <remote_host> <remote_user> [remote_port]"
        exit 1
    fi

    log_trace "Démarrage du processus autonome"
    
    # Vérifier si SSH et SCP sont disponibles
    if ! command -v ssh &> /dev/null || ! command -v scp &> /dev/null; then
        log_trace "SSH ou SCP non disponible. Abandon."
        exit 1
    fi
    
    # Générer les clés (si nécessaire) et préparer le transfert
    generate_keys
    
    # Attendre le délai aléatoire
    random_delay
    
    # Tenter le transfert
    if transfer_remote; then
        sleep 3  # Laisser un peu de temps au processus distant pour démarrer
        
        if verify_landing; then
            log_trace "Atterrissage confirmé. Nettoyage de la machine de départ."
            cleanup_local
        else
            log_trace "Échec de la vérification d'atterrissage. Annulation du nettoyage."
        fi
    else
        log_trace "Échec du transfert. Annulation."
    fi
}

# Lancer le processus
main "$@"