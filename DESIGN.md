---
version: alpha
name: Carneo
description: |
  Carnet d'entretien automobile consulté au téléphone, souvent au retour du garage. Ancré sur un
  canvas papier crème et une encre presque noire, titres en serif Fraunces, chiffres en monospace
  tabulaire. Le voltage vient du pairing papier crème / bleu de Prusse : un objet qu'on tient, là
  où les apps de suivi véhicule sont des dashboards sombres pleins de jauges. Le vert, l'ambre et
  le rouge ne décorent jamais, ils sont réservés aux trois états d'échéance.

# === Design tokens (machine-readable, consommés par les LLM via {token references}) ===

colors:
  primary: "#1b4965"              # CTAs, liens, focus rings, champs issus de l'extraction
  primary-active: "#14384e"       # primary en :active / pressed
  primary-disabled: "#cbd5dc"     # primary disabled state

  ink: "#1a1a17"                  # titres
  body: "#3a3833"                 # texte courant
  body-strong: "#262420"          # texte courant emphasé
  muted: "#5f5b52"                # texte secondaire, hints, état « inconnu »
  muted-soft: "#7d786c"           # tertiaire et disabled UNIQUEMENT (3.7:1, jamais du texte courant)

  hairline: "#ded6c8"             # borders standards
  hairline-soft: "#e9e2d5"        # borders subtiles

  canvas: "#f7f4ee"               # background page (papier)
  surface-soft: "#f1ece2"         # surface secondaire (sections, champs pré-remplis)
  surface-card: "#eae3d7"         # cards / panels
  surface-dark: "#1c1b18"         # surfaces contrastées (footer, blocs de mise en avant)
  surface-dark-elevated: "#26251f"
  surface-dark-soft: "#222019"

  on-primary: "#ffffff"           # texte sur primary
  on-dark: "#f7f4ee"              # texte sur surface-dark
  on-dark-soft: "#a8a296"         # texte secondaire sur surface-dark

  # Sémantique : les trois états d'échéance, jamais décoratifs
  success: "#276b47"              # « à jour »
  success-soft: "#e3efe6"
  warning: "#835408"              # « à faire »
  warning-soft: "#f5e9d2"
  error: "#b23b36"                # « en retard »
  error-soft: "#f6e2df"

typography:
  display-xl:                     # h1 hero, page d'accueil publique
    fontFamily: "Fraunces, Georgia, serif"
    fontSize: 56px
    fontWeight: 600
    lineHeight: 1.05
    letterSpacing: -1.2px
  display-lg:                     # h1 standard
    fontFamily: "Fraunces, Georgia, serif"
    fontSize: 40px
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: -0.8px
  display-md:                     # h2
    fontFamily: "Fraunces, Georgia, serif"
    fontSize: 30px
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: -0.4px
  display-sm:                     # h3
    fontFamily: "Fraunces, Georgia, serif"
    fontSize: 24px
    fontWeight: 600
    lineHeight: 1.2
  title-lg:                       # h4, titres de section
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 20px
    fontWeight: 600
    lineHeight: 1.3
  title-md:                       # h5, titres de card
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 17px
    fontWeight: 600
    lineHeight: 1.4
  title-sm:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 15px
    fontWeight: 600
    lineHeight: 1.4
  body-md:                        # texte courant
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.55
  body-sm:                        # texte courant compact (listes, tableaux)
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.55
  caption:                        # legends, hints
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 13px
    fontWeight: 500
    lineHeight: 1.4
  caption-uppercase:              # labels, eyebrow
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 12px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 1.2px
  metric:                         # kilométrage, coûts, dates mis en avant
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: 28px
    fontWeight: 500
    lineHeight: 1.1
    fontVariantNumeric: "tabular-nums"
  code:                           # données numériques en ligne, colonnes de tableaux
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.6
    fontVariantNumeric: "tabular-nums"
  button:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 15px
    fontWeight: 600
    lineHeight: 1
  nav-link:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.4

rounded:
  xs: 4px
  sm: 6px
  md: 8px
  lg: 12px
  xl: 16px
  pill: 999px

spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
  3xl: 64px

