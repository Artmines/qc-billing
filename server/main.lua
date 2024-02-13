RSGCore = exports['rsg-core']:GetCoreObject()

-- Functions --

local function comma_value(amount)
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end

function isAllowedToBill(player)
    local playerJob = player.PlayerData.job
    for k, v in pairs(Config.PermittedJobs) do
        if v == playerJob.name then
            if not playerJob.onduty and Config.OnDutyToBillEnabled then
                return false
            end
            return true
        end
    end
    return false
end

function getPendingBilled(source, cb)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if player then
        MySQL.query('SELECT * FROM bills WHERE sender_citizenid = ? AND status = ?', {
            player.PlayerData.citizenid,
            'Unpaid'
        }, function(result)
            cb(result)
        end)
    else
        cb(nil)
    end
end

function getPaidBilled(source, cb)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if player then
        MySQL.query('SELECT * FROM bills WHERE sender_citizenid = ? AND status = ?', {
            player.PlayerData.citizenid,
            'Paid'
        }, function(result)
            cb(result)
        end)
    else
        cb(nil)
    end
end

function getBillsToPay(source, cb)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if player then
        MySQL.query('SELECT * FROM bills WHERE recipient_citizenid = ? AND status = ?', {
            player.PlayerData.citizenid,
            'Unpaid'
        }, function(result)
            if result and #result > 0 then
                cb(result)
            else
                cb(nil)
            end
        end)
    else
        cb(nil)
    end
end

function getPaidBills(source, cb)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if player then
        MySQL.query('SELECT * FROM bills WHERE sender_citizenid = ? AND status = ?', {
            player.PlayerData.citizenid,
            'Paid'
        }, function(result)
            if result and #result > 0 then
                cb(result)
            else
                cb(nil)
            end
        end)
    else
        cb(nil)
    end
end

-- Events --

RSGCore.Functions.GetPlayerByCitizenId = function(citizenId, cb)
    local players = RSGCore.Functions.GetPlayers()
    for _, playerId in pairs(players) do
        local player = RSGCore.Functions.GetPlayer(playerId)
        if player.PlayerData.citizenid == citizenId then
            cb(player) 
            return
        end
    end
    cb(nil) 
end

RSGCore.Functions.CreateCallback('qc-billing:server:getPlayerFromCitizenId', function(source, cb, citizenId)
    RSGCore.Functions.GetPlayerByCitizenId(citizenId, function(player)
        if player then
            cb(player)
        else
            cb(nil)
        end
    end)
end)

RegisterNetEvent('qc-billing:server:sendBill')
AddEventHandler('qc-billing:server:sendBill', function(data)
    local src = source
    local sender = RSGCore.Functions.GetPlayer(src)
    local billAmount = data.billAmount
    local recipientCitizenId = data.recipientCitizenId 
    local senderFullName = (sender.PlayerData.charinfo.firstname .. ' ' .. sender.PlayerData.charinfo.lastname)
    local senderAccount = sender.PlayerData.job.name
    if isAllowedToBill(sender) then
        RSGCore.Functions.GetPlayerByCitizenId(recipientCitizenId, function(recipient)
            if recipient then
                local recipientFullName = (recipient.PlayerData.charinfo.firstname .. ' ' .. recipient.PlayerData.charinfo.lastname)
                local datetime = os.date('%Y-%m-%d %H:%M:%S')
                local sql = 'INSERT INTO bills (bill_date, amount, sender_account, sender_name, sender_citizenid, recipient_name, recipient_citizenid, status, status_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
                MySQL.insert(sql, {
                    datetime,
                    billAmount,
                    senderAccount,
                    senderFullName,
                    sender.PlayerData.citizenid,
                    recipientFullName,
                    recipientCitizenId, 
                    'Unpaid',
                    datetime
                }, function(result)
                    if result > 0 then
                        local message = 'Bill sent to ' .. recipientFullName .. ' for the amount of $' .. billAmount
                        TriggerClientEvent('RSGCore:Notify', src, message, 'success')
                    else
                        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.sending_bill'), 'error')
                    end
                end)
            else
                TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.recipient_not_found'), 'error')
            end
        end)
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.not_permitted'), 'error')
    end
    TriggerClientEvent('qc-billing:client:engageChooseBillViewMenu', src)
end)

RegisterNetEvent('qc-billing:server:getPendingBilled')
AddEventHandler('qc-billing:server:getPendingBilled', function()
    local src = source
    getPendingBilled(src, function(bills)
        if bills and bills[1] then
            TriggerClientEvent('qc-billing:client:openPendingBilledMenu', src, bills)
        else
            TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.retrieving_bills'), 'error')
        end
    end)
end)

RegisterNetEvent('qc-billing:server:getPaidBilled')
AddEventHandler('qc-billing:server:getPaidBilled', function()
    local src = source
    getPaidBilled(src, function(bills)
        if bills and bills[1] then
            TriggerClientEvent('qc-billing:client:openPaidBilledMenu', src, bills)
        else
            TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.retrieving_bills'), 'error')
        end
    end)
end)

RegisterNetEvent('qc-billing:server:getBillsToPay')
AddEventHandler('qc-billing:server:getBillsToPay', function()
    local src = source
    getBillsToPay(src, function(bills)
        if bills and bills[1] then
            TriggerClientEvent('qc-billing:client:openBillsToPayMenu', src, bills)
        else
            TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.retrieving_bills'), 'error')
        end
    end)
end)

