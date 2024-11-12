local RSGCore = exports['rsg-core']:GetCoreObject()

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

local function engageConfirmBillMenu(billAmount, recipient)
    local recCharInfo = recipient.PlayerData.charinfo
    local recCitizenId = recipient.PlayerData.citizenid 
    if Config.Menu == 'ox_lib' then
    lib.registerContext({
        id = 'billing_menu',
        title = Lang:t('menu.confirm_send'),
        options = {
            {
                title = Lang:t('menu.amount_billed_to', { amount = billAmount, firstName = recCharInfo.firstname, lastName = recCharInfo.lastname }),
            },
            {
                title = Lang:t('menu.no_changed_mind'),
                icon = 'fa-solid fa-money-bill',
                event = 'qc-billing:client:engageChooseBillViewMenu',
                arrow = true
            },
            {
                title = Lang:t('menu.send_bill_for_account', { account = RSGCore.Functions.GetPlayerData().job.name }),
                icon = 'fa-solid fa-money-bill',
                event = 'qc-billing:server:sendBill',
                arrow = true
            }
        }
    })
elseif Config.Menu == 'rsg-menu' then
    local menu = {
        {
            header = Lang:t('menu.confirm_send'),
            isMenuHeader = true,
            txt = Lang:t('menu.amount_billed_to', { amount = billAmount, firstName = recCharInfo.firstname, lastName = recCharInfo.lastname })
        },
        {
            header = Lang:t('menu.no_changed_mind'),
            params = {
                event = 'qc-billing:client:engageChooseBillViewMenu'
            }
        },
        {
            header = Lang:t('menu.send_bill_for_account', { account = RSGCore.Functions.GetPlayerData().job.name }),
            params = {
                isServer = true,
                event = 'qc-billing:server:sendBill',
                args = {
                    billAmount = billAmount,
                    recipientCitizenId = recCitizenId 
                }
            }
        },
    }
    exports['rsg-menu']:openMenu(menu)
    end
end

local function engageSendBillMenu()
    local senderData = RSGCore.Functions.GetPlayerData()
    if Config.Menu == 'ox_lib' then
        local options = {
            {
                title = Lang:t('menu.account_name', { account = senderData.job.name }),
                icon = 'fa-solid fa-briefcase'
            },
            {
                title = Lang:t('menu.send_a_bill_id_bullet'),
                icon = 'fa-solid fa-money-bill',
                event = 'qc-billing:client:createBill',
                arrow = true,
                args = {
                    billingClosestPlayer = false
                }
            }
        }
        if Config.AllowNearbyBilling then
            table.insert(options, {
                title = Lang:t('menu.send_a_bill_closest_bullet'),
                icon = 'fa-solid fa-users',
                event = 'qc-billing:client:createBill',
                arrow = true,
                args = {
                    billingClosestPlayer = true
                }
            })
        end
        table.insert(options, {
            title = Lang:t('menu.return_bullet'),
            icon = 'fa-solid fa-arrow-left',
            event = 'qc-billing:client:engageChooseBillViewMenu',
            arrow = true
        })
        table.insert(options, {
            title = Lang:t('menu.cancel_bullet'),
            icon = 'fa-solid fa-times',
            arrow = true
        })
        lib.registerContext({
            id = 'send_bill_menu',
            title = Lang:t('menu.ask_send'),
            options = options
        })
        lib.showContext('send_bill_menu')       
    elseif Config.Menu == 'rsg-menu' then
        local menu = {
            {
                header = Lang:t('menu.ask_send'),
                isMenuHeader = true,
                txt = Lang:t('menu.account_name', { account = senderData.job.name })
            },
            {
                header = Lang:t('menu.send_a_bill_id_bullet'),
                params = {
                    event = 'qc-billing:client:createBill',
                    args = {
                        billingClosestPlayer = false
                    }
                }
            }
        }
        if Config.AllowNearbyBilling then
            menu[#menu + 1] = {
                header = Lang:t('menu.send_a_bill_closest_bullet'),
                params = {
                    event = 'qc-billing:client:createBill',
                    args = {
                        billingClosestPlayer = true
                    }
                }
            }
        end
        menu[#menu + 1] = {
            header = Lang:t('menu.return_bullet'),
            params = {
                event = 'qc-billing:client:engageChooseBillViewMenu'
            }
        }
        menu[#menu + 1] = {
            header = Lang:t('menu.cancel_bullet'),
            params = {
                event = exports['rsg-menu']:closeMenu()
            }
        }
        exports['rsg-menu']:openMenu(menu)
    end