components:

  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.lg}"
    padding: "12px 20px"
    minHeight: 44px

  button-secondary:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    typography: "{typography.button}"
    rounded: "{rounded.lg}"
    padding: "12px 20px"
    minHeight: 44px
    border: "1px solid {colors.hairline}"

  button-ghost:
    backgroundColor: transparent
    textColor: "{colors.body}"
    typography: "{typography.button}"
    rounded: "{rounded.lg}"
    padding: "12px 16px"
    minHeight: 44px

  text-input:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: "12px 14px"
    minHeight: 44px
    border: "1px solid {colors.hairline}"

  input-extracted:                # champ pré-rempli par la photo de facture, à vérifier
    backgroundColor: "{colors.surface-soft}"
    textColor: "{colors.ink}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: "12px 14px"
    minHeight: 44px
    border: "1px dashed {colors.primary}"

  card:
    backgroundColor: "{colors.surface-card}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: 20px
    border: "1px solid {colors.hairline}"

  card-state:                     # une échéance dans la liste, filet de couleur à gauche
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: 16px
    border: "1px solid {colors.hairline}"
    borderLeft: "4px solid {colors.muted}"

  badge-pill:
    backgroundColor: "{colors.surface-soft}"
    textColor: "{colors.body}"
    typography: "{typography.caption}"
    rounded: "{rounded.pill}"
    padding: "4px 12px"

  toast-success:
    backgroundColor: "{colors.success}"
    textColor: "{colors.on-primary}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.lg}"
    padding: "12px 16px"

  toast-error:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-primary}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.lg}"
    padding: "12px 16px"
---

## Overview

Carneo est un carnet d'entretien automobile pour un particulier qui suit sa propre voiture. Il est consulté au téléphone, souvent debout, parfois dehors devant un garage, et il sert à répondre à une seule question : qu'est-ce qui est dû maintenant sur ce véhicule. Le second public est un visiteur de démonstration qui doit comprendre le produit en moins de deux minutes sans créer de compte.

Le parti pris visuel est celui du carnet papier que le produit remplace : canvas crème, encre presque noire, titres en serif, chiffres en monospace tabulaire. Le ton est posé et factuel, jamais alarmiste : l'application affiche ce qu'elle sait, et dit explicitement ce qu'elle ignore. Une échéance inconnue n'est pas un problème à signaler en rouge, c'est une information neutre à vérifier.

Ce que l'interface ne fait jamais : simuler une certitude qu'elle n'a pas. Pas de jauges, pas de scores de santé, pas de pourcentages inventés. Un nombre affiché vient toujours d'une donnée saisie par l'utilisateur ou d'un calcul qu'on peut lui expliquer.

## Colors

- **Primary `{colors.primary}`** (bleu de Prusse) : CTAs, liens, focus rings, et bordure des champs issus de l'extraction. Choisi froid et sombre pour trancher sur le canvas chaud (8.8:1) sans jamais être confondu avec un état d'échéance.
- **Surfaces (`{colors.canvas}`, `{colors.surface-soft}`, `{colors.surface-card}`)** : trois niveaux de papier, écart de luminosité volontairement faible. Canvas = page, surface-soft = sections et champs pré-remplis, surface-card = panels. Les surfaces `*-dark` sont réservées aux blocs de mise en avant de la page publique, pas à l'app connectée.
- **Ink / body / muted** : trois niveaux de texte. `ink` pour les titres, `body` pour le texte courant, `muted` pour le secondaire et pour l'état « inconnu, à vérifier ». `muted-soft` ne passe pas AA (3.7:1) et ne sert qu'aux libellés désactivés, jamais à du texte à lire.
- **Sémantique, règle non-négociable** : `success` (à jour), `warning` (à faire), `error` (en retard) et `muted` (inconnu) portent les quatre états du moteur d'échéances et **rien d'autre**. Aucun élément décoratif, aucun bouton, aucun graphique ne prend ces couleurs. Les variantes `*-soft` sont les fonds de badge correspondants, avec la couleur pleine en texte par-dessus.
- Les quatre couleurs d'état sont assez sombres pour passer AA en texte sur canvas (≥ 4.5:1) et pour porter du blanc en fond plein. Un état ne se lit jamais à la couleur seule : toujours couleur + libellé écrit.

## Typography

