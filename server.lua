local API = {}

local accountsCache = {} -- Cache para futuras consultas de saldo
local historyCache = {} -- Cache para futuras consultas de histórico

function API.getAccount(userSteam,blockCreate)
    if accountsCache[userSteam] then    -- 
        return accountsCache[userSteam] --  caso ja tenha sido consultado retorna o cache
    end                                 --

    local account = exports['oxmysql']:query_async("SELECT balance FROM bank_accounts WHERE steam = @steam",{ steam = userSteam }) 
    if account and account[1] then                                                                                 -- caso ja exista uma conta seta o cache e retorna
        accountsCache[userSteam] = account[1]                                                                      --                                   
        return accountsCache[userSteam]                                                                            --
    end                                                                                                            --                                  

    if not blockCreate then                                                                                     -- caso não tenha sido consultado e o parametro blockCreate não esteja setado
        exports['oxmysql']:query("INSERT INTO bank_accounts (steam,balance) VALUES(@steam,0)",{steam = userSteam}) -- 
        accountsCache[userSteam] = {                                                                      -- caso não exista uma conta cria uma nova e seta o cache
            balance = 0,                                                                                  -- 
        }      
        return accountsCache[userSteam] -- retorna o cache 
    end                                                                                          --

    return false -- caso não exista uma conta e o parametro blockCreate esteja setado retorna false
end

function API.getHistory(userSteam)
    if historyCache[userSteam] then
        return historyCache[userSteam] --  caso ja tenha sido consultado retorna o cache
    end

    local history = exports['oxmysql']:query_async("SELECT data FROM bank_history WHERE steam = @steam",{ steam = userSteam }) -- caso ja existam registro no historico seta todos no cache e retorna
    if history and history[1] then
        historyCache[userSteam] = history
        return historyCache[userSteam]
    end

    historyCache[userSteam] = {} -- caso não exista registro no historico seta o cache como vazio e retorna
    return historyCache[userSteam]
    
end

function API.addHistory(userSteam,action,amount)
    local history = API.getHistory(userSteam) -- pega o historico do jogador
    if history then -- checa se o historico existe
        local data = { action = action, amount = amount }

        exports['oxmysql']:query("INSERT INTO bank_history (steam,data) VALUES(@steam,@data)",{steam = userSteam,data = json.encode(data)}) -- insere o registro no banco de dados
        local newIndex = #historyCache[userSteam] + 1
        historyCache[userSteam][newIndex] = {} -- cria um novo registro no cache
        historyCache[userSteam][newIndex].data = json.encode(data) -- insere o registro no cache
        return true
    end
    return false
end


function getPlayerSteam(source) -- retorna a steam do jogador
    local identifiers = GetPlayerIdentifiers(source)
	for k,v in ipairs(identifiers) do
		if string.sub(v,1,5) == "steam" then
			return v
		end
	end
    return false
end

function formatarReal(valor)
    -- Verifica se o valor é numérico
    if type(valor) ~= "number" then
        return "Valor inválido"
    end
    
    -- Formata o número com duas casas decimais, separador de milhar e decimal
    local formatado = string.format("R$ %.2f", valor)
    
    -- Substitui o ponto por vírgula na parte decimal
    formatado = formatado:gsub("%.", ",")
    
    -- Adiciona separadores de milhar
    local parteInteira, parteDecimal = formatado:match("R$ (.*),(.*)")
    if parteInteira then
        parteInteira = parteInteira:reverse():gsub("(%d%d%d)", "%1."):reverse()
        parteInteira = parteInteira:gsub("^%.", "")  -- Remove ponto no início se houver
        formatado = "R$ " .. parteInteira .. "," .. parteDecimal
    end
    
    return formatado
end

