-- Callbacks ox_lib — étapes suivantes

lib.callback.register('qbx-taxi:server:getPublicConfig', function()
    return Taxi.GetPublicConfig()
end)

lib.callback.register('qbx-taxi:server:getPlayerStatus', function(source)
    return {
        isTaxiEmployee = TaxiServer.IsTaxiEmployee(source),
        grade = TaxiServer.GetJobGrade(source),
        gradeLabel = Taxi.GetGradeLabel(TaxiServer.GetJobGrade(source)),
        onDuty = TaxiServer.IsOnDuty(source),
        company = {
            name = Config.Company.name,
            shortName = Config.Company.shortName,
            stateOwned = Config.CompanyStateOwned,
        },
    }
end)
