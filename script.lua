COREFUNCTIONS = {}
Tunnel.bindInterface("CoreFunctions", COREFUNCTIONS)

local COREFUNCTIONS_CL = Tunnel.getInterface("CoreFunctions_CL")

WALLSYSTEM = {}
Tunnel.bindInterface("Wallsystem", WALLSYSTEM)

function bye(source, reason)
    DropPlayer(source,reason)
end

local wall_infos = {}
function WALLSYSTEM.setWallInfos()
    local source = source
    local passport = getUserId(source)
    if not wall_infos[source] then
        wall_infos[source] = {}
        wall_infos[source].Passport = (type(passport) == "number" and passport or 0)
        local name = GetPlayerName(source)
        if name == nil or name == "" or name == -1 then
            name = "N/A"
        end
        wall_infos[source].name = name
        wall_infos[source].wallstats = false
    end
    if wall_infos[source].Passport ~= passport then
        wall_infos[source].Passport = getUserId(source)
    end
end

function WALLSYSTEM.SetNewLineColor(Cor)
    TriggerClientEvent("SetLineColor", Cor)
end

function WALLSYSTEM.updatePassport(src)
    local passport = getUserId(src)
    wall_infos[src].Passport = passport
    return passport or "não encontrado"
end

function WALLSYSTEM.updateAcId(src)
    local license = GetPlayerRockstarLicense(src)
    local token = TokenAC(license)
    wall_infos[src].Acid = token
    return token or "não encontrado"
end

function WALLSYSTEM.getWallInfos()
    return wall_infos
end

RegisterCommand(
    "wall",
    function(source, args)
        local source = source
        local Passport = getUserId(source)

        if hasPermission(Passport, permissaoadm) then
            if args[1] == "on" then
                wall_infos[source].wallstats = true
                TriggerClientEvent("wall", source, wall_infos[source].wallstats)
                TriggerClientEvent("Alertaadm", source, "alertaadm", "Wall ativado.", 5000)
            elseif args[1] == "off" then
                wall_infos[source].wallstats = false
                TriggerClientEvent("wall", source, wall_infos[source].wallstats)
                TriggerClientEvent("Alertaadm", source, "alertaadm", "Wall desativado.", 5000)
            else
                TriggerClientEvent("Alertaadm", source, "alertaadm", "Uso correto: /wall on ou /wall off.", 5000)
            end
        else
            TriggerClientEvent("Alertaadm", source, "alertaadm", "Você não tem permissão para usar este comando.", 5000)
        end
    end,
    false
)

function WALLSYSTEM.GetAllInfos()
    local source = source
    local Passport = getUserId(source)
    if Passport then
        local consulta = query("GetAcId", {user_id = Passport})

        return Passport, source, getUserIdentity(Passport), consulta[1].token, GetNumPlayerIndices()
    end
end

function WALLSYSTEM.GetAllLogs()
    local Passport = getUserId(source)

    if Passport then
        if not hasPermission(Passport, permissaoadm) then
            return
        end

        return query("GetAllLogs", {})
    end
end

function WALLSYSTEM.GetAllUsers()
    local source = source
    local Passport = getUserId(source)
    if Passport then
        if not hasPermission(Passport, permissaoadm) then
            return
        end

        local players = query("GetAllusers", {})
        local tableusers = {}

        for k, v in pairs(players) do
            local src = getUserSource(v.user_id)
            if not src then
                src = "JOGADOR OFFLINE"
            end

            local userData = {
                id = v.user_id,
                src = src,
                name = getUserIdentity(parseInt(v.user_id)),
                token = v.token,
                xboxid = v.live,
                license = v.license,
                steam = v.steam,
                discord = v.discord
            }

            table.insert(tableusers, userData)
        end

        return tableusers
    end
end

function WALLSYSTEM.KickPlayer(srcrb, motivo)
    local source = source
    local Passport = getUserId(source)

    if not hasPermission(Passport, permissaoadm) then
        return
    end

    local user_id = getUserId(srcrb)

    if hasPermission(Passport, permissaoadm) then
        if user_id then
            local license = GetPlayerRockstarLicense(srcrb)
            local token = TokenAC(license)

            if not token then
                return
            end

            print("kikado", user_id, "foi kikado.")

            local nome = getUserIdentity(user_id)
            local motivo = "EXPULSO PELO PAINEL"

            execute(
                "anticheat/insertlog",
                {nome = nome, token = token, data = os.date("%d/%m/%Y"), hora = os.date("%H:%M:%S"), motivo = motivo}
            )

            bye(srcrb, motivo)
        end
    end
end

function WALLSYSTEM.SpecPlayer(srcrb, motivo)
    local source = source
    local Passport = getUserId(source)

    if not hasPermission(Passport, permissaoadm) then
        return
    end

    SpectarPlayer(srcrb)
