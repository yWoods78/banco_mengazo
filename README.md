# 📄 **Documentação Completa - Sistema Bancário para FiveM**  

**Autor:** yWoods_78 
**Versão:** 1.0.0  
**Status:** Estável ✅  

---

## 🌟 **Visão Geral do Sistema**  
Sistema bancário completo para FiveM com:  
✅ **API modular** para integração com outros recursos  
✅ **Comandos in-game** para operações básicas  
✅ **Sistema de cache** inteligente  
✅ **Histórico de transações**  
✅ **Exportação de funções** para desenvolvedores  

---

## 🛠 **Tecnologias Principais**  
| Tecnologia | Função |  
|------------|--------|  
| **Lua** | Linguagem principal |  
| **oxmysql** | Conexão com banco de dados |  
| **FiveM API** | Eventos e exports |  

---

## 🔧 **Arquitetura do Sistema**  

### 📂 **Estrutura de Dados**  
```lua
local accountsCache = {}  -- Cache de saldos
local historyCache = {}   -- Cache de histórico
local API = {}            -- Interface pública
```

---

## 📌 **Principais Funcionalidades**  

### 1. **Sistema de Comandos**  
| Comando | Parâmetros | Descrição | Exemplo |  
|---------|------------|-----------|---------|  
| `banco saldo` | - | Verifica saldo | `/banco saldo` |  
| `banco depositar` | valor | Deposita dinheiro | `/banco depositar 500` |  
| `banco sacar` | valor | Saca dinheiro | `/banco sacar 300` |  
| `banco historico` | - | Mostra últimas transações | `/banco historico` |  
| `banco transferir` | valor steamID | Transfere para jogador | `/banco transferir 200 steam:110000112345678` |  

### 2. **API Pública**  
```lua
-- Acesse a API em outros recursos:
local banking = exports['banking-system']:getAPI()

-- Métodos disponíveis:
banking.getAccount(steamID)          → Retorna {balance = number}  
banking.getHistory(steamID)          → Retorna array de transações  
banking.addHistory(steamID, ação, valor) → Adiciona registro  
```

---

## 🧠 **Detalhes Técnicos Avançados**  

### 1. **Sistema de Cache**  
- **Funcionamento:**  
  ```lua
  function API.getAccount(userSteam)
      if accountsCache[userSteam] then
          return accountsCache[userSteam]  -- Retorna do cache
      end
      -- Consulta banco de dados se não encontrado
  end
  ```
- **Atualização Automática:**  
  - Cache é atualizado em todas as operações de escrita  

### 2. **Segurança**  
- **Validações:**  
  - Checagem de SteamID válido  
  - Verificação de saldo antes de saques/transferências  
  - Validação de valores numéricos positivos  

### 3. **Banco de Dados**  
- **Estrutura:**  
  ```sql
  CREATE TABLE bank_accounts (
      steam VARCHAR(255) PRIMARY KEY,
      balance DECIMAL(10,2) DEFAULT 0
  );
  
  CREATE TABLE bank_history (
      id INT AUTO_INCREMENT PRIMARY KEY,
      steam VARCHAR(255),
      data TEXT,
      FOREIGN KEY (steam) REFERENCES bank_accounts(steam)
  );
  ```

---

## 🧪 **Guia de Testes**  

### 1. **Testando Comandos**  
```bash
# No chat do jogo:
/banco saldo
/banco depositar 1000
/banco transferir 500 steam:110000112345678
```

### 2. **Testando a API**  
```lua
-- Em outro recurso:
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'meu-recurso' then
        local bank = exports['banking-system']:getAPI()
        print(bank.getAccount("steam:11000013e1e5192"))
    end
end)
```

### 3. **Simulando Falhas**  
- Tentar sacar valor maior que o saldo  
- Usar SteamID inválido em transferências  
- Testar com valores não numéricos  


---

## 📜 **Políticas de Uso**  
1. Modificações devem manter os créditos originais  
2. Requer oxmysql configurado corretamente  
