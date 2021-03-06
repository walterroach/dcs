-- execute(dofile) this script at the end of
-- of 'DCS World\MissionEditor\modules\me_mission.lua'
-- base.dofile("path\\pydcs_export.lua")

-------------------------------------------------------------------------------
-- settings
-------------------------------------------------------------------------------

-- edit export_path to your export folder
local export_path = "C:\\Users\\peint\\Documents\\dcs\\dcs\\"

local loadLiveries = require('loadLiveries')

-------------------------------------------------------------------------------
-- helper functions
-------------------------------------------------------------------------------
local function writeln(file, text)
    file:write(text.."\r\n")
end

local function safe_name(name)
    local safeName = name
    safeName = string.gsub(safeName, "[-()/., *'+`#%[%]]", "_")
    safeName = string.gsub(safeName, "_*$", "")  -- strip __ from end
    safeName = string.gsub(safeName, "^([0-9])", "_%1")
    if safeName == 'None' then
        safeName = 'None_'
    end
    return safeName
end

-------------------------------------------------------------------------------
-- country to shortname mapping
-------------------------------------------------------------------------------
local countries = {}
countries["Russia"] = "RUS"
countries["Ukraine"] = "UKR"
countries["USA"] = "USA"
countries["Turkey"] = "TUR"
countries["UK"] = "UK"
countries["France"] = "FRA"
countries["Germany"] = "GER"
countries["USAFAggressors"] = "AUSAF"
countries["Canada"] = "CAN"
countries["Spain"] = "SPN"
countries["TheNetherlands"] = "NETH"
countries["Belgium"] = "BEL"
countries["Norway"] = "NOR"
countries["Denmark"] = "DEN"
countries["Israel"] = "ISR"
countries["Georgia"] = "GRG"
countries["Insurgents"] = "INS"
countries["Abkhazia"] = "ABH"
countries["SouthOssetia"] = "RSO"
countries["Italy"] = "ITA"
countries["Australia"] = "AUS"
countries["Switzerland"] = "SUI"
countries["Austria"] = "AUT"
countries["Belarus"] = "BLR"
countries["Bulgaria"] = "BGR"
countries["CzechRepublic"] = "CZE"
countries["China"] = "CHN"
countries["Croatia"] = "HRV"
countries["Egypt"] = "EGY"
countries["Finland"] = "FIN"
countries["Greece"] = "GRC"
countries["Hungary"] = "HUN"
countries["India"] = "IND"
countries["Iran"] = "IRN"
countries["Iraq"] = "IRQ"
countries["Japan"] = "JPN"
countries["Kazakhstan"] = "KAZ"
countries["NorthKorea"] = "PRK"
countries["Pakistan"] = "PAK"
countries["Poland"] = "POL"
countries["Romania"] = "ROU"
countries["SaudiArabia"] = "SAU"
countries["Serbia"] = "SRB"
countries["Slovakia"] = "SVK"
countries["SouthKorea"] = "KOR"
countries["Sweden"] = "SWE"
countries["Syria"] = "SYR"

-------------------------------------------------------------------------------
-- prepare and export weapons data
-------------------------------------------------------------------------------
local weapons = {}
local keys = {}
for j in pairs({CAT_BOMBS,CAT_MISSILES,CAT_ROCKETS,CAT_AIR_TO_AIR,CAT_FUEL_TANKS,CAT_PODS}) do
	for i, v in ipairs(db.Weapons.Categories[j].Launchers) do
		local pyName = v.displayName
		if string.sub(v.CLSID, 0, 1) ~= "{" then
			pyName = v.CLSID
		end
		pyName = string.gsub(pyName, "[-()/., *']", "_")
		pyName = string.gsub(pyName,"^([0-9])", "_%1")
		key = pyName
		if weapons[key] ~= nil then
			key = pyName .. "_"
		end
		local w = "None"
		if v["Weight"] ~= nil then
			w = v["Weight"]
		end
		while weapons[key] ~= nil do
			key = key..'_'
		end
		weapons[key] = {clsid = v.CLSID, displayName = v.displayName, weight = w}
		table.insert(keys, key)
		-- print("    " .. key .. " = {\"clsid\": \"" .. v.CLSID .. "\", \"name\": \"" .. v.displayName .. "\"}")
	end