end


local function getClosestPlayer()
    local closestPlayers = RSGCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayerCitizenId = nil 
    local coords = GetEntityCoords(PlayerPedId())
    for i = 1, #closestPlayers, 1 do
        local player = RSGCore.Functions.GetPlayer(closestPlayers[i])
        if player and player.PlayerData.citizenid and closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayerCitizenId = player.PlayerData.citizenid 
                closestDistance = distance
            end
        end
    end
    return closestPlayerCitizenId, closestDistance
end

-- Commands --

RegisterCommand(Config.BillingCommand, function()
    TriggerEvent('qc-billing:client:engageChooseBillViewMenu')
end)

-- Events --

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    TriggerEvent('qc-billing:client:RequestCommands')
end)

RegisterNetEvent('qc-billing:client:RequestCommands', function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.BillingCommand, Lang:t('other.chat_desc'))
end)

RegisterNetEvent('qc-billing:client:canSendBill', function()
    RSGCore.Functions.TriggerCallback('qc-billing:server:canSendBill', function(canSendBill)
        if canSendBill then
            engageSendBillMenu()
        else
            lib.notify({
                title = Lang:t('error.must_be_on_duty'),
                description = '',
                type = 'error'
            })
        end
    end)
end)

RegisterNetEvent('qc-billing:client:notifyOfPaidBill', function()
    lib.notify({
        title = Lang:t('error.already_paid'),
        description = '',
        type = 'error'
    })
    TriggerServerEvent('qc-billing:server:getPaidBills')
end)

RegisterNetEvent('qc-billing:client:notifyOfPaidBilled', function()
    lib.notify({
        title = Lang:t('error.already_paid'),
        description = '',
        type = 'error'
    })
    TriggerServerEvent('qc-billing:server:getPaidBilled')
end)

RegisterNetEvent('qc-billing:client:createBill', function(data)
    local recipientCitizenId
    local billAmount
    local billingClosestPlayer = data.billingClosestPlayer
    if billingClosestPlayer then
        local closestPlayerCitizenId, distance = getClosestPlayer()
        if closestPlayerCitizenId and distance < 4 then
            recipientCitizenId = closestPlayerCitizenId
            if Config.Menu == 'ox_lib' then
                local input = lib.inputDialog(Lang:t('menu.new_bill'), {
                    {
                        type = 'number',
                        label = Lang:t('menu.amount'),
                        required = true
                    }
                })
                if not input or not input[1] then
                    return
                end
                billAmount = tonumber(input[1])
            elseif Config.Menu == 'rsg-menu' then
                local input = exports['rsg-input']:ShowInput({
                    header = Lang:t('menu.new_bill'),
                    submitText = Lang:t('menu.confirm'),
                    inputs = {
                        {
                            text = Lang:t('menu.amount'),
                            name = 'amount',
                            type = 'number',
                            isRequired = true
                        }
                    }
                })
                if not input then
                    return
                end
                billAmount = tonumber(input.amount)
            end
            if not billAmount or billAmount <= 0 then
                lib.notify({
                    title = Lang:t('error.getting_amount'),
                    description = '',
                    type = 'error'
                })
                return
            end
            RSGCore.Functions.TriggerCallback('qc-billing:server:getPlayerFromCitizenId', function(validRecipient)
                if validRecipient then
                    engageConfirmBillMenu(billAmount, validRecipient)
                else
                    lib.notify({
                        title = Lang:t('error.getting_player'),
                        description = 'Notification description',
                        type = 'error'
                    })
                    engageSendBillMenu()
                end
            end, recipientCitizenId)
        else
            lib.notify({
                title = Lang:t('error.no_nearby'),
                description = '',
                type = 'error'
            })
            return
        end
    else
        if Config.Menu == 'ox_lib' then
            local input = lib.inputDialog(Lang:t('menu.new_bill'), {
                {
                    type = 'text',
                    label = Lang:t('menu.recipient_citizenid'),
                    required = true
                },
                {
                    type = 'number',
                    label = Lang:t('menu.amount'),
                    required = true
                }
            })
            if not input or not input[1] or not input[2] then
                return
            end
            recipientCitizenId = input[1]
            billAmount = tonumber(input[2])
        elseif Config.Menu == 'rsg-menu' then
            local input = exports['rsg-input']:ShowInput({
                header = Lang:t('menu.new_bill'),
                submitText = Lang:t('menu.confirm'),
                inputs = {
                    {
                        text = Lang:t('menu.recipient_citizenid'),
                        name = 'citizenid',
                        type = 'text',
                        isRequired = true
                    },
                    {
                        text = Lang:t('menu.amount'),
                        name = 'amount',
                        type = 'number',
                        isRequired = true
                    }
                }
            })
            if not input then
                return
            end
            recipientCitizenId = input.citizenid
            billAmount = tonumber(input.amount)
        end
        if not recipientCitizenId or recipientCitizenId == '' then
            lib.notify({
                title = Lang:t('error.getting_citizenid'),
                description = 'Notification description',
                type = 'error'
            })
            return
        end
        if not billAmount or billAmount <= 0 then
            lib.notify({
                title = Lang:t('error.getting_amount'),
                description = 'Notification description',
                type = 'error'
            })
            return
        end
        RSGCore.Functions.TriggerCallback('qc-billing:server:getPlayerFromCitizenId', function(validRecipient)
            if validRecipient then
                engageConfirmBillMenu(billAmount, validRecipient)
            else
                lib.notify({
                    title = Lang:t('error.getting_player'),
                    description = 'Notification description',
                    type = 'error'
                })
                engageSendBillMenu()
            end
        end, recipientCitizenId)
    end
end)


