ABCache_Storage = {};

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

local _UnitDebuff, _UnitBuff = UnitDebuff, UnitBuff;

AuraBuffsCacheFrame = CreateFrame("Frame", nil, UIParent);

-- Check value in storage
AuraBuffsCacheFrame.GetStorageValue = function(name, id)
  if (not name or not id) then
    return nil;
  end

  return ABCache_Storage[name] and ABCache_Storage[name][id];
end

-- Create value in storage
AuraBuffsCacheFrame.CreateStorageValue = function(name, id, debuffType, rank)
  if (not name or not id) then
    return;
  end

  if (not ABCache_Storage[name]) then
    ABCache_Storage[name] = {};
  end

  ABCache_Storage[name][id] = {
    debuffType = debuffType,
    rank = rank,
  };
  return ABCache_Storage[name][id];
end

---Original UnitBuff function
AuraBuffsCacheFrame._UnitBuff = _UnitBuff;

---Original UnitDebuff function
AuraBuffsCacheFrame._UnitDebuff = _UnitDebuff;

local _buffLimit = 64;
local _debuffLimit = 16;

AuraBuffsCacheFrame.UnitBuff = function (unit, index, filter)
  local name, count, icon, rank, debuffType, duration, expirationTime = _UnitBuff(unit, index, filter);

  -- Bad data or it's debuff signature
  if (
    not name or
    AuraBuffsCacheFrame.GetStorageValue(name, icon)
  ) then
    return nil, nil, nil, nil, nil, nil, nil;
  end

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
  local cachedValue = nil
  
  local name, count, icon, rank, debuffType, duration, expirationTime = nil, nil, nil, nil, nil, nil, nil;
  
  for i=1,_buffLimit do 
    name, count, icon, rank, debuffType, duration, expirationTime = _UnitBuff(unit, i);

    if (not name) then
      break;
    end

    cachedValue = AuraBuffsCacheFrame.GetStorageValue(name, icon);
    -- it's actually debuff
    if (cachedValue) then
      countDebuffInBuff = countDebuffInBuff + 1;
      if (countDebuffInBuff == indexDebuff) then
        indexDebuffInBuff = i;
        break;
      end
    end
  end

  -- find debuff
  if (indexDebuffInBuff > 0) then
    
    debuffType = debuffType or cachedValue.debuffType;
    rank = rank or cachedValue.rank;

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

  local name, count, debuffType, icon, rank, duration, expirationTime = _UnitDebuff(unit, index, filter);
  if (not name) then
    return nil, nil, nil, nil, nil, nil, nil;
  end

  -- check cache for add new debuff
  if (not AuraBuffsCacheFrame.GetStorageValue(name, icon)) then
    AuraBuffsCacheFrame.CreateStorageValue(name, icon, debuffType, rank);
  end
  
  return name, count, debuffType, icon, rank, duration, expirationTime;
end
UnitDebuff = AuraBuffsCacheFrame.UnitDebuff;