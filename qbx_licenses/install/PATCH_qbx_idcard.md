--[[
    Patch optionnel pour qbx_idcard (um-idcard)

    Dans resources/[qbx]/qbx_idcard/main/server.lua, dans l'event
    `um-idcard:server:sendData`, après avoir construit `data` :

        local data = exports.qbx_core:GetPlayer(source).PlayerData.charinfo
        data.sex = data.gender == 0 and 'Male' or 'Female'
        data.cardtype = item or "id_card"
        data.mugShot = metadata.mugShot

        -- >>> AJOUTER :
        if GetResourceState('qbx_licenses') == 'started' then
            data = exports.qbx_licenses:EnrichCardData(source, data)
        end
        -- <<<

        TriggerClientEvent('um-idcard:client:sendData', src, data)

    Puis dans web/index.html, ajouter sous la nationalité :

        <li>
            <span>Points permis</span>
            <span id="driverPoints" class="info"></span>
        </li>

    Et dans web/js/main.js, dans openIdCard :

        if (playerData.driverPoints != null) {
          getElementById('driverPoints').textContent =
            `${playerData.driverPoints}/${playerData.driverMaxPoints} (${playerData.driverStatus})`;
        }

    Note : la ressource qbx_licenses embarque déjà sa propre carte complète
    (4 permis + points live) via /mespermis ou l'item permis.
]]