RegisterNetEvent('qc-billing:client:engageChooseBillViewMenu', function()
    if Config.Menu == 'ox_lib' then
        lib.registerContext({
            id = 'bill_view_menu',
            title = Lang:t('menu.billing_options'),
            options = {
                {
                    title = Lang:t('menu.view_your_bills_bullet'),
                    event = 'qc-billing:client:engageChooseYourBillsViewMenu',
                    arrow = true
                },
                {
                    title = Lang:t('menu.view_sent_bills_bullet'),
                    event = 'qc-billing:client:engageChooseSentBillsViewMenu',
                    arrow = true
                },
                {
                    title = Lang:t('menu.send_new_bill_bullet'),
                    event = 'qc-billing:client:canSendBill',
                    arrow = true
                }
            }
        })
        lib.showContext('bill_view_menu')
    elseif Config.Menu == 'rsg-menu' then
        local menu = {
            {
                header = Lang:t('menu.billing_options'),
                isMenuHeader = true
            },
            {
                header = Lang:t('menu.view_your_bills_bullet'),
                params = {
                    event = 'qc-billing:client:engageChooseYourBillsViewMenu'
                }
            },
            {
                header = Lang:t('menu.view_sent_bills_bullet'),
                params = {
                    event = 'qc-billing:client:engageChooseSentBillsViewMenu'
                }
            },
            {
                header = Lang:t('menu.send_new_bill_bullet'),
                params = {
                    event = 'qc-billing:client:canSendBill'
                }
            },
            {
                header = Lang:t('menu.cancel_bullet'),
                params = {
                    event = 'rsg-menu:closeMenu'
                }
            }
        }
        exports['rsg-menu']:openMenu(menu)
    end
end)