end

table.sort( keys )

local weapons_map = {}
local i = 1
while i <= #keys do
	local x = keys[i]
	weapons_map[weapons[x].clsid] = x
	i = i + 1
end

file = io.open(export_path.."weapons_data.py", "w")
file:write([[# This file is generated from pydcs_export.lua


class Weapons:
]])
local i = 1
while i <= #keys do
	local x = keys[i]
	writeln(file, "    " .. x .. " = {\"clsid\": \"" .. weapons[x].clsid
		.. "\", \"name\": \"" .. weapons[x].displayName .. "\", \"weight\": " .. weapons[x].weight .. "}")
	i = i + 1
end

writeln(file, '')
writeln(file, "weapon_ids = {")
i = 1
while i <= #keys do
	local x = keys[i]
	local s = "    \"" .. weapons[x].clsid .. "\": Weapons." .. x
	i = i + 1
	if i <= #keys then
		s = s .. ","
	end
	writeln(file, s)
end
writeln(file, "}")
file:close()


-------------------------------------------------------------------------------
-- aircraft export planes and helicopters
-------------------------------------------------------------------------------
local flyable = {}
flyable["A-10A"] = true
flyable["A-10C"] = true
flyable["Su-27"] = true
flyable["Su-33"] = true
flyable["Su-25"] = true
flyable["Su-25T"] = true
flyable["M-2000C"] = true
flyable["F-15C"] = true
flyable["MiG-29A"] = true
flyable["MiG-29S"] = true
flyable["P-51D"] = true
flyable["TF-51D"] = true
flyable["FW-190D9"] = true
flyable["Bf-109K-4"] = true
flyable["C-101EB"] = true
flyable["F-86F Sabre"] = true
flyable["Hawk"] = true
flyable["L-39C"] = true
flyable["L-39ZA"] = true
flyable["MiG-15bis"] = true
flyable["MiG-21Bis"] = true
flyable["Ka-50"] = true
flyable["Mi-8MT"] = true
flyable["UH-1H"] = true
flyable["SpitfireLFMkIX"] = true
flyable["SA342M"] = true
flyable["AV8BNA"] = true


