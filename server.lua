ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)


RegisterNetEvent('sqz_hospital:PayForHeal')
AddEventHandler('sqz_hospital:PayForHeal', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer.getMoney() >= Config.Price then
        xPlayer.removeMoney(Config.Price)
        xPlayer.showNotification(_U('has_paid', Config.Price))
        TriggerClientEvent('sqz_hospital:HasEnoughMoney', _source)

        if Config.Society then
            TriggerEvent('esx_addonaccount:getSharedAccount', Config.Society, function(account)
                account.addMoney(Config.Price)
            end)
        end
    elseif xPlayer.getAccount('bank').money >= Config.Price then
        xPlayer.removeAccountMoney('bank', Config.Price)
        xPlayer.showNotification(_U('has_paid', Config.Price))
        TriggerClientEvent('sqz_hospital:HasEnoughMoney', _source)

        if Config.Society then
            TriggerEvent('esx_addonaccount:getSharedAccount', Config.Society, function(account)
                account.addMoney(Config.Price)
            end)
        end
    else
        xPlayer.showNotification(_U('no_money'))
    end
end)

RegisterNetEvent('sqz_hospital:IamCheating')
AddEventHandler('sqz_hospital:IamCheating', function()
    local _source = source

    DropPlayer(_source, _U('drop_reason'))

end)