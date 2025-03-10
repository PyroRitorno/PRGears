fx_version 'adamant'
games {'gta5'}

author 'Pyro_Ritorno'
description 'Manual/Sequential + Vehicle HUD (HRSGears)'

lua54 'yes'


client_script '@PRKeybinds/imports.lua'
shared_script '@es_extended/imports.lua'

client_scripts {
	"client.lua",
	"config.lua",
}
