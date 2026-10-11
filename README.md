# claude-mods

Ma sélection de **mods Claude Code**, installée et configurée en une commande, sur macOS, Linux et
Windows.

Un mod est un plugin Claude Code qui contient un module de hooks. Ce module lui permet de dessiner
sa propre interface (panneau, barre au-dessus du prompt, barre latérale) et de réagir aux événements
de la session. Les mods s'installent au **scope user** : ils sont actifs dans toutes les sessions, en
terminal comme dans l'app Desktop.

## Installation rapide

**Prérequis :** `git` et [Claude Code](https://code.claude.com) déjà installés. Les mods demandent
Claude Code **2.1.287 ou plus récent**, mais le script fait la mise à jour lui-même.

```bash
git clone https://github.com/Nelahia/claude-mods.git ~/claude-mods
```

```bash
bash ~/claude-mods/install-mods.sh
```

- **macOS / Linux** : lancer ces commandes dans le Terminal.
- **Windows** : lancer ces commandes dans **Git Bash**, pas dans PowerShell.

Ensuite, **redémarre Claude Code**, ou tape `/reload-plugins` dans une session ouverte.

### Mettre à jour

```bash
git -C ~/claude-mods pull && bash ~/claude-mods/install-mods.sh
```

Le script est **idempotent** : on peut le relancer sans risque, il ne fait que rafraîchir ce qui est
déjà en place.

## Ce que fait le script

1. Il met à jour Claude Code et vérifie que la version est au moins 2.1.287. Il utilise en priorité
   l'installation native (`~/.local/bin/claude`).
2. Il ajoute les marketplaces des mods, ou les rafraîchit si elles sont déjà là.
3. Il installe les plugins au scope user et fixe leurs options.
4. Il applique le skin **tokyo-night**, mais seulement si aucun skin n'a encore été choisi : un thème
   choisi plus tard avec `/skin` n'est jamais écrasé.

## Les mods

| Mod | Ce qu'il fait | Commandes |
| --- | --- | --- |
| **[skins](https://github.com/hellosverre/claude-skins)** | Refonte visuelle complète : lignes d'outils avec icônes, cartes de diff, tableaux, Mermaid, maths et shell, code coloré, repliage, 15 thèmes. | `/skin` (réglages avec aperçu), `/skin <thème>`, `/skin list`, `/skin off` |
| **[savvy-progress](https://github.com/JohnnyVizz/claude-kit/tree/main/plugins/savvy-progress)** | Barre de progression au-dessus du prompt et panneau des sous-agents en direct : modèle, tâches, contexte, coût estimé, durée. | `/agents-info` |
| **[cache-tax](https://github.com/karanb192/cache-tax)** | Garde le cache de prompt « chaud » pendant les pauses et bloque une fois un envoi sur un cache froid, en affichant le coût estimé. | `/keepwarm [90m\|always\|status\|off]`, `/cache-tax` |

## Configuration appliquée

Les options sont modifiables à tout moment via `/config` ou `/plugin configure <plugin>`.

- **skins** : thème `tokyo-night`. Le choix est enregistré par machine et vaut pour tous les dossiers,
  sauf ceux où tu as tapé `/skin pin` (`/skin unpin` les ramène au thème par défaut).
- **savvy-progress** : `language=auto`, la langue suit celle de Claude Code.
- **cache-tax** : réglages d'origine. `/cache-tax guard warn` affiche seulement un avertissement au
  lieu de bloquer l'envoi.

## À savoir

- **cache-tax coûte des tokens et change l'envoi.** Quand le cache est froid et que le contexte dépasse
  50k tokens, le **premier** envoi est annulé et le prix estimé s'affiche : il suffit de renvoyer le
  message pour qu'il passe. Chaque ping de `/keepwarm` (toutes les 50 min) consomme des tokens. Le
  maintien au chaud suppose un cache d'une heure. C'est le défaut en abonnement ; avec une clé API, il
  faut `"promptCacheTtl": "1h"`.
- Les mods ne chargent pas dans les sessions WSL de l'app Desktop.
- **Barre au-dessus du prompt partagée** : savvy-progress et cache-tax y dessinent tous les deux. Si les
  deux veulent s'afficher en même temps, un seul gagne.
- **API en early access** : une mise à jour de Claude Code peut casser un mod. `claude plugin list`
  permet de vérifier leur état, `claude plugin disable <plugin>` d'en couper un.
- **Deux installations de Claude Code** (native + npm) : celle qui arrive en premier dans le PATH
  gagne. Le script met à jour la version native. Si une ancienne copie npm traîne, supprime-la en
  dehors de toute session avec `npm -g uninstall @anthropic-ai/claude-code`.

## Désinstaller

```bash
claude plugin uninstall skins@hellosverre-mods
```

Même commande pour `savvy-progress@claude-kit` et `cache-tax@claude-code-mods`. `claude plugin marketplace remove <nom>` retire une marketplace.

## Ajouter un mod

Le script lit deux listes en tête de [`install-mods.sh`](install-mods.sh) :

- `MARKETPLACES` : des entrées `nom|owner/repo`.
- `PLUGINS` : des entrées `plugin@marketplace|clé=valeur;clé=valeur`.

Il suffit d'y ajouter une ligne, puis de relancer le script.