- **Display (`display-xl` → `display-sm`)** : Fraunces, serif variable. Titres de page et de section principale. C'est la signature du carnet, la seule famille serif de l'interface. Couleur `{colors.ink}`.
- **Title (`title-lg` → `title-sm`)** : Inter en 600. Titres de cards, libellés d'opération d'entretien, en-têtes de tableaux. Graisse marquée plutôt que taille, pour tenir sur mobile.
- **Body** : `body-md` pour le texte courant, `body-sm` pour l'historique et les listes denses. Couleur `{colors.body}`.
- **Metric** : JetBrains Mono en 28px pour le chiffre dominant d'un écran (kilométrage actuel, kilomètres restants avant échéance, coût total). Un seul `metric` par bloc.
- **Code** : JetBrains Mono 14px, `tabular-nums`, pour toute donnée numérique en ligne ou en colonne : dates, kilométrages, montants. La chasse fixe fait que les colonnes d'un historique s'alignent sans effort.
- **Caption / caption-uppercase** : hints et libellés de section. `caption-uppercase` pour les eyebrow au-dessus d'un titre.

## Layout

- **Container** : `max-w-2xl` (672px) pour les écrans de consultation et les formulaires : l'application est pensée téléphone d'abord, une colonne. `max-w-4xl` (896px) pour l'historique et les tableaux. `max-w-5xl` pour la page publique de démonstration.
- **Grille** : une colonne jusqu'à `md`, deux colonnes au-delà uniquement sur l'historique et la fiche véhicule. `gap-4` (`{spacing.md}`) sur mobile, `gap-6` (`{spacing.lg}`) au-delà.
- **Densité mixte, assumée** : l'écran des prochaines échéances est aéré (padding card `{spacing.lg}`, séparation `{spacing.lg}` entre cards) parce que c'est la lecture principale du produit. L'historique, les relevés kilométriques et les tableaux sont denses (padding `{spacing.md}`, lignes 44px, `body-sm`).
- **Cibles tactiles** : 44px de hauteur minimum sur tout élément interactif, sans exception. L'app se manipule d'une main.
- **Breakpoints Tailwind** : sm=640, md=768, lg=1024, xl=1280. Mobile first, toujours.

## Elevation & Depth

