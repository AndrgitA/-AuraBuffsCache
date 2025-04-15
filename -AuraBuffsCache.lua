ABCache_Table = {};
---Локальная функция принта
---@param ... unknown
---@return void
local function Print(...)
  if arg.n == 0 then
    return
  end

  local result = tostring(arg[1]) 
  for i = 2, arg.n do
    result = result.." "..tostring(arg[i])
  end

  DEFAULT_CHAT_FRAME:AddMessage(result, .5, 1, .3)
end

AuraBuffsCacheFrame = CreateFrame("Frame", nil, UIParent);

---Генерирует ключ для таблицы по входным данным
---@param icon string
---@param spellID number
---@return string
AuraBuffsCacheFrame.CreateCacheName = function (icon, spellID)
  return icon.."__"..spellID;
end

---Original UnitBuff function
AuraBuffsCacheFrame._UnitBuff = UnitBuff;

---Original UnitDebuff function
AuraBuffsCacheFrame._UnitDebuff = UnitDebuff;

local _buffLimit = 64;
local _debuffLimit = 16;

---Добавляет новые данные в таблицу
---@param key string
---@param value {name: string, icon: number, debuffType: string }
---@return void
local function addDebuffToCache(key, value)
  ABCache_Table[key] = value;
end 


AuraBuffsCacheFrame.UnitBuff = function (unit, index, filter)
  -- print("UnitBuff:: unit: "..tostring(unit)..";index: "..tostring(index)..";filter: ", tostring(filter))
  local name, count, icon, rank, debuffType, duration, expirationTime = AuraBuffsCacheFrame._UnitBuff(unit, index, filter);

  if (not name) then
    return nil, nil, nil, nil, nil, nil, nil;
  end

  local key = AuraBuffsCacheFrame.CreateCacheName(name, icon);
  -- It's cached debuffs
  if (ABCache_Table[key]) then
    return nil, nil, nil, nil, nil, nil, nil;
  end

  -- Print("BUFF:: unit: "..unit..";name: "..name..";rank: ", rank, ";icon: ", icon, ";count: ", count, ";debuffType: ", debuffType, ";duration: ", duration)
  return name, count, icon, rank, debuffType, duration, expirationTime;
end
UnitBuff = AuraBuffsCacheFrame.UnitBuff;

---Получение данных о дебаффе из списка баффов
---@param unit  string
---@param index number
---@param filter string
---@return string name, number count, string debuffType, string icon, number rank, number duration, number expirationTime;
AuraBuffsCacheFrame.getDebuffInBuffs = function (unit, index, filter)
  local indexDebuff = index - _debuffLimit;
  local countDebuffInBuff = 0;
  
  local indexDebuffInBuff = 0;
  local buffKey = nil
  
  
  for i=1,_buffLimit do 
    local name, _, icon = AuraBuffsCacheFrame._UnitBuff(unit, i);

    if (not name) then
      break;
    end

    buffKey = AuraBuffsCacheFrame.CreateCacheName(name, icon);
    if (ABCache_Table[buffKey]) then
      countDebuffInBuff = countDebuffInBuff + 1;
      if (countDebuffInBuff == indexDebuff) then
        indexDebuffInBuff = i;
        break;
      end
    end
  end

  -- Я нашел нужный мне дебафф в баффах.
  if (indexDebuffInBuff > 0) then
    local name, count, icon, rank, debuffType, duration, expirationTime = AuraBuffsCacheFrame._UnitBuff(unit, indexDebuffInBuff);
    local cachedValue = ABCache_Table[buffKey];
    
    debuffType = debuffType or cachedValue.debuffType;
    rank = rank or cachedValue.rank;

    local newKey = buffKey.."_inBuff";
    if (not ABCache_Table[newKey]) then
      addDebuffToCache(newKey, {
        name = name,
        -- count = count,
        debuffType = debuffType,
        icon = icon,
        rank = rank,
        -- duration = duration,
        -- expirationTime = expirationTime
      });
    end
    return name, count, debuffType, icon, rank, duration, expirationTime;
  end
  
  return nil, nil, nil, nil, nil, nil, nil;
end

AuraBuffsCacheFrame.UnitDebuff = function (unit, index, filter)
  -- fixed limit client vanilla to check UnitBuff
  -- if index > 16 (hard value in this clown client ^*^)
  if (index > _debuffLimit) then
    return AuraBuffsCacheFrame.getDebuffInBuffs(unit, index, filter);
  end

  local name, count, debuffType, icon, rank, duration, expirationTime = AuraBuffsCacheFrame._UnitDebuff(unit, index, filter);
  if (not name) then
    return nil, nil, nil, nil, nil, nil, nil;
  end
  -- Print("DEBUFF:: unit: "..unit..";name: "..name..";rank: ", rank, ";icon: ", icon, ";count: ", count, ";debuffType: ", debuffType, ";duration: ", duration)
  local key = AuraBuffsCacheFrame.CreateCacheName(name, icon);
  -- check cache for add new debuff
  if (not ABCache_Table[key]) then
    addDebuffToCache(key, {
      name = name,
      -- count = count,
      debuffType = debuffType,
      icon = icon,
      rank = rank,
      -- duration = duration,
      -- expirationTime = expirationTime
    });
  end
  
  return name, count, debuffType, icon, rank, duration, expirationTime;
end
UnitDebuff = AuraBuffsCacheFrame.UnitDebuff;