# Organisation des ressources

| Dossier | Contenu attendu |
|---------|-----------------|
| `[core]` | Ressources CFX de base si tu ne passes pas par les defaults artifacts |
| `[ox]` | oxmysql, ox_lib, ox_inventory, ox_target, ox_doorlock |
| `[qbx]` | qbx_core + modules Qbox |
| `[voice]` | pma-voice, microphones, markers de voix |
| `[phone]` | lb-phone et dépendances |
| `[housing]` | ps-housing, ps-realtor, shells |
| `[jobs]` | Jobs légaux (EMS, mécano, taxi, …) |
| `[crimi]` | Scripts illégaux non-vibe (ou futurs modules) |
| `[vibe]` | Scripts custom du serveur (stubs fournis) |
| `[standalone]` | HUD, admin, xsound, utils |
| `[maps]` | MLO / mapdata / IPL |
| `[vehicles]` | Packs véhicules |
| `[stream]` | Props / streams divers |

Les groupes entre crochets sont démarrés via `ensure [nom]` dans `server.cfg`.