local function export_aircraft(file, aircrafts, export_type, exportplane)
    -- generate export output
    file:write(
[[# This file is generated from pydcs_export.lua

from .weapons_data import Weapons
from . import task
from .unittype import FlyingType
from enum import Enum


]])
    writeln(file, 'class '..export_type..'Type(FlyingType):')
    if exportplane then
        writeln(file, '    pass')
    else
        writeln(file, '    helicopter = True')
    end
    writeln(file, '')
    writeln(file, '')

    for i in pairs(aircrafts) do
        local plane = aircrafts[i];
        local safename = plane.Name
        safename = string.gsub(safename, "[-()/., *']", "_")
        safename = string.gsub(safename,"^([0-9])", "_%1")
        writeln(file, "class "..safename.."("..export_type.."Type):")
        writeln(file, '    id = "'..plane.type..'"')
        if plane.HumanCockpit or flyable[plane.type] ~= nil then
            writeln(file, '    flyable = True')
        end
        if plane.singleInFlight then
            writeln(file, '    group_size_max = 1')
        end
        if plane.bigParkingRamp then
            writeln(file, '    large_parking_slot = True')
        end
        writeln(file, '    height = '..plane.height)
        if exportplane then
            writeln(file, '    width = '..plane.wing_span or plane.rotor_diameter)
        else
            writeln(file, '    width = '..plane.rotor_diameter)
        end
        writeln(file, '    length = '..plane.length)
        writeln(file, '    fuel_max = '..plane.MaxFuelWeight)
        writeln(file, '    max_speed = '..plane.MaxSpeed)
        --writeln(file, '    ammo_type = '..plane.MaxFuelWeight)
        --writeln(file, '    gun_max = '..)
        if plane.passivCounterm then
            writeln(file, '    chaff = '..plane.passivCounterm.chaff.default)
            writeln(file, '    flare = '..plane.passivCounterm.flare.default)
            writeln(file, '    charge_total = '..plane.passivCounterm.SingleChargeTotal)
            writeln(file, '    chaff_charge_size = '..plane.passivCounterm.chaff.chargeSz)
            writeln(file, '    flare_charge_size = '..plane.passivCounterm.flare.chargeSz)
        end

        if plane.TACAN then
            writeln(file, '    tacan = True')
        end

        if plane.EPLRS then
            writeln(file, '    eplrs = True')
        end

        if plane.Categories and plane.Categories[1] then
            local clsid = plane.Categories[1]
            if plane.Categories[1].CLSID then
                clsid = plane.Categories[1].CLSID
            end
            local s = '    category = "'
            if clsid == "{D2BC159C-5B7D-40cf-92CD-44DF3E99FAA9}" then
                s = s..'AWACS'
            elseif clsid == "{8A302789-A55D-4897-B647-66493FA6826F}" then
                s = s..'Tankers'
            elseif clsid == "{78EFB7A2-FD52-4b57-A6A6-3BF0E1D6555F}" then
                s = s..'Interceptor'
            else
                s = s..'Air'
            end
            writeln(file, s..'"  #'..clsid)  -- category
        end

        -- panel radio
        if plane.HumanRadio then
            local bwritefreq = false
            if exportplane and plane.HumanRadio.frequency ~= 251 then
                bwritefreq = true
            end
            if not exportplane and plane.HumanRadio.frequency ~= 127.5 then
                bwritefreq = true
            end
            if bwritefreq then
                writeln(file, '    radio_frequency = '..plane.HumanRadio.frequency)
            end
            -- modulation seems always to be nil
            -- if plane.HumanRadio.modulation ~= nil then
            --     writeln(file, '    radio_modulation = '..plane.HumanRadio.modulation)
            -- end
        end
        if plane.panelRadio then
            writeln(file, '')
            writeln(file, '    panel_radio = {')
            for j in pairs(plane.panelRadio) do
                cnt = 0
                writeln(file, '        '..j..': {')
                writeln(file, '            "channels": {')
                for c in pairs(plane.panelRadio[j]["channels"]) do
                    channel = plane.panelRadio[j]["channels"][c]
                    local s = '                '..c..': '..channel.default
                    if cnt + 1 < #plane.panelRadio[j]["channels"] then
                       s = s..','
                    end
                    writeln(file, s)
                    cnt = cnt + 1
                end
                writeln(file, '            },')
                writeln(file, '        },')
            end
            writeln(file, '    }')
        end

        if plane.SpecificCallnames then
            writeln(file, '')
            writeln(file, '    callnames = {')
            for c in pairs(plane.SpecificCallnames) do
                writeln(file, '        "'..country.by_idx[c].Name..'": [')
                for n in pairs(plane.SpecificCallnames[c]) do
                    writeln(file, '            "'..plane.SpecificCallnames[c][n][1]..'",')
                end
                writeln(file, '        ]')
            end
            writeln(file, '    }')
        end

        if plane.AddPropAircraft then
            writeln(file, '')
            -- default dict
            writeln(file, '    property_defaults = {')
            for j in pairs(plane.AddPropAircraft) do
                local prop = plane.AddPropAircraft[j]
                local defval = prop.defValue
                if defval == true then
                    defval = 'True'
                elseif defval == false then
                    defval = 'False'
                else
                    defval = tostring(defval)
                end
                writeln(file, '        "'..safe_name(prop.id)..'": '..defval..',')
            end
            writeln(file, '    }')

            writeln(file, '')
            writeln(file, '    class Properties:')
            for j in pairs(plane.AddPropAircraft) do
                local prop = plane.AddPropAircraft[j]
                writeln(file, '')
                writeln(file, '        class '..safe_name(prop.id)..':')
                writeln(file, '            id = "'..prop.id..'"')
                if prop.values then
                    writeln(file, '')
                    writeln(file, '            class Values:')
                    for k, val in pairs(prop.values) do
                        writeln(file, '                '..safe_name(val.dispName)..' = '..tostring(val.id))
                    end
                end
            end
        end

        writeln(file, '')
        writeln(file, '    class Liveries:')
        for j in pairs(countries) do
            local schemes = loadLiveries.loadSchemes(plane.type, countries[j])
            if schemes ~= nil and #schemes > 0 then
                writeln(file, '')
                writeln(file, '        class '..j..'(Enum):')
                for k in pairs(schemes) do
                    local liv_safe = safe_name(schemes[k].itemId)
                    writeln(file, '            '..liv_safe..' = "'..schemes[k].itemId..'"')
                end
            end
        end

        local pylons = {}

        for j in pairs(plane.Pylons) do
            if #plane.Pylons[j].Launchers > 0 then
                writeln(file, "")
                table.insert(pylons, j)
                writeln(file, '    class Pylon'..j..':')
                for k in pairs(plane.Pylons[j].Launchers) do
                    if weapons_map[plane.Pylons[j].Launchers[k].CLSID] then
                        local name = weapons_map[plane.Pylons[j].Launchers[k].CLSID]
                        writeln(file, '        '..name..' = ('..j..', Weapons.'..name..')')
                    else
                        if plane.Pylons[j].Launchers[k].CLSID then
                            writeln(file, '#ERRR '..plane.Pylons[j].Launchers[k].CLSID)
                        end
                    end
                end
            end
        end

        writeln(file, "")
        local s = ''
        for j in pairs(pylons) do
            s = s..tostring(pylons[j])
            if j < #pylons then
                s = s..', '
            end
        end
        writeln(file, '    pylons = {'..s..'}')

        -- tasks
        writeln(file, "")
        s = ''
        j = 1
        while j <= #plane.Tasks do
            local objname = string.gsub(plane.Tasks[j].Name, "[-()/., *']", "")
            s = s..'task.'..objname..''
            j = j + 1
            if j <= #plane.Tasks then
                s = s..', '
            end
        end
        writeln(file, '    tasks = ['..s..']')
        local objname = string.gsub(plane.DefaultTask.Name, "[-()/., *']", "")
        writeln(file, '    task_default = task.'..objname..'')
        -- writeln(file, safename..'.load_payloads()')
        writeln(file, "")
        writeln(file, "")
    end


    writeln(file, string.lower(export_type).."_map = {")
    for i in pairs(aircrafts) do
        local plane = aircrafts[i];
        local safename = plane.Name
        safename = string.gsub(safename, "[-()/., *']", "_")
        safename = string.gsub(safename,"^([0-9])", "_%1")
        writeln(file, '    "'..plane.type..'": '..safename..',')
    end
    writeln(file, "}")
