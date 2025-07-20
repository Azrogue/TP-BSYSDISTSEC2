# TP Sécurité Système : Processus Furtifs et Autonomes

Ce projet, réalisé dans le cadre d'un TP de sécurité système, explore les techniques avancées de manipulation de processus sous Unix/Linux. Il présente deux scripts : `fog`, un processus conçu pour se dissimuler, et `autonom`, un processus capable de s'auto-propulser vers un autre système.

## 📋 Sommaire

- Script `fog` : Processus Furtif
- Script `autonom` : Processus Auto-Propulsé
- Prérequis
- Avertissement Éthique

---

## 🌫️ Script `fog` : Processus Furtif

Le script `fog` lance un processus persistant qui cherche à se fondre parmi les processus légitimes du système.

#### Techniques mises en œuvre
*   **Camouflage du nom :** Le processus se renomme en `[kworker/0:0-events]` pour imiter un *worker* légitime du noyau.
*   **Détachement de session :** Utilise `setsid` pour s'exécuter dans une nouvelle session, totalement indépendante du terminal de lancement.
*   **Architecture robuste :** Un script parent lance un processus enfant entièrement autonome, puis se termine proprement.
*   **Persistance et traçabilité :** Le processus reste actif et laisse une preuve de vie périodique dans un fichier de log et une base de données SQLite pour permettre la vérification de son activité.

#### Utilisation et Vérification
1.  **Lancement :**
    ```bash
    ./fog
    ```
2.  **Vérification de l'activité :**
    ```bash
    # Chercher le processus camouflé
    ps aux | grep '\[k]worker/0:0-events'

    # Consulter les traces
    $ tail ~/.cache/fog_trace
    [2025-07-21 00:47:45] Processus actif - PID: 4149
    [2025-07-21 00:48:15] Processus actif - PID: 4149

    $ sqlite3 ~/.local/share/fog.db "SELECT * FROM logs ORDER BY id DESC LIMIT 1;"
    2|2025-07-20 22:48:15|4149|active
    ```

---

## 🚀 Script `autonom` : Processus Auto-Propulsé

Le script `autonom` est un processus capable de s'auto-propulser de manière sécurisée et autonome vers un autre système.

#### Techniques mises en œuvre
*   **Auto-propulsion :** Utilise `scp` pour se copier et `ssh` pour s'exécuter à distance.
*   **Décision autonome :** Simule une prise de décision en attendant un délai aléatoire avant d'agir.
*   **Transport sécurisé :** Le transfert est chiffré via SSH et l'authentification est assurée par une paire de clés dédiée (`~/.ssh/autonom_key`).
*   **Vérification post-atterrissage :** Confirme sa propre exécution sur la machine cible et vérifie que le compte utilisateur n'est **pas root (UID ≠ 0)**, conformément à l'énoncé.
*   **Nettoyage des traces :** Efface sa présence (le fichier script) sur la machine de départ après une propulsion réussie.

#### Utilisation (Processus en 2 étapes)

1.  **Étape 1 : Configuration initiale (une seule fois)**
    *   Lancez le script : `./autonom <hôte_distant> <user_distant>`
    *   Le script va créer une clé SSH et se mettre en pause.
    *   Dans un **second terminal**, copiez la clé sur l'hôte distant avec la commande `ssh-copy-id` qui vous est fournie.
    *   Retournez au premier terminal et appuyez sur `Entrée`.

2.  **Étape 2 : Lancement autonome**
    *   Relancez la même commande : `./autonom <hôte_distant> <user_distant>`
    *   Le script s'exécutera maintenant sans aucune interaction.

#### Vérification
*   **Sur l'hôte distant :** Vérifiez que le processus a bien atterri.
    ```bash
    ssh -i ~/.ssh/autonom_key <user_distant>@<hôte_distant> "ps aux | grep '[a]utonom.sh --landed'"
    ```
*   **Sur l'hôte de départ :** Vérifiez que le script s'est bien auto-détruit (si la mission a réussi).
    ```bash
    ls -l /root/TP-BSYSDISTSEC2/autonom.sh
    # Doit retourner "No such file or directory"
    ```
*   **Consulter le journal de bord de la mission :**
    ```bash
    cat ~/.autonom_trace
    ```

---

## 🛠️ Prérequis

1.  **Rendre les scripts exécutables :**
    ```bash
    chmod +x fog autonom
    ```
2.  **Installer les dépendances :**
    ```bash
    # Pour le script 'fog'
    sudo apt-get update && sudo apt-get install -y sqlite3

    # Pour le script 'autonom' (copie de clé simplifiée)
    sudo apt-get install -y openssh-client
    ```

---

## ⚠️ Avertissement Éthique

Ces scripts ont été développés dans un but purement **éducatif**.