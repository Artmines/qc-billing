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

local function engageSendBillMenu()
    local senderData = RSGCore.Functions.GetPlayerData()
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
            lib.notify({title = Lang:t('error.must_be_on_duty'),type = 'error'})
        end
    end)
end)

RegisterNetEvent('qc-billing:client:notifyOfPaidBill', function()
    lib.notify({title = Lang:t('error.already_paid'),type = 'error'})
    TriggerServerEvent('qc-billing:server:getPaidBills')
end)

RegisterNetEvent('qc-billing:client:notifyOfPaidBilled', function()
    lib.notify({title = Lang:t('error.already_paid'),type = 'error'})
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
            billAmount = input.amount
            if not billAmount or billAmount == '' or tonumber(billAmount) <= 0 then
                lib.notify({title = Lang:t('error.getting_amount'),type = 'error'})
                return
            end
            RSGCore.Functions.TriggerCallback('qc-billing:server:getPlayerFromCitizenId', function(validRecipient)
                if validRecipient then
                    engageConfirmBillMenu(billAmount, validRecipient)
                else
                    lib.notify({title = Lang:t('error.getting_player'),type = 'error'})
                    engageSendBillMenu()
                end
            end, recipientCitizenId)
        else
            lib.notify({title = Lang:t('error.no_nearby'),type = 'error'})
            return
        end
    else
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
        billAmount = input.amount
        if not recipientCitizenId or recipientCitizenId == '' then
            lib.notify({title = Lang:t('error.getting_citizenid'),type = 'error'})
            return
        end
        if not billAmount or billAmount == '' or tonumber(billAmount) <= 0 then
            lib.notify({title = Lang:t('error.getting_amount'),type = 'error'})
            return
        end
    end
    RSGCore.Functions.TriggerCallback('qc-billing:server:getPlayerFromCitizenId', function(validRecipient)
        if validRecipient then
            engageConfirmBillMenu(billAmount, validRecipient)
        else
            lib.notify({title = Lang:t('error.getting_player'),type = 'error'})
            engageSendBillMenu()
        end
    end, recipientCitizenId)
end)

RegisterNetEvent('qc-billing:client:engageChooseBillViewMenu', function()
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
                event = exports['rsg-menu']:closeMenu()
            }
        },
    }
    exports['rsg-menu']:openMenu(menu)
end)

RegisterNetEvent('qc-billing:client:engageChooseSentBillsViewMenu', function()
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
                event = exports['rsg-menu']:closeMenu()
            }
        },
    }
    exports['rsg-menu']:openMenu(menu)
end)

RegisterNetEvent('qc-billing:client:engageChooseYourBillsViewMenu', function()
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
                event = exports['rsg-menu']:closeMenu()
            }
        },
    }
    exports['rsg-menu']:openMenu(menu)
end)