end

local file = io.open(export_path.."planes.py", "w")
export_aircraft(file, db.Units.Planes.Plane, 'Plane', true)
file:close()

aircrafts = db.Units.Helicopters.Helicopter
local file = io.open(export_path.."helicopters.py", "w")
export_aircraft(file, db.Units.Helicopters.Helicopter, 'Helicopter', false)
file:close()


-------------------------------------------------------------------------------
-- ground units
-------------------------------------------------------------------------------
local file = io.open(export_path.."vehicles.py", "w")

file:write(
[[# This file is generated from pydcs_export.lua

from . import unittype
]])

-- sort by categories
local unit_categories = {}
unit_categories["Unarmed"] = {}
unit_categories["AirDefence"] = {}
unit_categories["Armor"] = {}
unit_categories["Fortification"] = {}
unit_categories["Artillery"] = {}
unit_categories["Infantry"] = {}
unit_categories["Carriage"] = {}
unit_categories["Locomotive"] = {}

for i in pairs(db.Units.Cars.Car) do
    local unit = db.Units.Cars.Car[i]
    if unit.category == 'Air Defence' then
        table.insert(unit_categories["AirDefence"], unit)
    else
        table.insert(unit_categories[unit.category], unit)
    end
end

for i in pairs(unit_categories) do
    writeln(file, '')
    writeln(file, '')
    writeln(file, 'class '..i..':')
    for j in pairs(unit_categories[i]) do
        local unit = unit_categories[i][j]
        local safename = safe_name(unit.DisplayName)
        writeln(file, '')
        writeln(file, '    class '..safename..'(unittype.VehicleType):')
        writeln(file, '        id = "'..unit.type..'"')
        writeln(file, '        name = "'..unit.DisplayName..'"')
        if unit.EPLRS then
            writeln(file, '        eprls = True')
        end
        --writeln(file, '        category = '..i)
    end
