# API — couche `rp_*`

## rp_core

```lua
exports.rp_core:Notify(source|nil, message, type?, duration?)
exports.rp_core:AddMoney(source, 'cash'|'bank', amount, reason?)
exports.rp_core:RemoveMoney(source, 'cash'|'bank', amount, reason?)
exports.rp_core:GetMoney(source, 'cash'|'bank')
exports.rp_core:AddSocietyMoney(account, amount, reason?)
exports.rp_core:RemoveSocietyMoney(account, amount)
exports.rp_core:AddItem(source, item, count?, metadata?)
exports.rp_core:RemoveItem(source, item, count?, metadata?)
exports.rp_core:GetPlayer(source)
exports.rp_core:HasAce(source, ace)
exports.rp_core:HasJob(source, job, minGrade?, requireDuty?)
exports.rp_core:RateLimit(source, key, cooldownMs)
```

### Events

- `rp_core:server:playerLoaded (source, data)`
- `rp_core:server:playerUnloaded (source)`
- `rp_core:server:jobUpdate (source, job)`
- `rp_core:server:moneyUpdate (source, moneyType, amount, action, reason)`

## rp_billing

```lua
exports.rp_billing:CreateInvoice(fromSource, toSource, amount, reason, society?)
exports.rp_billing:PayInvoice(source, invoiceId)
exports.rp_billing:RefuseInvoice(source, invoiceId)
```

## rp_licenses

```lua
exports.rp_licenses:HasLicense(source, type)
exports.rp_licenses:GrantLicense(target, type, issuer?)
exports.rp_licenses:RevokeLicense(target, type, issuer?)
exports.rp_licenses:GetLicenses(source)
```

Types : `driver`, `motorcycle`, `truck`, `boat`, `aircraft`, `weapon`

## rp_business

```lua
exports.rp_business:GetBusiness(name)
exports.rp_business:AddBusinessMoney(name, amount)
exports.rp_business:RemoveBusinessMoney(name, amount)
exports.rp_business:GetBusinessBalance(name)
exports.rp_business:LogBusinessTransaction(name, amount, citizenid, type, reason)
```

## rp_logs

```lua
exports.rp_logs:Log(category, source?, message, meta?)
```

## rp_phone_bridge

```lua
exports.rp_phone_bridge:NotifyPhone(source, title, message, app?)
```