RegisterNetEvent('qc-billing:client:engageChooseSentBillsViewMenu', function()
    if Config.Menu == 'ox_lib' then
        lib.registerContext({
            id = 'sent_bills_menu',
            title = Lang:t('menu.sent_bills'),
            options = {
                {
                    title = Lang:t('menu.view_pending_bullet'),
                    event = 'qc-billing:server:getPendingBilled',
                    arrow = true
                },
                {
                    title = Lang:t('menu.view_paid_bullet'),
                    event = 'qc-billing:server:getPaidBilled',
                    arrow = true
                },
                {
                    title = Lang:t('menu.return_bullet'),
                    event = 'qc-billing:client:engageChooseBillViewMenu',
                    arrow = true
                }
            }
        })
        lib.showContext('sent_bills_menu')
    elseif Config.Menu == 'rsg-menu' then
        local menu = {
            {
                header = Lang:t('menu.sent_bills'),
                isMenuHeader = true
            },
            {
                header = Lang:t('menu.view_pending_bullet'),
                params = {
                    isServer = true,
                    event = 'qc-billing:server:getPendingBilled'
                }
            },
            {
                header = Lang:t('menu.view_paid_bullet'),
                params = {
                    isServer = true,
                    event = 'qc-billing:server:getPaidBilled'
                }
            },
            {
                header = Lang:t('menu.return_bullet'),
                params = {
                    event = 'qc-billing:client:engageChooseBillViewMenu'
                }
            },
            {
                header = Lang:t('menu.cancel_bullet'),
                params = {
                    event = 'rsg-menu:closeMenu' 
                }
            }
        }
        exports['rsg-menu']:openMenu(menu)
    end
end)


RegisterNetEvent('qc-billing:client:engageChooseYourBillsViewMenu', function()
    if Config.Menu == 'ox_lib' then
        lib.registerContext({
            id = 'your_bills_menu',
            title = Lang:t('menu.your_bills'),
            options = {
                {
                    title = Lang:t('menu.view_current_due_bullet'),
                    event = 'qc-billing:server:getBillsToPay',
                    arrow = true
                },
                {
                    title = Lang:t('menu.view_past_paid_bullet'),
                    event = 'qc-billing:server:getPaidBills',
                    arrow = true
                },
                {
                    title = Lang:t('menu.return_bullet'),
                    event = 'qc-billing:client:engageChooseBillViewMenu',
                    arrow = true
                }
            }
        })
        lib.showContext('your_bills_menu')
    elseif Config.Menu == 'rsg-menu' then
        local menu = {
            {
                header = Lang:t('menu.your_bills'),
                isMenuHeader = true
            },
            {
                header = Lang:t('menu.view_current_due_bullet'),
                params = {
                    isServer = true,
                    event = 'qc-billing:server:getBillsToPay'
                }
            },
            {
                header = Lang:t('menu.view_past_paid_bullet'),
                params = {
                    isServer = true,
                    event = 'qc-billing:server:getPaidBills'
                }
            },
            {
                header = Lang:t('menu.return_bullet'),
                params = {
                    event = 'qc-billing:client:engageChooseBillViewMenu'
                }
            },
            {
                header = Lang:t('menu.cancel_bullet'),
                params = {
                    event = 'rsg-menu:closeMenu' 
                }
            }
        }
        exports['rsg-menu']:openMenu(menu)
    end
end)


RegisterNetEvent('qc-billing:client:openConfirmPayBillMenu', function(data)
    local bill = data.bill
    if Config.Menu == 'ox_lib' then
        lib.registerContext({
            id = 'confirm_pay_bill_menu',
            title = Lang:t('menu.confirm_pay', { amount = comma_value(bill.amount) }),
            options = {
                {
                    title = Lang:t('menu.confirm_bill_info', { 
                        billId = bill.id, 
                        date = bill.bill_date, 
                        senderName = bill.sender_name, 
                        account = bill.sender_account 
                    }),
                },
                {
                    title = Lang:t('menu.no_back'),
                    event = 'qc-billing:server:getBillsToPay',
                    arrow = true
                },
                {
                    title = Lang:t('menu.yes_pay'),
                    event = 'qc-billing:server:payBill',
                    args = { bill = bill },
                    arrow = true
                }
            }
        })
        lib.showContext('confirm_pay_bill_menu')
    elseif Config.Menu == 'rsg-menu' then
        local billsMenu = {
            {
                header = Lang:t('menu.confirm_pay', { amount = comma_value(bill.amount) }),
                isMenuHeader = true,
                txt = Lang:t('menu.confirm_bill_info', { 
                    billId = bill.id, 
                    date = bill.bill_date, 
                    senderName = bill.sender_name, 
                    account = bill.sender_account 
                })
            },
            {
                header = Lang:t('menu.no_back'),
                params = {
                    isServer = true,
                    event = 'qc-billing:server:getBillsToPay'
                }
            },
            {
                header = Lang:t('menu.yes_pay'),
                params = {
                    isServer = true,
                    event = 'qc-billing:server:payBill',
                    args = {
                        bill = bill
                    }
                }
            }
        }
        exports['rsg-menu']:openMenu(billsMenu)
    end
end)