end

writeln(file, '')
writeln(file, "vehicle_map = {")
for i in pairs(db.Units.Cars.Car) do
    local unit = db.Units.Cars.Car[i];
    local safename = safe_name(unit.DisplayName)
    local cat = "AirDefence"
    if unit.category ~= "Air Defence" then
        cat = unit.category
    end
    writeln(file, '    "'..unit.type..'": '..cat..'.'..safename..',')
end
writeln(file, "}")
file:close()


-------------------------------------------------------------------------------
-- static units
-------------------------------------------------------------------------------
local file = io.open(export_path.."statics.py", "w")

file:write(
[[# This file is generated from pydcs_export.lua

from . import unittype
]])

local function lookup_map(file, parent, arr, b_parent)
    if b_parent == nil then
        b_parent = true
    end
    writeln(file, '')
    writeln(file, string.lower(parent).."_map = {")
    for i in pairs(arr) do
        local unit = arr[i];
        local safename = safe_name(unit.DisplayName)
        if b_parent then
            writeln(file, '    "'..unit.type..'": '..parent..'.'..safename..',')
        else
            writeln(file, '    "'..unit.type..'": '..safename..',')
        end
    end
    writeln(file, "}")
end

writeln(file, '')
writeln(file, '')
writeln(file, 'class Fortification:')
for i in pairs(db.Units.Fortifications.Fortification) do
    local unit = db.Units.Fortifications.Fortification[i]
    local safename = safe_name(unit.DisplayName)
    writeln(file, '')
    writeln(file, '    class '..safename..'(unittype.StaticType):')
    writeln(file, '        id = "'..unit.type..'"')
    writeln(file, '        name = "'..unit.DisplayName..'"')
    writeln(file, '        shape_name = "'..unit.ShapeName..'"')
    writeln(file, '        rate = '..unit.Rate)
    if unit.SeaObject ~= nil and unit.SeaObject then
        writeln(file, '        sea_object = True')
    end
end

lookup_map(file, "Fortification", db.Units.Fortifications.Fortification)

writeln(file, '')
writeln(file, '')
writeln(file, 'class GroundObject:')
for i in pairs(db.Units.GroundObjects.GroundObject) do
    local unit = db.Units.GroundObjects.GroundObject[i]
    local safename = safe_name(unit.DisplayName)
    writeln(file, '')
    writeln(file, '    class '..safename..'(unittype.StaticType):')
    writeln(file, '        id = "'..unit.type..'"')
    writeln(file, '        name = "'..unit.DisplayName..'"')
    writeln(file, '        category = ""')
end

lookup_map(file, "GroundObject", db.Units.GroundObjects.GroundObject)

writeln(file, '')
writeln(file, '')
writeln(file, 'class Warehouse:')
for i in pairs(db.Units.Warehouses.Warehouse) do
    local unit = db.Units.Warehouses.Warehouse[i]
    local safename = safe_name(unit.DisplayName)
    writeln(file, '')
    writeln(file, '    class '..safename..'(unittype.StaticType):')
    writeln(file, '        id = "'..unit.type..'"')
    writeln(file, '        name = "'..unit.DisplayName..'"')
    writeln(file, '        shape_name = "'..unit.ShapeName..'"')
    writeln(file, '        category = "Warehouses"')
    writeln(file, '        rate = '..unit.Rate)
    if unit.SeaObject ~= nil and unit.SeaObject then
        writeln(file, '        sea_object = True')
    end
end

lookup_map(file, "Warehouse", db.Units.Warehouses.Warehouse)

writeln(file, '')
writeln(file, '')
writeln(file, 'class Cargo:')
for i in pairs(db.Units.Cargos.Cargo) do
    local unit = db.Units.Cargos.Cargo[i]
    local safename = safe_name(unit.DisplayName)
    writeln(file, '')
    writeln(file, '    class '..safename..'(unittype.StaticType):')
    writeln(file, '        id = "'..unit.type..'"')
    writeln(file, '        name = "'..unit.DisplayName..'"')
    writeln(file, '        shape_name = "'..unit.ShapeName..'"')
    writeln(file, '        category = "Cargos"')
    writeln(file, '        rate = '..unit.Rate)
    writeln(file, '        can_cargo = True')
