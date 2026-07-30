--- Bridge esx_progressbar (capsule orange) avec fallback ox_lib

function GarageProgress(opts)
    if GetResourceState('esx_progressbar') == 'started' then
        return exports['esx_progressbar']:progressBar(opts)
    end
    return lib.progressCircle(opts)
end