RegisterNetEvent('qc-billing:client:openConfirmCancelBillMenu', function(data)
    local bill = data.bill
    if Config.Menu == 'ox_lib' then
        lib.registerContext({
            id = 'confirm_cancel_bill_menu',
            title = Lang:t('menu.confirm_cancel', { amount = comma_value(bill.amount) }),
            options = {
                {
                    title = Lang:t('menu.cancel_bill_info', {
                        date = bill.bill_date,
                        account = bill.sender_account,
                        recipientName = bill.recipient_name,
                        recipientCid = bill.recipient_citizenid
                    }),
                },
                {
                    title = Lang:t('menu.no_back'),
                    event = 'qc-billing:server:getPendingBilled',
                    arrow = true
                },
                {
                    title = Lang:t('menu.yes_cancel'),
                    event = 'qc-billing:server:deleteBill',
                    args = { bill = bill },
                    arrow = true
                }
            }
        })
        lib.showContext('confirm_cancel_bill_menu')
    elseif Config.Menu == 'rsg-menu' then
        local billsMenu = {
            {
                header = Lang:t('menu.confirm_cancel', { amount = comma_value(bill.amount) }),
                isMenuHeader = true,
                txt = Lang:t('menu.cancel_bill_info', {
                    date = bill.bill_date,
                    account = bill.sender_account,
                    recipientName = bill.recipient_name,
                    recipientCid = bill.recipient_citizenid
                })
            },
            {
                header = Lang:t('menu.no_back'),
                params = {
                    isServer = true,
                    event = 'qc-billing:server:getPendingBilled'
                }
            },
            {
                header = Lang:t('menu.yes_cancel'),
                params = {
                    isServer = true,
                    event = 'qc-billing:server:deleteBill',
                    args = {
                        bill = bill
                    }
                }
            }
        }
        exports['rsg-menu']:openMenu(billsMenu)
    end
end)


RegisterNetEvent('qc-billing:client:openPendingBilledMenu', function(bills)
    local ordered_keys = {}
    local totalDue = 0
    for k, v in pairs(bills) do
        table.insert(ordered_keys, k)
        totalDue = totalDue + v.amount
    end
    table.sort(ordered_keys)
    if Config.Menu == 'ox_lib' then
        local options = {}
        for i = #ordered_keys, 1, -1 do
            local v = bills[i]
            table.insert(options, {
                title = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
                description = Lang:t('menu.cancel_bill_info', { date = v.bill_date, account = v.sender_account, recipientName = v.recipient_name, recipientCid = v.recipient_citizenid }),
                event = 'qc-billing:client:openConfirmCancelBillMenu',
                args = { bill = v }
            })
        end
        table.insert(options, {
            title = Lang:t('menu.return_bullet'),
            event = 'qc-billing:client:engageChooseSentBillsViewMenu',
            arrow = true
        })
        table.insert(options, {
            title = Lang:t('menu.cancel_bullet'),
            event = 'rsg-menu:client:closeMenu'
        })
        lib.registerContext({
            id = 'pending_bills_menu',
            title = Lang:t('menu.bills_owed'),
            description = Lang:t('menu.total_owed', { amount = comma_value(totalDue) }),
            options = options
        })
        lib.showContext('pending_bills_menu')
    elseif Config.Menu == 'rsg-menu' then
        local billsMenu = {
            {
                header = Lang:t('menu.bills_owed'),
                isMenuHeader = true,
                txt = Lang:t('menu.total_owed', { amount = comma_value(totalDue) })
            }
        }
        for i = #ordered_keys, 1, -1 do
            local v = bills[i]
            table.insert(billsMenu, {
                header = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
                txt = Lang:t('menu.cancel_bill_info', { date = v.bill_date, account = v.sender_account, recipientName = v.recipient_name, recipientCid = v.recipient_citizenid }),
                params = {
                    event = 'qc-billing:client:openConfirmCancelBillMenu',
                    args = { bill = v }
                }
            })
        end
        table.insert(billsMenu, {
            header = Lang:t('menu.return_bullet'),
            params = {
                event = 'qc-billing:client:engageChooseSentBillsViewMenu'
            }
        })
        table.insert(billsMenu, {
            header = Lang:t('menu.cancel_bullet'),
            params = {
                event = exports['rsg-menu']:closeMenu()
            }
        })
        exports['rsg-menu']:openMenu(billsMenu)
    end
end)