end

lookup_map(file, "Cargo", db.Units.Cargos.Cargo)

file:close()


-------------------------------------------------------------------------------
-- ship units
-------------------------------------------------------------------------------
local file = io.open(export_path.."ships.py", "w")

file:write(
[[# This file is generated from pydcs_export.lua

from . import unittype
]])

for i in pairs(db.Units.Ships.Ship) do
    local unit = db.Units.Ships.Ship[i]
    local safename = safe_name(unit.DisplayName)
    writeln(file, '')
    writeln(file, '')
    writeln(file, 'class '..safename..'(unittype.ShipType):')
    writeln(file, '    id = "'..unit.type..'"')
    writeln(file, '    name = "'..unit.DisplayName..'"')
    if unit.Plane_Num_ ~= nil then
        writeln(file, '    plane_num = '..unit.Plane_Num_)
    end
    if unit.Helicopter_Num_ ~= nil then
        writeln(file, '    helicopter_num = '..unit.Helicopter_Num_)
    end
    if unit.numParking ~= nil then
        writeln(file, '    parking = '..unit.numParking)
    end
--    writeln(file, '    shape_name = "'..unit.ShapeName..'"')
--    writeln(file, '    rate = '..unit.Rate)
end

lookup_map(file, "ship", db.Units.Ships.Ship, false)

-------------------------------------------------------------------------------
-- export country data
-------------------------------------------------------------------------------
file = io.open(export_path.."countries.py", "w")

local categories = {
    'AWACS',
    'Tankers',
    'Air',
    'Helipad',
    'Ground Units',
    'GrassAirfield'
}

local function getUnit(arr, _type)
    for i in pairs(arr) do
        local unit = arr[i]
        if unit.type == _type then
            return unit
        end
    end
    return nil
end

local name_mapping = {}
name_mapping["FW_190D9"] = "Fw_190_D_9"
name_mapping["Bf_109K_4"] = "Bf_109_K_4"
name_mapping["F_86F_Sabre"] = "F_86F"
name_mapping["Mi_8MT"] = "Mi_8MTV2"
name_mapping["E_2C"] = "E_2D"
name_mapping["RQ_1A_Predator"] = "MQ_1A_Predator"
name_mapping["KC130"] = "KC_130"
name_mapping["AV8BNA"] = "AV_8B_N_A"
name_mapping["SpitfireLFMkIX"] = "Spitfire_LF_Mk__IX"

