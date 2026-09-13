local resourceName = GetCurrentResourceName()

CreateThread(function()
    print(('[TPM Clothing Studio] Server booted for resource "%s".'):format(resourceName))
end)

RegisterNetEvent('tpm_clothing_studio:screenshot:capture', function(filename)
    local playerId = source

    if type(filename) ~= 'string' or filename == '' then
        print(('[TPM Clothing Studio] Refused screenshot request from %s because the filename was invalid.'):format(playerId))
        return
    end

    exports['screenshot-basic']:requestClientScreenshot(playerId, {
        fileName = filename,
        encoding = Config.Screenshot.encoding,
        quality = Config.Screenshot.quality
    }, function(error)
        if error then
            print(('[TPM Clothing Studio] Screenshot failed for %s: %s'):format(playerId, error))
            return
        end

        print(('[TPM Clothing Studio] Screenshot saved for %s as "%s".'):format(playerId, filename))
    end)
end)
