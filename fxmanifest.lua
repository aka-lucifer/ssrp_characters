------------------------------------------------------------------------------------
-- LX Characters
-- Designed & Written By akaLucifer#0103
-- Releasing or Claiming this as your own is against, this resources License
------------------------------------------------------------------------------------
fx_version "bodacious"
game "gta5"

this_is_a_map "yes"

ui_page "client/ui/index.html"

files {
	"configs/client.json",
  "client/ui/libraries/css/*.css",
  "client/ui/libraries/js/*.js",
	"client/ui/assets/fonts/*.eot",
	"client/ui/assets/fonts/*.svg",
	"client/ui/assets/fonts/*.ttf",
	"client/ui/assets/fonts/*.otf",
	"client/ui/assets/img/**/*.png",
	"client/ui/assets/img/**/*.jpg",
	"client/ui/assets/blips/*.png",
	"client/ui/assets/mapStyles/**/*.jpg",
	"client/ui/index.html",
	"client/ui/*.js",
	"client/ui/style.css"
}

client_scripts {
	"client/classes/*.lua",
	"client/managers/*.lua",
	"client/main.lua"
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	"server/managers/*.lua",
	"server/main.lua"
}

-- # Resource Changes
  -- Made changes to `qb-apartments`
  -- `lx_characters` New character & spawner resource 
  -- `qb-spawn & qb-multicharacter` is now replaced with the new character and spawner system, so they can both be deleted.