# Checklist de tests

## Connexion & personnage
- [ ] Connexion license valide
- [ ] Création multichar Qbox
- [ ] Chargement identité (prénom, nom, DOB, sexe, nationalité, téléphone)
- [ ] Déconnexion / reconnexion
- [ ] Sauvegarde argent / job / metadata

## Économie
- [ ] Cash / banque via qbx_core
- [ ] Renewed-Banking (si installé)
- [ ] `rp_billing` création / paiement / refus / expiration
- [ ] Dépôt / retrait entreprise `rp_business`

## Inventaire
- [ ] ox_inventory joueur
- [ ] Coffre entreprise
- [ ] Armes / munitions / poids

## Jobs
- [ ] Police / EMS / Mécano / Taxi (qbx_*)
- [ ] Burgershot / UwU / Gouvernement / DOJ (`rp_jobs`)
- [ ] Duty on/off
- [ ] Recrutement / licenciement / promotion (boss)

## Véhicules
- [ ] Achat / spawn / rangement garage
- [ ] Fourrière + frais
- [ ] Clés `qbx_vehiclekeys`

## Interfaces
- [ ] Menu F5
- [ ] `/factures`
- [ ] `/radmin` (ACE)
- [ ] HUD (si `rp_hud` activé)

## Sécurité
- [ ] Event facture sans job → refus
- [ ] Montant négatif → refus
- [ ] Ban license → kick au connect
- [ ] SQL injection attempt → prepared statements OK

## Perf
- [ ] Client idle ~0.00 ms hors HUD
- [ ] Pas de spam events
- [ ] NUI fermée = pas d’updates inutiles
