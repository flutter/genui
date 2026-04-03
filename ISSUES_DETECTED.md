# Opportunités de contribution — flutter/genui

> Fichier local de suivi. Dernière mise à jour : 2026-04-03.
> Dépôt cible : https://github.com/flutter/genui

---

## Modalités de contribution

### Processus standard (pas de Discord propre à genui)

1. **Discord Flutter** — Le projet suit les guidelines Flutter. Le canal principal est `#hackers-triage` sur le Discord Flutter. Il n'y a pas de Discord dédié à genui.
2. **Signaler qu'on bosse sur une issue** — Pas de système de "claim" officiel. La pratique standard est de **commenter sur l'issue GitHub** pour indiquer qu'on s'en occupe, afin d'éviter les doublons de travail.
3. **GitHub Discussions** — Le projet a une section Discussions active (https://github.com/flutter/genui/discussions). C'est le bon endroit pour poser des questions avant de commencer un gros chantier.
4. **Draft PR** — Ne pas review les PRs en état draft sauf si l'auteur le demande explicitement (cf. `docs/contributing/README.md`).
5. **Avant de soumettre une PR** — Remplir la Pre-Review Checklist du [PR template](https://github.com/flutter/genui/.github/PULL_REQUEST_TEMPLATE.md) et faire tourner `./tool/run_all_tests_and_fixes.sh`.

---

## Issues identifiées

### Faciles / Bonne porte d'entrée

| Issue | Titre | Priorité | Statut | Notes |
|-------|-------|----------|--------|-------|
| [#783](https://github.com/flutter/genui/issues/783) | Broken link in README on `examples/travel_app` | P1 | Ouvert, non assigné | Correction triviale d'un lien cassé dans le README principal. Idéal pour se familiariser avec le processus de PR. |

---

### Intermédiaires

| Issue | Titre | Priorité | Statut | Notes |
|-------|-------|----------|--------|-------|
| [#819](https://github.com/flutter/genui/issues/819) | `DateTimeInput` inside `Row` causes layout error | P1 | Ouvert, non assigné | Bug bien délimité : `DateTimeInput` se rend comme un `ListTile` sans contraintes dans un `Row`. Fix suggéré dans l'issue : ajouter `DateTimeInput` à la détection d'auto-weight, comme `TextField`. |
| [#823](https://github.com/flutter/genui/issues/823) | Fix prompt builder | P2 | Ouvert, non assigné | Deux tâches : corriger les évaluations du prompt builder + affiner les prompts pour se limiter aux opérations autorisées. Suite de #751. |
| [#847](https://github.com/flutter/genui/issues/847) | Create clear API to observe who's turn it is | P2 | Ouvert, non assigné | Créer une API observable pour détecter si c'est le tour de l'agent ou de l'utilisateur dans une conversation. Labellé `api-simplicity`. |

---

### Avancées / Architecturales

| Issue | Titre | Priorité | Statut | Notes |
|-------|-------|----------|--------|-------|
| [#828](https://github.com/flutter/genui/issues/828) | Create `a2ui_core` library, independent of genui | P2 | En cours (PR #831 en draft) | Bibliothèque Dart pur indépendante de Flutter implémentant le protocole A2UI v0.9. Inclut : modèles, `MessageProcessor`, classes de contexte, API catalog de base. Un prototype est en cours dans PR #831. |
| [#818](https://github.com/flutter/genui/issues/818) | CI breaks whenever `subosito/flutter-action` is updated | P2 | Ouvert, sprint ready | Robustifier le pipeline CI/CD face aux mises à jour externes de l'action Flutter. Labellé `tech-debt`. |
| [#801](https://github.com/flutter/genui/issues/801) | Revisit Gen UI SDK Catalog definition design | P2 | Assigné à polina-c | Refonte du design du catalog pour s'aligner avec les renderers web (React, Angular, Lit). Ne pas toucher pour l'instant — assigné. |

---

## PRs ouvertes en lien (à ne pas dupliquer)

| PR | Titre | Lié à |
|----|-------|-------|
| [#831](https://github.com/flutter/genui/pull/831) | Prototype of a2ui_core library | #828 |
| [#841](https://github.com/flutter/genui/pull/841) | Fix: prompt builder misleading LLM | #823 |
| [#850](https://github.com/flutter/genui/pull/850) | Create Dart replicas for Flutter's notifiers | #824/#826 |

---

## Ordre d'attaque recommandé

1. **#783** — Lien cassé dans le README → PR minimale pour apprendre le processus
2. **#819** — Bug de layout `DateTimeInput` → fix bien délimité, impactant, aucune PR en cours
3. **#847** — API d'observation du tour → fonctionnalité utile, non assignée, pas de PR en cours
