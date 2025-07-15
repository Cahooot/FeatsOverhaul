Ext.Vars.RegisterModVariable(ModuleUUID, "WeaponPropertyTracker", {})

-- Apply any changes to weapon properties (i.e. Versatile being removed) on session load, as changes to weapon properties would otherwise by overwritten by the weapon's stats entry
local function InitializeWeaponProperties()
    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
        for uuid, property in pairs(ModVars) do
            entity = Ext.Entity.Get(uuid)
            entity.Weapon.WeaponProperties = property
        end
    _D(ModVars)
end

Ext.Events.SessionLoaded:Subscribe(InitializeWeaponProperties)

-- Remove Versatile property from weapon
local function RemoveVersatile(weapon)
    -- Returns as bit flags (decimal)
    local WeaponProperties = weapon.Weapon.WeaponProperties
    local WeaponPropertiesNew = {}

    -- Remove Versatile property (=2048 in decimal form under WeaponFlags)
    WeaponPropertiesNew = WeaponProperties & ~2048
    weapon.Weapon.WeaponProperties = WeaponPropertiesNew

    -- Stores the new properties to the weapon entity in the mod variable
    EntityUUID = weapon.Uuid["EntityUuid"]

    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    ModVars[EntityUUID] = WeaponPropertiesNew
    Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker = ModVars

    -- Replicate the Weapon component after changing properties
    weapon:Replicate("Weapon")
end

-- Restore Versatile property to weapon
local function RestoreVersatile(weapon)
    -- Returns as bit flags (decimal)
    local WeaponProperties = weapon.Weapon.WeaponProperties
    local WeaponPropertiesNew = {}

    -- Add Versatile property (=2048 in decimal form under WeaponFlags)
    WeaponPropertiesNew = WeaponProperties + 2048
    weapon.Weapon.WeaponProperties = WeaponPropertiesNew

    -- Remove the weapon's entry in the mod variables table
    EntityUUID = weapon.Uuid["EntityUuid"]

    local ModVars = Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker or {}
    for uuid, _ in pairs(ModVars) do
        function table.removekey(table, key)
            local element = table[key]
            table[key] = nil
            return element
        end

        if uuid == EntityUUID then
            table.removekey(ModVars, uuid)
            Ext.Vars.GetModVariables(ModuleUUID).WeaponPropertyTracker = ModVars
        end
    end

    -- Replicate the Weapon component after changing properties
    weapon:Replicate("Weapon")
end

-- Listening for the remove Versatile status being applied to the weapon
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(weapon, status, _, _)
    local WeaponEntity = Ext.Entity.Get(weapon)
    if status == "CHT_DUELIST_REMOVED_VERSATILE" then
        RemoveVersatile(WeaponEntity)
    end
end)

-- Listening for the remove Versatile status being removed from the weapon (not listening for the restore Versatile helper status being applied, to also catch long rests which remove the main status but don't apply that helper status)
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(weapon, status, _, _)
    local WeaponEntity = Ext.Entity.Get(weapon)
    if status == "CHT_DUELIST_REMOVED_VERSATILE" then
        RestoreVersatile(WeaponEntity)
    end
end)



-- Ext_Enums.WeaponFlags = {
--     Light = 1,
--     Ammunition = 2,
--     Finesse = 4,
--     Heavy = 8,
--     Loading = 16,
--     Range = 32,
--     Reach = 64,
--     Lance = 128,
--     Net = 256,
--     Thrown = 512,
--     Twohanded = 1024,
--     Versatile = 2048,
--     Melee = 4096,
--     Dippable = 8192,
--     Torch = 16384,
--     NoDualWield = 32768,
--     Magical = 65536,
--     NeedDualWieldingBoost = 131072,
--     NotSheathable = 262144,
--     Unstowable = 524288,
--     AddToHotbar = 1048576,
-- }