end

function WALLSYSTEM.UnbanPlayer(acid)
    local source = source
    local Passport = getUserId(source)

    if Passport then
        if hasPermission(Passport, permissaoadm) then
            local consult = query("getuerId", {token = acid})
            if consult and consult[1] then
                local player_id = consult[1].user_id
                execute("unbanplayer", {user_id = parseInt(player_id)})
            end
        end
    end
end

function SendWebhookMessage(webhook, message, footer)
    PerformHttpRequest(webhook, 
        function(statusCode, response, headers)
            -- Verificar se há erros na resposta
            if statusCode ~= 200 then
                print("Erro ao enviar webhook: " .. statusCode)
            end
        end, 
        "POST", 
        json.encode({
            username = "MQTHAC FIVEM",
            avatar_url = "https://media.discordapp.net/attachments/1114907621917474887/1234627370095214622/goianox.png?",
            embeds = {
                {
                    color = 16758345,
                    author = {
                        name = 'MQTHAC FIVEM',
                        icon_url = 'https://media.discordapp.net/attachments/1114907621917474887/1234627370095214622/goianox.png?'
                    },
                    description = message,
                    footer = {
                        text = footer
                    }
                }
            }
        }), 
        {
            ["Content-Type"] = "application/json"
        }
    )
end

function WALLSYSTEM.BanPlayer(srcrb, motivo)
    local source = source
    local Passport = getUserId(source)

    if Passport then
        if hasPermission(Passport, permissaoadm) then
            local user_id = getUserId(srcrb)

            local license = GetPlayerRockstarLicense(srcrb)
            local token = TokenAC(license)
            if not user_id then
                return
            end
            if not token then
                return
            end
            if not isImune(token) then
                SendWebhookMessage(banimentos,"```ini\n[ID]: " .. user_id .." [BANIDO PELO PAINEL]\n[TOKEN]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
                if token then
                    print("^2" .. token .. "  " .. "^1banido pelo painel")

                    local nome = getUserIdentity(user_id)
                    local motivo = "BANIDO PELO PAINEL"

                    execute("anticheat/banauto", {license = license, token = token})
                    execute(
                        "anticheat/insertlog",
                        {
                            nome = nome,
                            token = token,
                            data = os.date("%d/%m/%Y"),
                            hora = os.date("%H:%M:%S"),
                            motivo = motivo
                        }
                    )

                    bye(srcrb, motivo)
                end
            end
        end
    end
end

function WALLSYSTEM.GetWallState()
    local source = source
    if source then
        if wall_infos[source] then
            return wall_infos[source].wallstats
        end
    end
end

function WALLSYSTEM.SetWallDistance(Distance)
    local source = source
    if source then
        if wall_infos[source] then
            wall_infos[source].walldistance = Distance
        end
    end
end

function WALLSYSTEM.GetWalLDistance()
    local source = source
    if source then
        if wall_infos[source] then
            return wall_infos[source].walldistance
        end
    end
end

function WALLSYSTEM.GetLinesState()
    local source = source
    if wall_infos[source].linesstate == true then
        return true
    elseif wall_infos[source].linesstate == false then
        return false
    end
    return false
end

function WALLSYSTEM.EnableWall()
    local source = source
    local Passport = getUserId(source)

    if hasPermission(Passport, permissaoadm) then
        if not wall_infos[source].wallstats then
            wall_infos[source].wallstats = true
            TriggerClientEvent("wall", source, wall_infos[source].wallstats)
            TriggerClientEvent("Alertaadm", source, "alertaadm", "Wall ativado.", 5000)
        elseif wall_infos[source].wallstats then
            wall_infos[source].wallstats = false
            TriggerClientEvent("wall", source, wall_infos[source].wallstats)
            TriggerClientEvent("Alertaadm", source, "alertaadm", "Wall desativado.", 5000)
        end
    end
end

function WALLSYSTEM.EnableLines()
    local source = source
    local Passport = getUserId(source)

    if hasPermission(Passport, permissaoadm) then
        if not wall_infos[source].linesstate or wall_infos[source].linesstate == nil then
            wall_infos[source].linesstate = true
            TriggerClientEvent("Lines", source, wall_infos[source].linesstate)
            TriggerClientEvent("Alertaadm", source, "alertaadm", "Lines ativado.", 5000)
        elseif wall_infos[source].linesstate then
            wall_infos[source].linesstate = false
            TriggerClientEvent("Lines", source, wall_infos[source].linesstate)
            TriggerClientEvent("Alertaadm", source, "alertaadm", "Lines desativado.", 5000)
        end
    end
end


function GetPlayerRockstarLicense(source)
    local identifiers = GetPlayerIdentifiers(source)

    local license = "Não encontrado"
    local steam = "Não encontrado"
    local discord = "Não encontrado"
    local live = "Não encontrado"

    for _, identifier in ipairs(identifiers) do
        if string.match(identifier, "license:") then
            license = string.sub(identifier, 9)
        elseif string.match(identifier, "steam:") then
            steam = string.sub(identifier, 6)
        elseif string.match(identifier, "discord:") then
            discord = string.sub(identifier, 9)
        elseif string.match(identifier, "live:") then
            live = string.sub(identifier, 6)
        end
    end

    return license, steam, discord, live
end

function TokenAC(license)
    local result = query("anticheat/infotoken", {license = license})
    if result and result[1] then
        return result[1].token
    else
        return nil
    end
end

function GenerateRandomId(length)
    local abyte = string.byte("A")
    local zbyte = string.byte("0")
    local number = ""

    for i = 1, length do
        local charType = math.random(1, 2)
        local char = nil

        if charType == 1 then
            char = string.char(zbyte + math.random(0, 9))
        else
            char = string.char(abyte + math.random(0, 25))
        end

        number = number .. char
    end

    return number
end

function CheckTokenExists(license)
    local result = query("anticheat/infotoken", {license = license})
    if result and result[1] then
        return true
    else
        return false
    end
end

function InsertToken(user_id, license, token, steam, discord, live)
    execute(
        "anticheat/novotoken",
        {user_id = user_id, license = license, token = token, steam = steam, discord = discord, live = live}
    )
end

AddEventHandler(
    "playerConnecting",
    function(name, setKickReason, deferrals)
        local source = source
        local license, steam, discord, live = GetPlayerRockstarLicense(source)

        if license then
            deferrals.defer()
            deferrals.update("Analisando suas informações...")

            Citizen.Wait(1000)

            local token = TokenAC(license)

            if not token then
                local user_id = getUserId(source)
                if not user_id then
                    Wait(1000)
                    print("^2Um novo jogador se conectando.^0")
                    return
                end

                local newToken = GenerateRandomId(8)
                InsertToken(user_id, license, newToken, steam, discord, live)
                Wait(1000)
                print("^2Novo token " .. newToken .. "^0")
                token = newToken
            end

            Citizen.Wait(1000)

            local result_ban = query("anticheat/infoplayer", {license = license, token = token})
            local is_banned = result_ban and result_ban[1] and result_ban[1].banned == true

            if is_banned then
                local user_id = getUserId(source)
                Wait(1000)
                print(
                    "^2Jogador com [ID]: " .. user_id .. " e [TOKEN]: " .. token .. "^1 banido ^0tentando se conectar."
                )
                deferrals.done("Você está banido. [ID]: " .. user_id .. " e [TOKEN]: " .. token)
                return
            end

            deferrals.done()
        end
    end
)

function SpectarPlayer(srcrb)
    local source = source
    local user_id = getUserId(source)
    local player = getUserId(srcrb)

    if hasPermission(user_id, permissaoadm) then
        local mundo = GetPlayerRoutingBucket(srcrb)
        if mundo then
            SetPlayerRoutingBucket(source, mundo)
            TriggerClientEvent("Alertaadm", source, "alertaadm", "Você está spectando um jogador: ", 5000)
            Wait(1000)
        end
        if GetPlayerName(srcrb) and source ~= srcrb then
            local coords = GetEntityCoords(GetPlayerPed(srcrb))
            if coords.x ~= 0 and coords.y ~= 0 and coords.z ~= 0 then
                TriggerClientEvent("9DUWAG9DUWHA9DUYWA89ASHDUWA", source, coords, srcrb)
            end
        else
            TriggerClientEvent("Alertaadm", source, "alertaadm", "Você não pode se espectar a si mesmo!", 5000)
        end
    end
end

RegisterCommand("acban",function(source, args, rawCommand)
    local source = source

    args[1] = tonumber(args[1])

    if not args[1] then
        print("^2COLOCA O ID CORRETO!^0")
        return
    end

    if type(args[1]) ~= "number" then
        print("^2COLOCA UM ID E NÃO LETRA!^0")
        return
    end

    if source == 0 then
        local banir = args[1]
        if tonumber(banir) > 0 then
            local infos = query("anticheat/GetInfos", {user_id = args[1]})
            if infos[1] then
                if infos[1].banned then
                    execute("anticheat/banir", {banned = 0, user_id = args[1]})
                    print("Você removeu o banimento do ID " .. args[1])
                elseif not infos[1].banned then
                    print("Você baniu o ID " .. args[1])
                    execute("anticheat/banir", {banned = 1, user_id = args[1]})

                    if getUserSource(parseInt(args[1])) then
                        bye(getUserSource(parseInt(args[1])), "Você foi banido.")
                    end
                end
            end
        end

        return
    end

    local user_id = getUserId(source)

    if user_id then
        if hasPermission(user_id, permissaobanunban) then
            local banir = args[1]
            if tonumber(banir) > 0 then
                local infos = query("anticheat/GetInfos", {user_id = args[1]})
                if infos[1] then
                    if infos[1].banned then
                        execute("anticheat/banir", {banned = 0, user_id = args[1]})
                        TriggerClientEvent("Alertaadm", source, "alertaadm", "Você removeu o banimento do ID " .. args[1], 5000)
                    elseif not infos[1].banned then
                        TriggerClientEvent("Alertaadm", source, "alertaadm", "Você baniu o ID " .. args[1], 5000)
                        execute("anticheat/banir", {banned = 1, user_id = args[1]})

                        if getUserSource(parseInt(args[1])) then
                            bye(getUserSource(parseInt(args[1])), "Você foi banido.")
                        end
                    end
                end
            end
        end
    end
end)

RegisterCommand(acmenu, function(source, args)
    local source = source
    local user_id = getUserId(source)
    
    if user_id ~= nil then
        if hasPermission(user_id, permissaomenu) then
            TriggerClientEvent('acmenu:open', source)
        else
            TriggerClientEvent('Alertaadm', source, 'alertaadm', 'Você não possui permissão', 5000)
        end
    end
end)

RegisterCommand(limparlocal, function(source, args, rawCommand)
        local source = source
        local user_id = getUserId(source)
        local plyCoords = GetEntityCoords(GetPlayerPed(source))
        local x, y, z = plyCoords[1], plyCoords[2], plyCoords[3]

        if hasPermission(user_id, permissaoadm) then
        TriggerClientEvent("limpandoessaporra", -1, x, y, z)
    end
end)

RegisterCommand(acveh, function(source, args)
    local source = source
    local user_id = getUserId(source)
    if user_id ~= nil then
        if hasPermission(user_id, permissaoadm) then
            for k, v in ipairs(GetAllVehicles()) do
                if DoesEntityExist(v) then
                    DeleteEntity(v)
                end
            end
        else
            TriggerClientEvent("Alertaadm", source, "alertaadm", "Você não possui permissão", 5000)
        end
    end
end)

RegisterCommand(acprops, function(source, args)
    local source = source
    local user_id = getUserId(source)
    if user_id ~= nil then
        if hasPermission(user_id, permissaoadm) then
            for k, v in ipairs(GetAllObjects()) do
                if DoesEntityExist(v) then
                    DeleteEntity(v)
                end
            end
        else
            TriggerClientEvent("Alertaadm", source, "alertaadm", "Você não possui permissão", 5000)
        end
    end
end)

RegisterCommand(acpeds,function(source, args)
    local source = source
    local user_id = getUserId(source)
    if user_id ~= nil then
        if hasPermission(user_id, permissaoadm) then
            for k, v in ipairs(GetAllPeds()) do
                if DoesEntityExist(v) then
                    DeleteEntity(v)
                end
            end
        else
            TriggerClientEvent("Alertaadm", source, "alertaadm", "Você não possui permissão", 5000)
        end
    end
end)

local blacklistCars = true
local blacklistPeds = true
local blacklistProps = true
local blacklistWeapons = true

local function printPed(message)
    if printPeds then
        print(message)
    end
end

local function printProp(message)
    if printProps then
        print(message)
    end
end

local function printVeh(message)
    if printVehs then
        print(message)
    end
end

function COREFUNCTIONS.UpDateState(name, status)
    if name == "VEÍCULOS" then
        blacklistCars = status
        if blacklistCars then
            uhgerutrCars()
        end
    end

    if name == "PEDS" then
        blacklistPeds = status
        if blacklistPeds then
            uhgerutrPeds()
        end
    end

    if name == "PROPS" then
        blacklistProps = status
        if blacklistProps then
            uhgerutrProps()
        end
    end

    if name == "ARMAS" then
        blacklistWeapons = status
        COREFUNCTIONS_CL.SetBlackListWeaponsState(-1, status)
    end
end

function COREFUNCTIONS.GetBlackListCarsState()
    return blacklistCars
end

function COREFUNCTIONS.GetBlackListWeaponsState()
    return blacklistWeapons
end

function COREFUNCTIONS.GetBlackListPedsState()
    return blacklistPeds
end

function COREFUNCTIONS.GetBlackListPropsState()
    return blacklistProps
end

function isImune(token)
    for _, imuneToken in ipairs(tokens) do
        if token == imuneToken then
            return true
        end
    end
    return false
end

function RegisterTunnel.CheckImune()
    local source = source
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)

    return isImune(token)