RegisterNetEvent('qc-billing:client:openPaidBilledMenu', function(bills)
    local ordered_keys = {}
    local totalPaid = 0
    for k, v in pairs(bills) do
        table.insert(ordered_keys, k)
        totalPaid = totalPaid + v.amount
    end
    table.sort(ordered_keys)
    if Config.Menu == 'ox_lib' then
        local options = {}
        for i = #ordered_keys, 1, -1 do
            local v = bills[i]
            table.insert(options, {
                title = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
                description = Lang:t('menu.paid_billed_info', { date = v.bill_date, account = v.sender_account, recipientName = v.recipient_name, recipientCid = v.recipient_citizenid, datePaid = v.status_date }),
                event = 'qc-billing:client:notifyOfPaidBilled'
            })
        end
        table.insert(options, {
            title = Lang:t('menu.return_bullet'),
            event = 'qc-billing:client:engageChooseSentBillsViewMenu',
            arrow = true
        })
        table.insert(options, {
            title = Lang:t('menu.cancel_bullet'),
            event = 'rsg-menu:client:closeMenu'
        })
        lib.registerContext({
            id = 'paid_bills_menu',
            title = Lang:t('menu.bills_paid'),
            description = Lang:t('menu.total_paid', { amount = comma_value(totalPaid) }),
            options = options
        })
        lib.showContext('paid_bills_menu')
    elseif Config.Menu == 'rsg-menu' then
        local billsMenu = {
            {
                header = Lang:t('menu.bills_paid'),
                isMenuHeader = true,
                txt = Lang:t('menu.total_paid', { amount = comma_value(totalPaid) })
            }
        }
        for i = #ordered_keys, 1, -1 do
            local v = bills[i]
            table.insert(billsMenu, {
                header = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
                txt = Lang:t('menu.paid_billed_info', { date = v.bill_date, account = v.sender_account, recipientName = v.recipient_name, recipientCid = v.recipient_citizenid, datePaid = v.status_date }),
                params = {
                    event = 'qc-billing:client:notifyOfPaidBilled'
                }
            })
        end
        table.insert(billsMenu, {
            header = Lang:t('menu.return_bullet'),
            params = {
                event = 'qc-billing:client:engageChooseSentBillsViewMenu'
            }
        })
        table.insert(billsMenu, {
            header = Lang:t('menu.cancel_bullet'),
            params = {
                event = 'rsg-menu:client:closeMenu'
            }
        })
        exports['rsg-menu']:openMenu(billsMenu)
    end
end)


