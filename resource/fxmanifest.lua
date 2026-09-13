fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'TPM Clothing Studio'
author 'TPM'
description 'A production-focused FiveM clothing preview and capture toolkit.'
version '0.0.5-alpha'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'client/core/namespace.lua',
    'client/core/logger.lua',
    'client/core/module_loader.lua'
}

client_scripts {
    'client/studio/main.lua',
    'client/camera/main.lua',
    'client/clothing/main.lua',
    'client/menu/main.lua',
    'client/controls/main.lua',
    'client/screenshot/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'screenshot-basic'
}

files {
    'html/index.html',
    'html/app.css',
    'html/app.js'
}
