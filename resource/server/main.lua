local resourceName = GetCurrentResourceName()

CreateThread(function()
    print(('[TPM Clothing Studio] Server booted for resource "%s".'):format(resourceName))
end)
