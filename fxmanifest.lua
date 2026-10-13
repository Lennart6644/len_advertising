fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'len_advertising'
description 'Advanced advertising and job announcement system'
version '2.0.0'

dependencies {
    'es_extended',
    'oxmysql'
}

shared_scripts {
    'config.lua',
    'locales/locale.lua',
    'locales/de.lua',
    'locales/en.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