end

function RegisterTunnel.armamentos(weapon)
    local source = source
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)
    if not isImune(token) then
        SendWebhookMessage(banimentos, "```ini\n[ID]: " .. user_id .. " [BANIDO] " .. "\n[ARMA]: " .. weapon .. "\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
        TriggerClientEvent("bostaliquidabanida",source)
        if token then
            print("^2" .. token .. "  " .. "^1banido^0")
            local nome = getUserIdentity(user_id)
            local motivo = "SPAWN DE ARMA!"
            execute("anticheat/banauto", {license = license, token = token})
            execute("anticheat/insertlog",{nome = nome, token = token, data = os.date("%d/%m/%Y"), hora = os.date("%H:%M:%S"), motivo = motivo})
            bye(source, "te peguei gostosa")
        end
    end
end

RegisterServerEvent("iohdawuhh843diwajdwa43")
AddEventHandler("iohdawuhh843diwajdwa43", function()
    local source = source
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)
    
    if token then
        SendWebhookMessage(
            banimentos, 
            "```ini\n[ID]: " .. user_id .. " [BANIDO POR TENTATIVA DE REVIVER]\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```"
        )
        TriggerClientEvent("bostaliquidabanida", source)
        print("^2" .. token .. "  " .. "^1banido^0")
        
        local nome = getUserIdentity(user_id)
        local motivo = "TENTATIVA DE REVIVER"
        
        execute("anticheat/banauto", { license = license, token = token })
        execute("anticheat/insertlog", {
            nome = nome, 
            token = token, 
            data = os.date("%d/%m/%Y"), 
            hora = os.date("%H:%M:%S"), 
            motivo = motivo 
        })
        
        bye(source, "te peguei gostosa")
    end
end)

