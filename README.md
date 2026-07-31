# RE ROLL — Site GTA RP

Interface web dark / rouge pour un serveur GTA RP (FiveM), inspirée d’un panel joueur type RE ROLL.

## Pages

- `/` — Landing page (hero, skyline, CTAs)
- `/login` — Connexion Discord (démo)
- `/panel` — Accueil joueur (whitelist + file d’attente)
- `/panel/personnage` — Fiche personnage
- `/panel/vehicules` — Liste des véhicules
- `/panel/images`, `/panel/mrp`, `/panel/medias` — Pages placeholder

## Stack

- React 19 + TypeScript
- Vite
- React Router
- Lucide icons

## Démarrage

```bash
npm install
npm run dev
```

Build production :

```bash
npm run build
npm run preview
```

## Notes

La connexion Discord est simulée côté front (bouton → panel). Branchez ensuite un vrai OAuth Discord / API FiveM pour les données live.
