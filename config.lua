Config = {}

Config.OnDutyToBillEnabled = true           -- If player must be on duty to bill

Config.AllowNearbyBilling = true            -- If players can bill nearby players (rather than just by server ID)

Config.EnableTextNotifications = true       -- If players receive text notifications for bill status changes
Config.EnablePopupNotification = true       -- If players receive pop-up notifications (QBCore Notify) for bill status changes

-- Jobs which can send bills on behalf of their respective establishments' accounts (qb-management)
Config.PermittedJobs = {
    'cinema',
    'reporter',
    'hunter',
    'horsetrainer',
    'farmer',
    'vallaw',
    'goldsmelter',
    'goldsmelter1',
    'goldsmelter2',
    'valweaponsmith',
    'rhoweaponsmith',
    'blacksmith',
    'valsaloontender',
    'blasaloontender',
    'rhosaloontender',
    'stdenissaloontender1',
    'stdenissaloontender2',
    'vansaloontender',
    'armsaloontender',
    'tumsaloontender',
    'moonsaloontender1',
    'moonsaloontender2',
    'moonsaloontender3',
    'moonsaloontender4',
    'moonsaloontender5',
    'stdeniswholesale',
    'blkwholesale',
    'railroad',
    'police',
    'bountyhunter',
    'medic',
    'realestate',
    'judge',
    'lawyer',
    'governor1',
    'governor2',
    'governor3',
    'governor4',
    'governor5',
    'bootlegger',
    
}

-- Commands --
Config.BillingCommand = 'bill'