RegisterServerEvent("bandevtools")
AddEventHandler("bandevtools", function()
    local source = source
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)
    
    if token then
        SendWebhookMessage(
            banimentos, 
            "```ini\n[ID]: " .. user_id .. " [BANIDO POR DEV TOOLS]\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```"
        )
        TriggerClientEvent("bostaliquidabanida", source)
        print("^2" .. token .. "  " .. "^1banido^0")
        
        local nome = getUserIdentity(user_id)
        local motivo = "DEV TOOLS"
        
        execute("anticheat/banauto", { license = license, token = token })
        execute("anticheat/insertlog", {
            nome = nome, 
            token = token, 
            data = os.date("%d/%m/%Y"), 
            hora = os.date("%H:%M:%S"), 
            motivo = motivo 
        })
        
        bye(source, "te peguei gostosa")
    end
end)

RegisterServerEvent("bannedvizziontermic")
AddEventHandler("bannedvizziontermic", function()
    local source = source
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)
    
    if token then
        SendWebhookMessage(
            banimentos, 
            "```ini\n[ID]: " .. user_id .. " [BANIDO POR VISÃO HACK]\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```"
        )
        TriggerClientEvent("bostaliquidabanida", source)
        print("^2" .. token .. "  " .. "^1banido^0")
        
        local nome = getUserIdentity(user_id)
        local motivo = "VISÃO HACK"
        
        execute("anticheat/banauto", { license = license, token = token })
        execute("anticheat/insertlog", {
            nome = nome, 
            token = token, 
            data = os.date("%d/%m/%Y"), 
            hora = os.date("%H:%M:%S"), 
            motivo = motivo 
        })
        
        bye(source, "te peguei gostosa")
    end
