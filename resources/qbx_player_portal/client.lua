--- Client minimal : affichage du code de liaison uniquement.
--- Aucun secret SQL / API ici.

RegisterNetEvent('qbx_player_portal:client:showCode', function(code, ttl)
    lib.notify({
        title = 'Portail joueur',
        description = ('Code : %s — valide %ss'):format(code, ttl),
        type = 'success',
        duration = 12000,
    })

    lib.setClipboard(code)
end)

-- Pas d'events confiance client → serveur pour argent / véhicules / permissions