RegisterNetEvent('qc-billing:client:openBillsToPayMenu', function(bills)
    local ordered_keys = {}
    local totalDue = 0
    for k, v in pairs(bills) do
        table.insert(ordered_keys, k)
        totalDue = totalDue + v.amount
    end
    table.sort(ordered_keys)
    if Config.Menu == 'ox_lib' then
        local options = {}
        for i = #ordered_keys, 1, -1 do
            local v = bills[i]
            table.insert(options, {
                title = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
                description = Lang:t('menu.unpaid_bill_info', { date = v.bill_date, senderName = v.sender_name, account = v.sender_account }),
                event = 'qc-billing:client:openConfirmPayBillMenu',
                args = { bill = v }
            })
        end
        table.insert(options, {
            title = Lang:t('menu.return_bullet'),
            event = 'qc-billing:client:engageChooseYourBillsViewMenu',
            arrow = true
        })
        table.insert(options, {
            title = Lang:t('menu.cancel_bullet'),
            event = 'rsg-menu:client:closeMenu'
        })
        lib.registerContext({
            id = 'bills_to_pay_menu',
            title = Lang:t('menu.owed_bills'),
            description = Lang:t('menu.total_due', { amount = comma_value(totalDue) }),
            options = options
        })
        lib.showContext('bills_to_pay_menu')
    elseif Config.Menu == 'rsg-menu' then
        local billsMenu = {
            {
                header = Lang:t('menu.owed_bills'),
                isMenuHeader = true,
                txt = Lang:t('menu.total_due', { amount = comma_value(totalDue) })
            }
        }
        for i = #ordered_keys, 1, -1 do
            local v = bills[i]
            table.insert(billsMenu, {
                header = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
                txt = Lang:t('menu.unpaid_bill_info', { date = v.bill_date, senderName = v.sender_name, account = v.sender_account }),
                params = {
                    event = 'qc-billing:client:openConfirmPayBillMenu',
                    args = {
                        bill = v
                    }
                }
            })
        end
        table.insert(billsMenu, {
            header = Lang:t('menu.return_bullet'),
            params = {
                event = 'qc-billing:client:engageChooseYourBillsViewMenu'
            }
        })
        table.insert(billsMenu, {
            header = Lang:t('menu.cancel_bullet'),
            params = {
                event = 'rsg-menu:client:closeMenu'
            }
        })
        exports['rsg-menu']:openMenu(billsMenu)
    end
end)


RegisterNetEvent('qc-billing:client:openPaidBillsMenu', function(bills)
    local ordered_keys = {}
    local totalPaid = 0
    for k, v in pairs(bills) do
        table.insert(ordered_keys, k)
        totalPaid = totalPaid + v.amount
    end
    table.sort(ordered_keys)
    if Config.Menu == 'ox_lib' then
        local options = {}
        for i = #ordered_keys, 1, -1 do
            local v = bills[i]
            table.insert(options, {
                title = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
                description = Lang:t('menu.paid_bills_info', { date = v.bill_date, senderName = v.sender_name, account = v.sender_account, datePaid = v.status_date }),
                event = 'qc-billing:client:notifyOfPaidBill'
            })
        end
        table.insert(options, {
            title = Lang:t('menu.return_bullet'),
            event = 'qc-billing:client:engageChooseYourBillsViewMenu',
            arrow = true
        })
        table.insert(options, {
            title = Lang:t('menu.cancel_bullet'),
            event = 'rsg-menu:client:closeMenu'
        })

        -- Register and show the context menu
        lib.registerContext({
            id = 'paid_bills_menu',
            title = Lang:t('menu.paid_bills'),
            description = Lang:t('menu.total_paid', { amount = comma_value(totalPaid) }),
            options = options
        })
        lib.showContext('paid_bills_menu')
    elseif Config.Menu == 'rsg-menu' then
        local billsMenu = {
            {
                header = Lang:t('menu.paid_bills'),
                isMenuHeader = true,
                txt = Lang:t('menu.total_paid', { amount = comma_value(totalPaid) })
            }
        }
        for i = #ordered_keys, 1, -1 do
            local v = bills[i]
            table.insert(billsMenu, {
                header = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
                txt = Lang:t('menu.paid_bills_info', { date = v.bill_date, senderName = v.sender_name, account = v.sender_account, datePaid = v.status_date }),
                params = {
                    event = 'qc-billing:client:notifyOfPaidBill'
                }
            })
        end
        table.insert(billsMenu, {
            header = Lang:t('menu.return_bullet'),
            params = {
                event = 'qc-billing:client:engageChooseYourBillsViewMenu'
            }
        })
        table.insert(billsMenu, {
            header = Lang:t('menu.cancel_bullet'),
            params = {
                event = 'rsg-menu:client:closeMenu'
            }
        })
        exports['rsg-menu']:openMenu(billsMenu)
    end
end)

RegisterNetEvent('qc-billing:client:getBillsToPay', function()
    TriggerServerEvent('qc-billing:server:getBillsToPay')
end)

RegisterNetEvent('qc-billing:client:getPendingBilled', function()
    TriggerServerEvent('qc-billing:server:getPendingBilled')
end)