end)

RegisterServerEvent("danodehackcarente")
AddEventHandler("danodehackcarente", function()
    local source = source
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)

    if token then
        SendWebhookMessage(banimentos, "```ini\n[ID]: " .. user_id .. " [BANIDO POR MULTIPLICADOR DE DANO]\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
        TriggerClientEvent("bostaliquidabanida", source)
        print("^2" .. token .. "  " .. "^1banido^0")
        
        local nome = getUserIdentity(user_id)
        local motivo = "MULTIPLICADOR DE DANO"
        
        execute("anticheat/banauto", {license = license, token = token})
        execute("anticheat/insertlog", {
            nome = nome, 
            token = token, 
            data = os.date("%d/%m/%Y"), 
            hora = os.date("%H:%M:%S"), 
            motivo = motivo
        })
        
        bye(source, "te peguei gostosa")
    end
end)

AddEventHandler("weaponDamageEvent", function(a, b)
    if tonumber(b.weaponDamage) > 150 and tonumber(b.weaponType) == 2725352035 then
        CancelEvent()
        TriggerEvent("danodehackcarente")
    end
end)

function RegisterTunnel.RemoveCar(vehicle)
    local source = source
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)
    if not isImune(token) then
        SendWebhookMessage(banimentos, "```ini\n[ID]: " .. user_id .. " [BANIDO] " .. "\n[VEICULO]: " .. vehicle .. "\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
        TriggerClientEvent("bostaliquidabanida",source)
        if token then
            print("^2" .. token .. "  " .. "^1banido^0")
            local nome = getUserIdentity(user_id)
            local motivo = "SPAWN DE CARRO"
            execute("anticheat/banauto", {license = license, token = token})
            execute("anticheat/insertlog",{nome = nome, token = token, data = os.date("%d/%m/%Y"), hora = os.date("%H:%M:%S"), motivo = motivo})
            bye(source, "te peguei gostosa")
        end
    end
end

function RegisterTunnel.BlacklistedPed(pedModel)
    local source = source
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)
    if not isImune(token) then
        SendWebhookMessage(banimentos, "```ini\n[ID]: " .. user_id .. " [BANIDO] " .. "\n[PED]: " .. pedModel .. "\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```" )
        TriggerClientEvent("bostaliquidabanida",source)
        if token then
            print("^2" .. token .. "  " .. "^1banido^0")
            local nome = getUserIdentity(user_id)
            local motivo = "SPAWN DE PED"
            execute("anticheat/banauto", {license = license, token = token})
            execute("anticheat/insertlog",{nome = nome, token = token, data = os.date("%d/%m/%Y"), hora = os.date("%H:%M:%S"), motivo = motivo})
            bye(source, "te peguei gostosa")
        end
    end
