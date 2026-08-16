ServerConfig = ServerConfig or {}

--- Optional ACE principals to grant via server.cfg documentation only.
--- Example: add_ace group.admin qbx_shopcreator.admin allow

ServerConfig.AutoMigrate = true

--- When true, shop balance is stored only in shopcreator_shops.balance
--- (no external banking dependency required).
ServerConfig.UseInternalBalance = true