RegisterNetEvent('qc-billing:client:openConfirmPayBillMenu', function(data)
    local bill = data.bill
    local billsMenu = {
        {
            header = Lang:t('menu.confirm_pay', { amount = comma_value(bill.amount) }),
            isMenuHeader = true,
            txt = Lang:t('menu.confirm_bill_info', { billId = bill.id, date = bill.bill_date, senderName = bill.sender_name, account = bill.sender_account })
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
end)

RegisterNetEvent('qc-billing:client:openConfirmCancelBillMenu', function(data)
    local bill = data.bill
    local billsMenu = {
        {
            header = Lang:t('menu.confirm_cancel', { amount = comma_value(bill.amount) }),
            isMenuHeader = true,
            txt = Lang:t('menu.cancel_bill_info', { date = bill.bill_date, account = bill.sender_account, recipientName = bill.recipient_name, recipientCid = bill.recipient_citizenid })
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
end)

RegisterNetEvent('qc-billing:client:openPendingBilledMenu', function(bills)
    local ordered_keys = {}
    local totalDue = 0
    for k, v in pairs(bills) do
        table.insert(ordered_keys, k)
        totalDue = totalDue + v.amount
    end
    table.sort(ordered_keys)
    local billsMenu = {
        {
            header = Lang:t('menu.bills_owed'),
            isMenuHeader = true,
            txt = Lang:t('menu.total_owed', { amount = comma_value(totalDue) })
        }
    }
    if #bills > 6 then
        billsMenu[#billsMenu + 1] = {
            header = Lang:t('menu.return_bullet'),
            params = {
                event = 'qc-billing:client:engageChooseSentBillsViewMenu'
            }
        }
    end
    for i = #ordered_keys, 1, -1 do
        local v = bills[i]
        billsMenu[#billsMenu + 1] = {
            header = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
            txt = Lang:t('menu.cancel_bill_info', { date = v.bill_date, account = v.sender_account, recipientName = v.recipient_name, recipientCid = v.recipient_citizenid }),
            params = {
                event = 'qc-billing:client:openConfirmCancelBillMenu',
                args = {
                    bill = v
                }
            }
        }
    end
    billsMenu[#billsMenu + 1] = {
        header = Lang:t('menu.return_bullet'),
        params = {
            event = 'qc-billing:client:engageChooseSentBillsViewMenu'
        }
    }
    billsMenu[#billsMenu + 1] = {
        header = Lang:t('menu.cancel_bullet'),
        params = {
            event = 'rsg-menu:client:closeMenu'
        }
    }
    exports['rsg-menu']:openMenu(billsMenu)
end)

RegisterNetEvent('qc-billing:client:openPaidBilledMenu', function(bills)
    local ordered_keys = {}
    local totalPaid = 0
    for k, v in pairs(bills) do
        table.insert(ordered_keys, k)
        totalPaid = totalPaid + v.amount
    end
    table.sort(ordered_keys)
    local billsMenu = {
        {
            header = Lang:t('menu.bills_paid'),
            isMenuHeader = true,
            txt = Lang:t('menu.total_paid', { amount = comma_value(totalPaid) })
        }
    }
    if #bills > 6 then
        billsMenu[#billsMenu + 1] = {
            header = Lang:t('menu.return_bullet'),
            params = {
                event = 'qc-billing:client:engageChooseSentBillsViewMenu'
            }
        }
    end
    for i = #ordered_keys, 1, -1 do
        local v = bills[i]
        billsMenu[#billsMenu + 1] = {
            header = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
            txt = Lang:t('menu.paid_billed_info', { date = v.bill_date, account = v.sender_account, recipientName = v.recipient_name, recipientCid = v.recipient_citizenid, datePaid = v.status_date }),
            params = {
                event = 'qc-billing:client:notifyOfPaidBilled'
            }
        }
    end
    billsMenu[#billsMenu + 1] = {
        header = Lang:t('menu.return_bullet'),
        params = {
            event = 'qc-billing:client:engageChooseSentBillsViewMenu'
        }
    }
    billsMenu[#billsMenu + 1] = {
        header = Lang:t('menu.cancel_bullet'),
        params = {
            event = 'rsg-menu:client:closeMenu'
        }
    }
    exports['rsg-menu']:openMenu(billsMenu)
end)

RegisterNetEvent('qc-billing:client:openBillsToPayMenu', function(bills)
    local ordered_keys = {}
    local totalDue = 0
    for k, v in pairs(bills) do
        table.insert(ordered_keys, k)
        totalDue = totalDue + v.amount
    end
    table.sort(ordered_keys)
    local billsMenu = {
        {
            header = Lang:t('menu.owed_bills'),
            isMenuHeader = true,
            txt = Lang:t('menu.total_due', { amount = comma_value(totalDue) })
        }
    }
    if #bills > 6 then
        billsMenu[#billsMenu + 1] = {
            header = Lang:t('menu.return_bullet'),
            params = {
                event = 'qc-billing:client:engageChooseYourBillsViewMenu'
            }
        }
    end
    for i = #ordered_keys, 1, -1 do
        local v = bills[i]
        billsMenu[#billsMenu + 1] = {
            header = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
            txt = Lang:t('menu.unpaid_bill_info', { date = v.bill_date, senderName = v.sender_name, account = v.sender_account }),
            params = {
                event = 'qc-billing:client:openConfirmPayBillMenu',
                args = {
                    bill = v
                }
            }
        }
    end
    billsMenu[#billsMenu + 1] = {
        header = Lang:t('menu.return_bullet'),
        params = {
            event = 'qc-billing:client:engageChooseYourBillsViewMenu'
        }
    }
    billsMenu[#billsMenu + 1] = {
        header = Lang:t('menu.cancel_bullet'),
        params = {
            event = 'rsg-menu:client:closeMenu'
        }
    }
    exports['rsg-menu']:openMenu(billsMenu)
end)

RegisterNetEvent('qc-billing:client:openPaidBillsMenu', function(bills)
    local ordered_keys = {}
    local totalPaid = 0
    for k, v in pairs(bills) do
        table.insert(ordered_keys, k)
        totalPaid = totalPaid + v.amount
    end
    table.sort(ordered_keys)
    local billsMenu = {
        {
            header = Lang:t('menu.paid_bills'),
            isMenuHeader = true,
            txt = Lang:t('menu.total_paid', { amount = comma_value(totalPaid) })
        }
    }
    if #bills > 6 then
        billsMenu[#billsMenu + 1] = {
            header = Lang:t('menu.return_bullet'),
            params = {
                event = 'qc-billing:client:engageChooseYourBillsViewMenu'
            }
        }
    end
    for i = #ordered_keys, 1, -1 do
        local v = bills[i]
        billsMenu[#billsMenu + 1] = {
            header = Lang:t('menu.id_amount', { id = v.id, amount = comma_value(v.amount) }),
            txt = Lang:t('menu.paid_bills_info', { date = v.bill_date, senderName = v.sender_name, account = v.sender_account, datePaid = v.status_date }),
            params = {
                event = 'qc-billing:client:notifyOfPaidBill'
            }
        }
    end
    billsMenu[#billsMenu + 1] = {
        header = Lang:t('menu.return_bullet'),
        params = {
            event = 'qc-billing:client:engageChooseYourBillsViewMenu'
        }
    }
    billsMenu[#billsMenu + 1] = {
        header = Lang:t('menu.cancel_bullet'),
        params = {
            event = 'rsg-menu:client:closeMenu'
        }
    }
    exports['rsg-menu']:openMenu(billsMenu)
end)


RegisterNetEvent('qc-billing:client:getBillsToPay', function()
    TriggerServerEvent('qc-billing:server:getBillsToPay')
end)

RegisterNetEvent('qc-billing:client:getPendingBilled', function()
    TriggerServerEvent('qc-billing:server:getPendingBilled')
end)
