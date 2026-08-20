--- Compat ox_lib : progressBar / progressCircle / progressActive / cancelProgress

local function vecToTable(v)
    if not v then return { x = 0.0, y = 0.0, z = 0.0 } end
    if type(v) == 'table' and v.x then
        return { x = v.x + 0.0, y = v.y + 0.0, z = v.z + 0.0 }
    end
    return { x = 0.0, y = 0.0, z = 0.0 }
end

local function normalizeProp(p)
    if not p then return nil end
    if type(p) == 'string' then return nil end
    if not p.model then return nil end

    local coords = p.coords
    if not coords and p.pos then
        coords = vecToTable(p.pos)
    end
    coords = coords or { x = 0.0, y = 0.0, z = 0.0 }

    local rotation = p.rotation
    if not rotation and p.rot then
        rotation = vecToTable(p.rot)
    end
    rotation = rotation or { x = 0.0, y = 0.0, z = 0.0 }

    return {
        model = p.model,
        bone = p.bone or 60309,
        coords = coords,
        rotation = rotation,
    }
end

local function normalizeAnim(anim)
    if not anim then return nil, nil end

    if type(anim) == 'string' then
        -- scenario
        return nil, anim
    end

    if type(anim) ~= 'table' then
        return nil, nil
    end

    if anim.scenario then
        return nil, anim.scenario
    end

    local dict = anim.dict or anim.animDict
    local clip = anim.clip or anim.anim or anim.name
    if dict and clip then
        return {
            animDict = dict,
            anim = clip,
            flags = anim.flag or anim.flags or 49,
        }, nil
    end

    return nil, nil
end

--- Accepte les options ox_lib progressBar / progressCircle
--- @param opts table
--- @return boolean success
function OxProgress(opts)
    if type(opts) ~= 'table' then
        return false
    end

    local animation, scenario = normalizeAnim(opts.anim)
    local prop, propTwo

    if opts.prop then
        if opts.prop[1] then
            prop = normalizeProp(opts.prop[1])
            propTwo = normalizeProp(opts.prop[2])
        else
            prop = normalizeProp(opts.prop)
        end
    end

    local position = opts.position
    if position == 'middle' then position = 'center' end

    return ProgressAwait({
        name = opts.name or 'ox_progress',
        label = opts.label or '',
        duration = opts.duration or Config.DefaultDuration,
        canCancel = opts.canCancel == true,
        useWhileDead = opts.useWhileDead == true,
        disarm = opts.disarm ~= false,
        animation = animation,
        scenario = scenario,
        prop = prop,
        propTwo = propTwo,
        position = position,
    })
end

function OxProgressActive()
    return isDoingSomething()
end

function OxCancelProgress()
    Cancel()
end

exports('progressBar', OxProgress)
exports('progressCircle', OxProgress)
exports('progressActive', OxProgressActive)
exports('cancelProgress', OxCancelProgress)
exports('OxProgress', OxProgress)