writeln(file, '# This file is generated from pydcs_export.lua')
writeln(file, '')
writeln(file, 'from .country import Country')
writeln(file, 'from . import vehicles')
writeln(file, 'from . import planes')
writeln(file, 'from . import helicopters')
writeln(file, 'from . import ships')
local i = 0
while i <= country.maxIndex do
    local c = country.by_idx[i]
    if c then
        local pyName = c.Name
        pyName = string.gsub(pyName, "[-()/., *']", "")
        writeln(file, '')
        writeln(file, '')
        writeln(file, 'class '..pyName..'(Country):')
        writeln(file, '    id = '..i)
        writeln(file, '    name = "'..c.Name..'"')
        writeln(file, '')

        writeln(file, '    class Vehicle:')

        -- sort country vehicles by category
        local unit_categories = {}
        unit_categories["Unarmed"] = {}
        unit_categories["AirDefence"] = {}
        unit_categories["Armor"] = {}
        unit_categories["Fortification"] = {}
        unit_categories["Artillery"] = {}
        unit_categories["Infantry"] = {}
        unit_categories["Carriage"] = {}
        unit_categories["Locomotive"] = {}

        local cars = c.Units.Cars.Car
        for u in pairs(cars) do
            local unit = {}
            for i in pairs(db.Units.Cars.Car) do
                unit = db.Units.Cars.Car[i]
                if unit.type == cars[u].Name then
                    break
                end
            end

            if unit.category == 'Air Defence' then
                table.insert(unit_categories["AirDefence"], unit)
            else
                table.insert(unit_categories[unit.category], unit)
            end
        end

        for i in pairs(unit_categories) do
            if #unit_categories[i] > 0 then
                writeln(file, '')
                writeln(file, '        class '..i..':')
                for j in pairs(unit_categories[i]) do
                    local unit = unit_categories[i][j]
                    local safename = safe_name(unit.DisplayName)
                    writeln(file, '            '..safename..' = vehicles.'..i..'.'..safename)
                end
            end
        end

        local planes = c.Units.Planes.Plane
        if #planes > 0 then
            writeln(file, '')
            writeln(file, '    class Plane:')
            for u in pairs(planes) do
                local safeName = safe_name(planes[u].Name)
                local idname = safeName
                if name_mapping[safeName] ~= nil then
                    idname = name_mapping[safeName]
                end
                writeln(file, '        '..safeName..' = planes.'..idname)
            end

            writeln(file, '')
            writeln(file, '    planes = [')
            for u in pairs(planes) do
                local safeName = safe_name(planes[u].Name)
                writeln(file, '        Plane.'..safeName..',')
            end
            writeln(file, '    ]')
        end

        local helis = c.Units.Helicopters.Helicopter
        if #helis > 0 then
            writeln(file, '')
            writeln(file, '    class Helicopter:')
            for u in pairs(helis) do
                local safeName = safe_name(helis[u].Name)
                local idname = safeName
                if name_mapping[safeName] ~= nil then
                    idname = name_mapping[safeName]
                end
                writeln(file, '        '..safeName..' = helicopters.'..idname)
            end

            writeln(file, '')
            writeln(file, '    helicopters = [')
            for u in pairs(helis) do
                local safeName = safe_name(helis[u].Name)
                writeln(file, '        Helicopter.'..safeName..',')
            end
            writeln(file, '    ]')
        end

        local ships = c.Units.Ships.Ship
        if #ships > 0 then
            writeln(file, '')
            writeln(file, '    class Ship:')
            for u in pairs(ships) do
                local funit = getUnit(db.Units.Ships.Ship, ships[u].Name)
                local safeName = safe_name(funit.DisplayName)
                writeln(file, '        '..safeName..' = ships.'..safeName)
            end
        end

        local countrycall = db.Callnames[i]
        if countrycall then
            for cat in pairs(categories) do
                local call = db.Callnames[i][categories[cat]]
                if call then
                    safeName = string.gsub(categories[cat], "[-()/., *']", "")
                    writeln(file, '')
                    writeln(file, '    class Callsign'..safeName..':')
                    for j in pairs(call) do
                        callsignSafe = safe_name(call[j].Name)
                        writeln(file, '        '..callsignSafe..' = "'..call[j].Name..'"')
                    end
                end
            end

            writeln(file, '')
            writeln(file, '    callsign = {')
            for cat in pairs(categories) do
                local call = db.Callnames[i][categories[cat]]
                if call then
                    safeName = string.gsub(categories[cat], "[-()/., *']", "")
                    writeln(file, '        "'..safeName..'": [')
                    local s = ''
                    for j in pairs(call) do
                        callsignSafe = safe_name(call[j].Name)
                        s = '            Callsign'..safeName..'.'..callsignSafe
                        if j < #call then
                            s = s..','
                        end
                        writeln(file, s)
                    end
                    writeln(file, '        ],')
                end
            end
            writeln(file, '    }')
        end

        writeln(file, '')
        writeln(file, '    def __init__(self):')
        writeln(file, '        super('..pyName..', self).__init__('..pyName..'.id, '..pyName..'.name)')
    end
    i = i + 1
end

writeln(file, '')
writeln(file, 'country_dict = {')
i = 0
while i <= country.maxIndex do
    local c = country.by_idx[i]
    if c then
        local pyName = c.Name
        pyName = string.gsub(pyName, "[-()/., *']", "")
        writeln(file, '    '..pyName..'.id: '..pyName..',')
    end
    i = i + 1
end
writeln(file, '}')

writeln(file, [[


def get_by_id(_id: int):
    """Returns a new country object for the given country id

    Args:
        _id: id for the country

    Returns:
        Country: a new country object
    """
    return country_dict[_id]()
]])
file:close()
