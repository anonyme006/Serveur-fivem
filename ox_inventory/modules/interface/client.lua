if not lib then return end

-- Module is deprecated and provided for compatibility
-- Progress routé vers esx_progressbar (capsule orange) si disponible

local function progressBar(options)
	if GetResourceState('esx_progressbar') == 'started' then
		return exports['esx_progressbar']:progressBar(options)
	end
	return lib.progressBar(options)
end

local function progressActive()
	if GetResourceState('esx_progressbar') == 'started' then
		return exports['esx_progressbar']:progressActive()
	end
	return lib.progressActive()
end

local function cancelProgress()
	if GetResourceState('esx_progressbar') == 'started' then
		return exports['esx_progressbar']:cancelProgress()
	end
	return lib.cancelProgress()
end

exports('Keyboard', lib.inputDialog)

exports('Progress', function(options, completed)
	local success = progressBar(options)

	if completed then
		completed(not success)
	end
end)

exports('CancelProgress', cancelProgress)
exports('ProgressActive', progressActive)
