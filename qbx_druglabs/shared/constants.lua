DrugLabs = DrugLabs or {}

DrugLabs.Resource = GetCurrentResourceName()

DrugLabs.Permissions = {
    ENTER = 'ENTER',
    USE_STASH = 'USE_STASH',
    START_PRODUCTION = 'START_PRODUCTION',
    COLLECT_PRODUCTION = 'COLLECT_PRODUCTION',
    MANAGE_MEMBERS = 'MANAGE_MEMBERS',
    CHANGE_CODE = 'CHANGE_CODE',
    LOCK_LAB = 'LOCK_LAB',
    SELL_LAB = 'SELL_LAB',
}

DrugLabs.DefaultMemberPermissions = {
    ENTER = true,
    USE_STASH = true,
    START_PRODUCTION = true,
    COLLECT_PRODUCTION = true,
    MANAGE_MEMBERS = false,
    CHANGE_CODE = false,
    LOCK_LAB = false,
    SELL_LAB = false,
}

DrugLabs.OwnerPermissions = {
    ENTER = true,
    USE_STASH = true,
    START_PRODUCTION = true,
    COLLECT_PRODUCTION = true,
    MANAGE_MEMBERS = true,
    CHANGE_CODE = true,
    LOCK_LAB = true,
    SELL_LAB = true,
}

DrugLabs.Events = {
    client = {
        syncLabs = 'qbx_druglabs:client:syncLabs',
        refreshLab = 'qbx_druglabs:client:refreshLab',
        enterLab = 'qbx_druglabs:client:enterLab',
        leaveLab = 'qbx_druglabs:client:leaveLab',
        productionResult = 'qbx_druglabs:client:productionResult',
        furnaceMinigame = 'qbx_druglabs:client:furnaceMinigame',
        maskEffect = 'qbx_druglabs:client:maskEffect',
        notify = 'qbx_druglabs:client:notify',
    },
    server = {
        enterLab = 'qbx_druglabs:server:enterLab',
        leaveLab = 'qbx_druglabs:server:leaveLab',
        purchaseLab = 'qbx_druglabs:server:purchaseLab',
        rentLab = 'qbx_druglabs:server:rentLab',
        renewRent = 'qbx_druglabs:server:renewRent',
        sellLab = 'qbx_druglabs:server:sellLab',
        transferLab = 'qbx_druglabs:server:transferLab',
        unlockLab = 'qbx_druglabs:server:unlockLab',
        setLocked = 'qbx_druglabs:server:setLocked',
        changeCode = 'qbx_druglabs:server:changeCode',
        openStash = 'qbx_druglabs:server:openStash',
        startProduction = 'qbx_druglabs:server:startProduction',
        finishProduction = 'qbx_druglabs:server:finishProduction',
        cancelProduction = 'qbx_druglabs:server:cancelProduction',
        plantAction = 'qbx_druglabs:server:plantAction',
        addMember = 'qbx_druglabs:server:addMember',
        removeMember = 'qbx_druglabs:server:removeMember',
        updateMember = 'qbx_druglabs:server:updateMember',
        sealLab = 'qbx_druglabs:server:sealLab',
        unsealLab = 'qbx_druglabs:server:unsealLab',
        raidLab = 'qbx_druglabs:server:raidLab',
        seizeStash = 'qbx_druglabs:server:seizeStash',
    },
}
