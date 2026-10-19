fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'double_plumbob'
author 'Doublee'
description 'The Sims style plumbob above player heads, synced through state bags'
version '1.0.1'
repository 'https://github.com/DoubleCZ/double_plumbob'

dependency 'ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

files {
    'stream/double_plumbob.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/double_plumbob.ytyp'