end

function RegisterTunnel.Speedgunammo()
    local source = source
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)
    if not isImune(token) then
        SendWebhookMessage(banimentos, "```ini\n[ID]: " .. user_id .. " [SUSPEITO POR SUPER TIRO]\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```" )
        TriggerClientEvent("ogyh8iequarhjyeqrw3hu8iyoerwjt", source)
        if token then
            print("^2" .. token .. "  " .. "^1Suspeito por hack^0")
        end
    end
end

function RegisterTunnel.Spawndearma()
    local source = source
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)
    if not isImune(token) then
        SendWebhookMessage(banimentos, "```ini\n[ID]: " .. user_id .. " [BANIDO POR SPAWN DE ARMA E MUNI]\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
        TriggerClientEvent("bostaliquidabanida",source)
        if token then

            print("^2" .. token .. "  " .. "^1banido^0")
            local nome = getUserIdentity(user_id)
            local motivo = "SPAWN DE ARMA E MUNIÇÃO"
            execute("anticheat/banauto", {license = license, token = token})
            execute("anticheat/insertlog",{nome = nome, token = token, data = os.date("%d/%m/%Y"), hora = os.date("%H:%M:%S"), motivo = motivo} )
            bye(source, "te peguei gostosa")
        end
    end
end

RegisterServerEvent("UDWADGHWPAIYHD89WAD8I0SA8DHWA9IDAWDH0SADYHWA8")
AddEventHandler(
    "UDWADGHWPAIYHD89WAD8I0SA8DHWA9IDAWDH0SADYHWA8",
    function()
        local source = source
        local license = GetPlayerRockstarLicense(source)
        local token = TokenAC(license)
        if not isImune(token) then
            local user_id = getUserId(source)
            SendWebhookMessage(banimentos,"```ini\n[ID]: " .. user_id .." [BANIDO POR VELOCIDADE ANORMAL]\n[Token]: " ..token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
            TriggerClientEvent("bostaliquidabanida",source)
            if token then
                print("^2" .. token .. "  " .. "^1banido^0")
                local nome = getUserIdentity(user_id)
                local motivo = "VELOCIDADE ANORMAL!"
                print("^2" .. token .. "  " .. "^1banido^0")
                execute("anticheat/banauto", {license = license, token = token})
                execute("anticheat/insertlog",{nome = nome,token = token,data = os.date("%d/%m/%Y"),hora = os.date("%H:%M:%S"),motivo = motivo})
                bye(source, "te peguei gostosa")
            end
        end
    end
)

local explosivedemerdacarente = {0, 1, 2, 3, 4, 5, 7, 8, 10, 11, 14, 16, 18, 25, 29, 31, 32, 33, 35, 36, 37, 38, 49, 70}

function RegisterTunnel.MuniExplosiva(playerId)
    local source = playerId
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)

    if not isImune(token) then
        Wait(100)
        SendWebhookMessage(banimentos,"```ini\n[ID]: " .. user_id .. " [BANIDO POR EXPLODIR PLAYER]\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
        TriggerClientEvent("bostaliquidabanida",source)
        if token then

            print("^2" .. token .. "  " .. "^1banido^0")
            local nome = getUserIdentity(user_id)
            local motivo = "EXPLODIR PLAYER!"

            execute("anticheat/banauto", {license = license, token = token})

            execute("anticheat/insertlog",{nome = nome, token = token, data = os.date("%d/%m/%Y"), hora = os.date("%H:%M:%S"), motivo = motivo})

            bye(source, "te peguei gostosa")
        end
    end
end

AddEventHandler(
    "explosionEvent",
    function(sender, ev)
        CancelEvent()

        if sender ~= nil then
            local player = GetPlayerPed(sender)
            local plycds = GetEntityCoords(player)
            local expcds = vector3(ev.posX, ev.posY, ev.posZ)
            local plydist = #(plycds - expcds)

            if plydist <= 150 then
                for _, exp in ipairs(explosivedemerdacarente) do
                    if ev.explosionType == exp then
                        RegisterTunnel.MuniExplosiva(sender)
                        return
                    end
                end
            end
        end
    end
)

RegisterCommand("print", function(source, args, rawCommand)
    local source = source
    local user_id = getUserId(source)
    if user_id then
        if hasPermission(user_id, permissaoadm) then
            if args[1] and parseInt(args[1]) then
                local nsource = getUserSource(parseInt(args[1]))
                TriggerClientEvent("printeivckkkk", nsource)
            end
        end
    end
end)

function RegisterTunnel.Explosaosuspeita(playerId)
    local source = playerId
    local user_id = getUserId(source)
    local license = GetPlayerRockstarLicense(source)
    local token = TokenAC(license)
    local plyCoords = GetEntityCoords(GetPlayerPed(source))
    local x, y, z = plyCoords[1], plyCoords[2], plyCoords[3]

    if not isImune(token) then
        Wait(1000)
        SendWebhookMessage(suspeitos, "```ini\n[ID]: " .. user_id .. " [SUSPEITO POR EXPLOSIVO HACK]\n[Token]: " .. token .. "\n[Data]: " .. os.date("%d/%m/%Y [Hora]: %H:%M:%S") .. "\n[Coordenadas]: " .. x .. ", " .. y .. ", " .. z .. "\r```")
        TriggerClientEvent("ogyh8iequarhjyeqrw3hu8iyoerwjt", source)
        if token then
            Wait(1000)
            print("^2" .. token .. "  " .. "^1SUSPEITO POR EXPLOSIVO HACK^0")
        end
    end
end

local explosaosuspeitademerda = { 9 }

AddEventHandler(
    "explosionEvent",
    function(sender, ev)
        CancelEvent()

        if sender ~= nil then
            local player = GetPlayerPed(sender)
            local plycds = GetEntityCoords(player)
            local expcds = vector3(ev.posX, ev.posY, ev.posZ)
            local plydist = #(plycds - expcds)

            if plydist <= 150 then
                for _, exp in ipairs(explosaosuspeitademerda) do
                    if ev.explosionType == exp then
                        RegisterTunnel.Explosaosuspeita(sender)
                        return
                    end
                end
            end
        end
    end
)

function uhgerutrCars()
    local vehicles = GetAllVehicles()
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local modelHash = GetEntityModel(vehicle)
            local isForbidden = false
            for _, forbiddenHash in pairs(vehshack) do
                if modelHash == forbiddenHash then
                    isForbidden = true
                    break
                end
            end
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
        end
    end
end

AddEventHandler(
    "entityCreated",
    function(entity)
        if DoesEntityExist(entity) then
            if not blacklistCars then
                return
            end

            local modelHash = GetEntityModel(entity)
            local vehicles = GetAllVehicles()

            for k, v in ipairs(vehicles) do
                if DoesEntityExist(v) then
                    local modelHash = GetEntityModel(v)
                    printVeh("vehs hash:  "..modelHash)
                    local isForbidden = false

                    for _, forbiddenHash in pairs(vehshack) do
                        if modelHash == forbiddenHash then
                            isForbidden = true
                            break
                        end
                    end

                    if isForbidden then
                        local source = NetworkGetEntityOwner(v)
                        local license = GetPlayerRockstarLicense(source)
                        local token = TokenAC(license)
                        if not isImune(token) then
                            if token then
                                local user_id = getUserId(source)
                                local nome = getUserIdentity(user_id)
                                local motivo = "SPAWN DE VEICULO COM HASH NA BLACKLIST!"

                                print("^2" .. token .. "  " .. "^1banido^0")
                                SendWebhookMessage(banimentos, "```ini\n[ID]: " .. user_id .. " [BANIDO POR SPAWN DE VEICULO]\n[Token]: " .. token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
                                TriggerClientEvent("bostaliquidabanida",source)
                                execute("anticheat/banauto", {license = license, token = token})
                                execute("anticheat/insertlog",{nome = nome,token = token,data = os.date("%d/%m/%Y"),hora = os.date("%H:%M:%S"),motivo = motivo})
                                bye(source, "te peguei gostosa")
                                if DoesEntityExist(v) then
                                    DeleteEntity(v)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
)

local forbiddenVehicles = {
    1058115860,
}

AddEventHandler("entityCreated", function(entity)
    if DoesEntityExist(entity) then
        local modelHash = GetEntityModel(entity)
        local vehicles = GetAllVehicles()

        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) then
                local vehicleModelHash = GetEntityModel(vehicle)
                local isForbidden = false

                for _, forbiddenHash in ipairs(forbiddenVehicles) do
                    if vehicleModelHash == forbiddenHash then
                        isForbidden = true
                        break
                    end
                end

                if isForbidden then
                    DeleteEntity(vehicle)
                end
            end
        end
    end
end)

function uhgerutrPeds()
    local peds = GetAllPeds()
    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped) then
            local modelHash = GetEntityModel(ped)
            local isForbidden = false
            for _, forbiddenHash in pairs(pedhashlist) do
                if modelHash == forbiddenHash then
                    isForbidden = true
                    break
                end
            end
            if isForbidden then
                if DoesEntityExist(ped) then
                    DeleteEntity(ped)
                end
            end
        end
    end
end

AddEventHandler(
    "entityCreated",
    function(entity)
        if not blacklistPeds then
            return
        end

        if DoesEntityExist(entity) then
            local modelHash = GetEntityModel(entity)
            printPed("ped hash:  "..modelHash)
            local objects = GetAllPeds()

            for k, v in ipairs(objects) do
                if DoesEntityExist(v) then
                    local modelHash = GetEntityModel(v)
                    local isForbidden = false

                    for _, forbiddenHash in pairs(pedhashlist) do
                        if modelHash == forbiddenHash then
                            isForbidden = true
                            break
                        end
                    end

                    if isForbidden then
                        local source = NetworkGetEntityOwner(v)
                        local license = GetPlayerRockstarLicense(source)
                        local token = TokenAC(license)

                        if token then
                            local user_id = getUserId(source)
                            local nome = getUserIdentity(user_id)
                            local motivo = "SPAWN DE PEDS COM HASH NA BLACKLIST!"
                            print("^2" .. token .. "  " .. "^1banido^0")
                            SendWebhookMessage(banimentos,"```ini\n[ID]: " .. user_id .." [BANIDO POR SPAWN DE PEDS]\n[Token]: " ..token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
                            TriggerClientEvent("bostaliquidabanida",source)
                            execute("anticheat/banauto", {license = license, token = token})
                            execute("anticheat/insertlog",{nome = nome,token = token,data = os.date("%d/%m/%Y"),hora = os.date("%H:%M:%S"),motivo = motivo})
                            bye(source, "te peguei gostosa")
                            if DoesEntityExist(v) then
                                DeleteEntity(v)
                            end
                        end
                    end
                end
            end
        end
    end
)

function uhgerutrProps()
    local objects = GetAllObjects()
    for k, v in ipairs(objects) do
        if DoesEntityExist(v) then
            local modelHash = GetEntityModel(v)
            local isForbidden = false

            for _, forbiddenHash in pairs(objetoshack) do
                if modelHash == forbiddenHash then
                    isForbidden = true
                    break
                end
            end

            if isForbidden then
                if DoesEntityExist(v) then
                    DeleteEntity(v)
                end
            end
        end
    end
end

AddEventHandler(
    "entityCreated",
    function(entity)
        if DoesEntityExist(entity) then
            if not blacklistProps then
                return
            end

            local modelHash = GetEntityModel(entity)
            local objects = GetAllObjects()

            for k, v in ipairs(objects) do
                if DoesEntityExist(v) then
                    local modelHash = GetEntityModel(v)
                    printProp("prop hash:  " .. modelHash)
                    local isForbidden = false

                    for _, forbiddenHash in pairs(objetoshack) do
                        if modelHash == forbiddenHash then
                            isForbidden = true
                            break
                        end
                    end

                    if isForbidden then
                        local source = NetworkGetEntityOwner(v)
                        local license = GetPlayerRockstarLicense(source)
                        local token = TokenAC(license)

                        if token then
                            local user_id = getUserId(source)
                            local nome = getUserIdentity(user_id)
                            local motivo = "SPAWN DE OBJETOS COM HASH NA BLACKLIST!"
                            print("^2" .. token .. "  " .. "^1banido^0")
                            SendWebhookMessage(banimentos,"```ini\n[ID]: " .. user_id .." [BANIDO POR SPAWN DE OBJETOS]\n[Token]: " ..token .. os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S") .. " \r```")
                            TriggerClientEvent("bostaliquidabanida",source)
                            execute("anticheat/banauto", {license = license, token = token})
                            execute("anticheat/insertlog",{nome = nome,token = token,data = os.date("%d/%m/%Y"),hora = os.date("%H:%M:%S"),motivo = motivo})
                            bye(source, "te peguei gostosa")
                            if DoesEntityExist(v) then
                                DeleteEntity(v)
                            end
                        end
                    end
                end
            end
        end
    end
)