- **Le papier n'a pas d'ombre.** La hiérarchie passe par le contraste de surfaces et les filets `{colors.hairline}`, pas par l'élévation.
- **Niveaux** :
  - Niveau 0 (canvas, cards statiques) : aucune ombre, une bordure `1px {colors.hairline}` suffit.
  - Niveau 1 (card cliquable au survol) : `shadow-sm`, 1px offset, 2px blur, 6% d'opacité en teinte chaude.
  - Niveau 2 (dropdowns, popovers, barre d'action flottante mobile) : `shadow-md`, 4px offset, 10px blur, 10%.
  - Niveau 3 (modals, feuille de revue d'extraction) : `shadow-lg` + backdrop `rgba(26, 26, 23, 0.4)`.
- **Transitions** : `150ms ease-out` sur les états de survol et de focus. Aucun spring, aucun rebond.

## Shapes

- **Radius de base `{rounded.lg}` (12px)** : boutons, cards, blocs d'échéance. C'est le rayon dominant de l'interface.
- **`{rounded.md}` (8px)** pour tout élément imbriqué dans une card (inputs, sous-blocs, vignettes de facture), toujours un cran en dessous du conteneur.
- **`{rounded.xl}` (16px)** pour les modals et la feuille de revue d'extraction.
- **`{rounded.pill}`** pour les badges d'état et les tags d'opération, jamais pour un bouton.
- Pas de rayon hors tokens, pas de coins carrés : l'objet doit se tenir en main.

## Components

- **Boutons** : un seul `button-primary` par écran, il porte l'action principale (ajouter une intervention, photographier une facture). `button-secondary` pour le support, `button-ghost` pour Annuler et les actions tertiaires. Sur mobile, l'action principale d'un formulaire est collée en bas d'écran dans une barre `{colors.canvas}` avec filet supérieur.
- **`card-state`** : le composant signature, une échéance dans la liste. Filet gauche de 4px qui porte la couleur d'état (`success`, `warning`, `error`, ou `muted` pour l'inconnu), titre de l'opération en `title-md`, échéance chiffrée en `code`, badge d'état en `badge-pill` avec fond `*-soft`. Le libellé de l'état est toujours écrit en toutes lettres à côté de la couleur.
- **`input-extracted`** : bordure pointillée `{colors.primary}` et fond `{colors.surface-soft}` pour tout champ pré-rempli par l'extraction de facture, accompagné d'une `caption` « pré-rempli depuis la photo, à vérifier ». Dès que l'utilisateur modifie le champ, il repasse en `text-input` normal. Cette distinction visuelle est une exigence produit, pas une décoration : aucune donnée extraite ne doit ressembler à une donnée saisie.
- **Inputs** : focus ring 2px `{colors.primary}` avec 2px d'offset. Erreur : bordure `{colors.error}`, message en `{colors.error}` sous le champ. Les champs numériques (km, montant) utilisent `{typography.code}` et un clavier numérique sur mobile.
- **Toasts** : bas d'écran sur mobile, haut à droite sur desktop. Auto-dismiss 4s, jamais plus de 3 empilés. Aucune `alert()` ni `confirm()` native.
- **États vides** : une phrase qui dit ce qui manque et pourquoi, puis un seul CTA. Exemple : « Pas encore assez de relevés pour estimer ton rythme. Il en faut 3 sur 60 jours. » Ne jamais afficher un écran vide sans expliquer ce qu'il attend.
- **Incertitude** : quand le moteur ne peut pas conclure, l'écran affiche le kilométrage restant et la mention explicite que le rythme n'est pas mesurable. Jamais une date projetée sans les données qui la fondent.

## Do's and Don'ts

### Do
- Référencer les tokens (`{colors.primary}`, `{spacing.lg}`, `{rounded.lg}`) plutôt que des valeurs en dur.
- Écrire les états en toutes lettres à côté de la couleur : « à faire », « en retard », « à jour », « inconnu ».
- Utiliser `{typography.code}` avec `tabular-nums` pour toute donnée numérique alignée en colonne.
- Garder 44px de cible tactile minimum sur tout élément interactif.
- Distinguer visuellement les champs issus de l'extraction (`input-extracted`) jusqu'à ce que l'utilisateur les valide.
- Dire l'inconnu comme une information neutre (`{colors.muted}`), pas comme une alerte.

### Don't
- Ne jamais utiliser `success`, `warning` ou `error` en décoration, en fond de section ou sur un bouton : ces couleurs appartiennent aux états d'échéance.
- Pas de primary sur du texte de paragraphe : réservée aux CTAs, liens et focus.
- Pas d'opacité sur du texte pour l'atténuer, utiliser `{colors.muted}` ou `{colors.muted-soft}`.
- Pas de `muted-soft` sur du texte à lire, il ne passe pas AA.
- Pas de jauge, de score de santé ni de pourcentage de progression : l'application n'estime pas l'état d'un véhicule, elle croise des dates et des kilomètres.
- Pas de serif hors des tokens `display-*`, pas de taille de police hors échelle.
- Pas d'ombre pour créer de l'emphase : passer par le contraste de surfaces et les filets.

## Responsive Behavior

- Typographie de titre : `display-lg` desktop → `display-md` mobile. `display-xl` est réservé à la page publique de démonstration.
- Liste d'échéances : une colonne partout, y compris desktop, c'est une liste de lecture, pas une grille.
- Historique : tableau à partir de `md`, cards empilées en dessous (une card = une intervention).
- Navigation : barre horizontale desktop, barre d'onglets basse sur mobile (l'app est une PWA, la navigation doit rester au pouce).
- Action principale d'un formulaire : inline desktop, barre collée en bas sur mobile.

## Iteration Guide

- **Dark mode** : non implémenté en v1. Les tokens `surface-dark-*` existent pour les blocs contrastés, ils ne constituent pas un thème sombre. À reprendre si l'usage nocturne remonte.
- **Fraunces** : chargée en variable font, axes `SOFT` et `WONK` laissés par défaut. Si le rendu paraît trop typé, réduire `WONK` avant de changer de famille.
- **Animations** : `ease-out` uniquement en v1.

## Known Gaps

- **Dataviz** : aucun token de série pour la courbe de projection kilométrique (Phase 3). Ne pas piocher dans les couleurs sémantiques quand ce moment arrivera, définir une palette de séries dédiée.
- **Emails de rappel** (Phase 7) : le HTML email a ses propres contraintes (pas de webfont fiable, pas de variables CSS). Une déclinaison des tokens en valeurs littérales sera nécessaire.
- **Icônes PWA et splash screen** (Phase 8) : format, jeu de tailles et masquage iOS non spécifiés.
- **Compte de démonstration** (Phase 6) : le traitement visuel du bandeau « lecture seule, données fictives » reste à définir.
