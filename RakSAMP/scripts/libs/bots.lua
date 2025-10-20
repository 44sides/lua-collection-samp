local luasql = require('luasql.sqlite3')
local env = luasql.sqlite3()
local conn = env:connect('my_database.db')

local function get_credentials(group)
	local dict, cursor = {}, conn:execute('SELECT nick, password FROM accounts')
	local account = cursor:fetch({}, 'a')
	while account do
		dict[account.nick] = account.password
		account = cursor:fetch(account, 'a')
	end
	cursor:close() conn:close() env:close()
	return dict
end

local b = {

}

b.CREDENTIALS = {
	MEDIC = { -- [1] = 6 rang, first logged
		{'Nick_Name', 'password'}, {'Nick_Name', 'password'}
	},
	INSTRUCTOR = {
		{'Nick_Name', 'password'}, {'Nick_Name', 'password'}
	},
	ROBBER = { -- [1] = armed, 6 rang, last logged
		{'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}
	},
	CROUPIER = {
		{'Nick_Name', 'password'}, {'Nick_Name', 'password'}
	},
	GRIB = {
		{'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}
	},
	TAXI = {
		{'Nick_Name', 'password'}, {'Nick_Name', 'password'}
	},
	POLICE = { -- [1] == skin 96, [2] == skin 95, [3] == skin 96
		{'Nick_Name', 'password'}, {'Nick_Name', 'password'}, {'Nick_Name', 'password'}
	},
	ARMY = {
		{'Nick_Name', 'password'}
	},
	TRANSFER = {
		{'Nick_Name', 'password'}
	},
	LAVKA = get_credentials('lavka'),
}

b.WHITELIST = {'Nick_Name', 'Nick_Name'}

-- deprecated
b.MEDIC = {b.CREDENTIALS.MEDIC[1][1], b.CREDENTIALS.MEDIC[2][1]}
b.INSTRUCTOR = {b.CREDENTIALS.INSTRUCTOR[1][1], b.CREDENTIALS.INSTRUCTOR[2][1]}
b.ROBBER = {b.CREDENTIALS.ROBBER[1][1], b.CREDENTIALS.ROBBER[2][1], b.CREDENTIALS.ROBBER[3][1]}
b.CROUPIER = {b.CREDENTIALS.CROUPIER[1][1], b.CREDENTIALS.CROUPIER[2][1]}
b.GRIB = {b.CREDENTIALS.GRIB[1][1], b.CREDENTIALS.GRIB[2][1], b.CREDENTIALS.GRIB[3][1], b.CREDENTIALS.GRIB[4][1], b.CREDENTIALS.GRIB[5][1], b.CREDENTIALS.GRIB[6][1], b.CREDENTIALS.GRIB[7][1], b.CREDENTIALS.GRIB[8][1], b.CREDENTIALS.GRIB[9][1], b.CREDENTIALS.GRIB[10][1], b.CREDENTIALS.GRIB[11][1], b.CREDENTIALS.GRIB[12][1], b.CREDENTIALS.GRIB[13][1], b.CREDENTIALS.GRIB[14][1], b.CREDENTIALS.GRIB[15][1], b.CREDENTIALS.GRIB[16][1], b.CREDENTIALS.GRIB[17][1], b.CREDENTIALS.GRIB[18][1], b.CREDENTIALS.GRIB[19][1], b.CREDENTIALS.GRIB[20][1], b.CREDENTIALS.GRIB[21][1], b.CREDENTIALS.GRIB[22][1], b.CREDENTIALS.GRIB[23][1], b.CREDENTIALS.GRIB[24][1], b.CREDENTIALS.GRIB[25][1], b.CREDENTIALS.GRIB[26][1], b.CREDENTIALS.GRIB[27][1], b.CREDENTIALS.GRIB[28][1], b.CREDENTIALS.GRIB[29][1], b.CREDENTIALS.GRIB[30][1]}
b.TAXI = {b.CREDENTIALS.TAXI[1][1], b.CREDENTIALS.TAXI[2][1]}
b.POLICE = {b.CREDENTIALS.POLICE[1][1], b.CREDENTIALS.POLICE[2][1], b.CREDENTIALS.POLICE[3][1]}
b.ARMY = {b.CREDENTIALS.ARMY[1][1]}
b.TRANSFER = {b.CREDENTIALS.TRANSFER[1][1]}

function b.keysToList(dict)
	local l = {}
	for k, _ in pairs(dict) do
		table.insert(l, k)
	end
	return l
end

function b.lists(...)
	local cl = {}
	for _, l in ipairs({...}) do
		for _, v in ipairs(l) do
			table.insert(cl, v)
		end
	end
	return cl
end

function b.contains(l, el)
    for _, v in ipairs(l) do
        if v == el then
            return true
        end
    end
    return false
end

function b.isSubset(subl, superl)
    for _, v in ipairs(subl) do
        if not b.contains(superl, v) then
            return false
        end
    end
    return true
end

return b