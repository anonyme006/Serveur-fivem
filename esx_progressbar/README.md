# esx_progressbar

Barre de progression NUI **capsule orange** (rail sombre, remplissage doré), pour actions in-game FiveM.

## Aperçu

Ouvrir `html/preview.html` dans un navigateur.

## Installation

```cfg
ensure esx_progressbar
```

Aucune dépendance obligatoire (ESX non requis). Compatible avec tout framework.

## Usage

```lua
exports['esx_progressbar']:Progress({
    name = 'search',
    label = 'Fouille…',
    duration = 5000,
    canCancel = true,
    animation = {
        animDict = 'amb@prop_human_bum_bin@idle_b',
        anim = 'idle_d',
        flags = 49,
    },
}, function(cancelled)
    if cancelled then
        print('annulé')
    else
        print('terminé')
    end
end)
```

### Exports

| Export | Description |
|--------|-------------|
| `Progress(action, finish)` | Lance la barre |
| `ProgressAwait(action)` | Bloquant — `true` si terminé, `false` si annulé |
| `ProgressWithStartEvent(action, start, finish)` | Callback au démarrage |
| `ProgressWithTickEvent(action, tick, finish)` | Tick chaque frame |
| `isDoingSomething()` | `true` si une action est en cours |
| `Cancel()` | Annule l’action en cours |

### Intégrations

- [`pa_garage`](../pa_garage) — rangement / sortie / fourrière
- [`ox_inventory`](../ox_inventory) — manger, boire, craft (`usetime`)

### API compatible ox_lib

```lua
exports['esx_progressbar']:progressBar({ label = '…', duration = 3000, canCancel = true, anim = { dict = '…', clip = '…' } })
exports['esx_progressbar']:progressCircle({ ... }) -- même barre capsule
exports['esx_progressbar']:progressActive()
exports['esx_progressbar']:cancelProgress()
```

### Événements

```lua
TriggerEvent('esx_progressbar:client:progress', { label = '…', duration = 3000 })
TriggerEvent('esx_progressbar:client:cancel')
```

### Test in-game

```
/testprogress [durée_ms] [label]
```

## Config

Voir `config.lua` — couleur, taille, position (`bottom` / `center`), annulation.