RegisterNetEvent('qc-billing:server:getPaidBills')
AddEventHandler('qc-billing:server:getPaidBills', function()
    local src = source
    getPaidBills(src, function(bills)
        if bills and bills[1] then
            TriggerClientEvent('qc-billing:client:openPaidBillsMenu', src, bills)
        else
            --TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.retrieving_bills'), 'error')          IDK WHY THIS TRIGGERS
        end
    end)
end)

RegisterNetEvent('qc-billing:server:payBill')
AddEventHandler('qc-billing:server:payBill', function(data)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    local bill = data.bill
    --print('qc-billing:server:payBill event triggered with bill ID:', bill.id)
    if player.Functions.GetMoney('bank') >= bill.amount then
        player.Functions.RemoveMoney('bank', bill.amount, Lang:t('other.bill_pay_desc'))
        local datetime = os.date('%Y-%m-%d %H:%M:%S')
        RSGCore.Functions.GetPlayerByCitizenId(bill.sender_citizenid, function(sender)
            if sender then
                TriggerEvent('qc-billing:server:notifyBillStatusChange', sender.PlayerData.source, Lang:t('info.bill_paid_sender', { billId = bill.id, amount = comma_value(bill.amount), recipient = bill.recipient_name }), 'success', Lang:t('other.sent_bill_paid_text_subject'), Lang:t('info.bill_paid_sender_text', { billId = bill.id, amount = comma_value(bill.amount), recipient = bill.recipient_name }))
            end
            TriggerEvent('qc-billing:server:notifyBillStatusChange', src, Lang:t('success.bill_paid_recipient', { billId = bill.id, amount = comma_value(bill.amount), senderName = bill.sender_name, account = bill.sender_account }), 'success', Lang:t('other.received_bill_paid_text_subject'), Lang:t('success.bill_paid_recipient_text', { billId = bill.id, amount = comma_value(bill.amount), senderName = bill.sender_name, account = bill.sender_account }))
        end)
        MySQL.update('UPDATE bills SET status = ?, status_date = ? WHERE id = ? AND bill_date = ? AND amount = ? AND sender_account = ? AND recipient_citizenid = ? AND status = ?', {
            'Paid',
            datetime,
            bill.id,
            bill.bill_date,
            bill.amount,
            bill.sender_account,
            bill.recipient_citizenid,
            'Unpaid'
        }, function(affectedRows)
            --print('Update query affected rows:', affectedRows)
        end)
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.not_enough_money'), 'error')
    end
    TriggerClientEvent('qc-billing:client:getBillsToPay', src)
end)

RegisterNetEvent('qc-billing:server:deleteBill')
AddEventHandler('qc-billing:server:deleteBill', function(data)
    local src = source
    local bill = data.bill
    RSGCore.Functions.TriggerCallback('qc-billing:server:getPlayerFromCitizenId', src, function(recipient)
        if recipient then
            TriggerEvent('qc-billing:server:notifyBillStatusChange', recipient.PlayerData.source, Lang:t('info.bill_canceled_recipient', { billId = bill.id, amount = comma_value(bill.amount), senderName = bill.sender_name, account = bill.sender_account }), 'success', Lang:t('other.received_bill_canceled_text_subject'), Lang:t('info.bill_canceled_recipient_text', { billId = bill.id, amount = comma_value(bill.amount), senderName = bill.sender_name, account = bill.sender_account }))
        end
        MySQL.query('DELETE FROM bills WHERE id = ? AND bill_date = ? AND amount = ? AND sender_account = ? AND recipient_citizenid = ? AND status = ?', {
            bill.id,
            bill.bill_date,
            bill.amount,
            bill.sender_account,
            bill.recipient_citizenid,
            bill.status
        }, function(affectedRows)
        end)
        TriggerEvent('qc-billing:server:notifyBillStatusChange', src, Lang:t('success.bill_canceled_sender', { billId = bill.id, amount = comma_value(bill.amount), recipient = bill.recipient_name }), 'success', Lang:t('other.sent_bill_canceled_text_subject'), Lang:t('success.bill_canceled_sender_text', { billId = bill.id, amount = comma_value(bill.amount), recipient = bill.recipient_name }))
        TriggerClientEvent('qc-billing:client:getPendingBilled', src)
    end, bill.recipient_citizenid)
end)

RegisterNetEvent('qc-billing:server:notifyBillStatusChange')
AddEventHandler('qc-billing:server:notifyBillStatusChange', function(recipient, notificationMessage, notificationMessageType, textSubject, textMessage)
    if Config.EnablePopupNotification then
        TriggerClientEvent('RSGCore:Notify', recipient, notificationMessage, notificationMessageType)
    end
    if Config.EnableTextNotifications then
        TriggerClientEvent('qc-billing:client:sendText', recipient, textSubject, textMessage)
    end
end)

-- Callbacks --

RSGCore.Functions.CreateCallback('qc-billing:server:canSendBill', function(source, cb)
    local src = source
    local player = RSGCore.Functions.GetPlayer(src)
    if isAllowedToBill(player) then
        cb(true)
    end
    cb(false)
end)

RSGCore.Functions.CreateCallback('qc-billing:server:hasBillsToPay', function(source, cb)
    local src = source
    local result = getBillsToPay(src)
    if result and result[1] then
        cb(true)
    else
        cb(false)
    end
end)

RSGCore.Functions.CreateCallback('qc-billing:server:getPlayerFromId', function(source, cb, playerId)
    local player = RSGCore.Functions.GetPlayer(tonumber(playerId))
    if player then
        cb(player.PlayerData.citizenid) 
    else
        cb(nil) 
    end
end)