local options = {
    ["saldo"] = {
        text = "Verifica o saldo da conta", -- texto explicativo do parametro
        action = function(source,userSteam)
            local account = API.getAccount(userSteam) -- pega a conta do jogador
            if account then -- checa se a conta existe
                TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Seu saldo é '..formatarReal(account.balance)) -- notifica o jogador com o saldo
            end
        end,
    },

    ['depositar'] = {
        text = "Deposita um valor na conta",  -- texto explicativo do parametro
        action = function(source,userSteam,amount)
            local account = API.getAccount(userSteam) -- pega a conta do jogador
            if account then -- checa se a conta existe
                local amount = tonumber(amount)  -- converte o valor para numero
                if not amount or amount <= 0 then -- checa se o valor é valido
                    TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Valor inválido') -- notifica o jogador com erro
                    return
                end

                exports['oxmysql']:query("UPDATE bank_accounts SET balance = balance + @amount WHERE steam = @steam",{amount = amount,steam = userSteam}) -- atualiza o saldo da conta
                accountsCache[userSteam].balance = account.balance + amount -- atualiza o cache
                TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Você depositou '..formatarReal(amount)) -- notifica o jogador com sucesso
                
                API.addHistory(userSteam,"Depositou",amount)
            end
        end,
    },

    ['sacar'] = {
        text = "Saca um valor da conta",  -- texto explicativo do parametro
        action = function(source,userSteam,amount)
            local account = API.getAccount(userSteam) -- pega a conta do jogador
            if account then -- checa se a conta existe
                local amount = tonumber(amount)  -- converte o valor para numero
                if not amount or amount <= 0 then -- checa se o valor é valido
                    TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Valor inválido') -- notifica o jogador com erro
                    return
                end

                if account.balance <= 0 or account.balance < amount then -- checa se o saldo é valido e se o jogador tem saldo suficiente
                    TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Saldo insuficiente') -- notifica o jogador com erro
                    return
                end
                
                exports['oxmysql']:query("UPDATE bank_accounts SET balance = balance - @amount WHERE steam = @steam",{amount = amount,steam = userSteam}) -- atualiza o saldo da conta
                accountsCache[userSteam].balance = account.balance - amount -- atualiza o cache
                TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Você sacou '..formatarReal(amount)) -- notifica o jogador com sucesso

                API.addHistory(userSteam,"Sacou",amount) -- adiciona o registro no historico
            end
        end,
    },

    ['historico'] = {
        text = "Verifica o histórico da conta",  -- texto explicativo do parametro
        action = function(source,userSteam)
            local history = API.getHistory(userSteam) -- pega o historico do jogador
            if history then -- checa se o historico existe
                if #history == 0 then -- checa se o historico esta vazio
                    TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Seu histórico está vazio') -- notifica o jogador com erro
                    return
                end

                local limit = 0
                local msg = 'Suas ultimas 3 ações: \n' -- cria a mensagem
                for i=#history,1,-1 do -- itera sobre o historico de trás para frente
                    if limit >= 3 then break end -- limita aos ultimos 3 registros
                    limit = limit + 1
                    local data = json.decode(history[i].data)
                    msg = msg..data.action..' - '..formatarReal(data.amount)..'\n' -- adiciona o registro na mensagem
                end
                TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,msg) -- notifica o jogador com sucesso
            end
        end,
    },

    ['transferir'] = {
        text = "Transfere um valor para outro jogador",  -- texto explicativo do parametro
        action = function(source,userSteam,amount,targetSteam)
            local account = API.getAccount(userSteam) -- pega a conta do jogador
            if account then -- checa se a conta existe
                local amount = tonumber(amount) -- converte o valor para numero
                if not amount or amount <= 0 then -- checa se o valor é valido
                    TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Valor inválido') -- notifica o jogador com erro
                    return
                end

                if account.balance <= 0 or account.balance < amount then -- checa se o saldo é valido e se o jogador tem saldo suficiente
                    TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Saldo insuficiente') -- notifica o jogador com erro
                    return
                end
                
                
                if not targetSteam then -- checa se o valor foi enviado
                    TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Usuario Invalido') -- notifica o jogador com erro
                    return
                end

                local targetAccount = API.getAccount(targetSteam,true) -- pega a conta do destinatario
                if not targetAccount then -- checa se a conta existe
                    TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Não encontramos a conta do destinatario') -- notifica o jogador com erro
                    return
                end

                exports['oxmysql']:query("UPDATE bank_accounts SET balance = balance - @amount WHERE steam = @steam",{amount = amount,steam = userSteam}) -- atualiza o saldo da conta do jogador
                accountsCache[userSteam].balance = account.balance - amount -- atualiza o cache

                exports['oxmysql']:query("UPDATE bank_accounts SET balance = balance + @amount WHERE steam = @steam",{amount = amount,steam = targetSteam}) -- atualiza o saldo da conta do destinatario
                accountsCache[targetSteam].balance = accountsCache[targetSteam].balance + amount -- atualiza o cache

                TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Você transferiu '..formatarReal(amount)..' para '..targetSteam) -- notifica o jogador com sucesso
                
                API.addHistory(userSteam,"Transferiu",amount) -- adiciona o registro no historico do jogador
            end
            
        end
    }
}

RegisterCommand('banco',function(source,args,rawCommand)
    local userSteam = getPlayerSteam(source) -- pega a steam do jogador
    if userSteam then -- checa se a steam existe
        local option = args[1] -- pega o primeiro argumento do comando
        if options[option] then -- checa se o argumento existe nas opções
            options[option].action(source,userSteam,args[2],args[3]) -- chama a função correspondente ao argumento
        else
            TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,'Opção inválida') -- notifica o jogador com erro
            local msg = 'Opções disponíveis: <br>' -- cria a mensagem
            for title,_ in pairs(options) do -- itera sobre as opções
                msg = msg..title..'<br>' -- adiciona a opção na mensagem
            end
            TriggerClientEvent(GetCurrentResourceName()..":showNotify", source,msg) -- notifica o jogador com as possibilidades
        end
    end
end)

exports('getAPI',function()
    return API
end)