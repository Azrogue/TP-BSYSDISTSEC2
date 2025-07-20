# 🕵️ TP Sécurité Système - Scripts de Processus Avancés

Ce dépôt contient deux scripts développés dans le cadre d'un TP de sécurité système portant sur les processus cachés et l'auto-propulsion sécurisée.

## 📋 Sommaire

- [Hack #3 - Processus caché dans le brouillard](#hack-3---processus-caché-dans-le-brouillard)
- [Hack #6 - Processus autonome](#hack-6---processus-autonome)
- [Installation et utilisation](#installation-et-utilisation)
- [Tests et vérification](#tests-et-vérification)

---

## 🔍 Hack #3 - Processus caché dans le brouillard

### Script : `fog`

Le script `fog` est conçu pour créer un processus qui se cache parmi les processus système en utilisant plusieurs techniques d'obfuscation.

### 🎯 Objectifs atteints

- **Nom de processus camouflé** : Utilise le nom `[kworker/0:0-events]` qui ressemble à un processus kernel
- **Détachement complet** : Se détache du terminal et redirige toutes les entrées/sorties vers `/dev/null`
- **Utilisation de `setsid`** : Crée une nouvelle session pour éviter d'être lié au terminal parent
- **Traces persistantes** : Enregistre son activité dans deux endroits :
  - Fichier texte : `~/.cache/fog_trace`
  - Base de données SQLite : `~/.local/share/fog.db`

### 🔧 Fonctionnement

1. **Initialisation** : Crée la structure de fichiers nécessaire
2. **Camouflage** : Change son nom de processus et se détache
3. **Persistance** : Tourne en arrière-plan avec une vérification toutes les 30 secondes
4. **Tracabilité** : Enregistre chaque cycle d'exécution

### 📊 Vérification de l'activité

```bash
# Vérifier les traces
tail -f ~/.cache/fog_trace

# Vérifier la base de données
sqlite3 ~/.local/share/fog.db "SELECT * FROM logs ORDER BY timestamp DESC LIMIT 5;"
```

---

## 🚀 Hack #6 - Processus autonome

### Script : `autonom`

Le script `autonom` est capable de s'auto-propulser vers une machine distante de manière sécurisée et autonome.

### 🎯 Objectifs atteints

- **Auto-propulsion** : Transfert automatique vers une machine distante
- **Sécurité** : Utilisation de clés SSH temporaires et chiffrement
- **Autonomie** : Délai aléatoire entre 2 et 40 secondes avant le transfert
- **Vérification** : Confirme l'atterrissage sur la machine distante
- **Nettoyage** : Supprime ses traces sur la machine d'origine

### 🔧 Fonctionnement

1. **Préparation** : Génère des clés SSH temporaires et crée une archive du script
2. **Attente** : Délai aléatoire pour simuler une décision autonome
3. **Transfert** : Copie sécurisée vers la machine distante via SCP
4. **Lancement** : Démarre automatiquement sur la machine cible
5. **Vérification** : Confirme que le processus tourne sur la destination
6. **Nettoyage** : Supprime toutes les traces sur la machine source

### 🔐 Sécurité implémentée

- **Clés SSH éphémères** : Générées à chaque exécution et supprimées après usage
- **Transfert chiffré** : Utilisation de SCP avec authentification par clé
- **Suppression des traces** : Nettoyage complet de l'historique et des fichiers
- **Permissions minimales** : Fonctionne avec un simple compte guest

### 📡 Utilisation

```bash
# Transfert vers une machine distante
./autonom remote.example.com guest 22

# Transfert avec paramètres personnalisés
./autonom 192.168.1.100 guestuser 2222
```

---

## 🛠️ Installation et utilisation

### Prérequis

```bash
# Rendre les scripts exécutables
chmod +x fog autonom

# Installer SQLite3 (pour fog)
sudo apt-get install sqlite3  # Ubuntu/Debian
# ou
brew install sqlite3          # macOS
```

### Installation rapide

```bash
git clone <repository-url>
cd <repository-name>
chmod +x fog autonom
```

---

## 🧪 Tests et vérification

### Test du script fog

```bash
# Lancer le processus
./fog

# Vérifier qu'il est actif (difficile à trouver !)
ps aux | grep kworker
# ou
pgrep -f "kworker"

# Vérifier les traces
sqlite3 ~/.local/share/fog.db "SELECT COUNT(*) FROM logs;"
```

### Test du script autonom

```bash
# Test local (boucle sur localhost)
./autonom localhost $USER

# Vérifier le transfert
ssh localhost "ps aux | grep autonom"

# Vérifier les traces
cat ~/.autonom_trace
```

### 📝 Notes importantes

- Ces scripts sont conçus à des fins éducatives
- **Utilisez uniquement dans des environnements contrôlés et avec autorisation**
- Les scripts incluent des mécanismes de nettoyage automatique
- Les traces sont conservées pour permettre l'audit et la vérification

### 🔍 Détection et mitigation

Pour détecter ces types de processus :
- Surveiller les connexions SSH sortantes
- Vérifier les processus avec des noms suspects
- Analyser les fichiers de traces dans les répertoires utilisateur
- Utiliser des outils comme `auditd` pour surveiller les exécutions

---

*Développé dans le cadre d'un TP de sécurité système - 2025*