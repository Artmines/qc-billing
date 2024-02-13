local Translations = {
    error = {
        already_paid = 'This bill is already paid!',
        getting_amount = 'Error getting bill amount',
        getting_id = 'Error getting recipient ID',
        getting_player = 'Error getting player from given ID',
        must_be_on_duty = 'You must be on duty and authorized to bill for your occupation!',
        no_nearby = 'There is no nearby player or they have to get closer!',
        not_enough_money = 'Not enough money in your bank account!',
        not_permitted = 'You are not permitted to bill for this account!',
        retrieving_bills = 'Error retrieving bills',
        sending_bill = 'Error sending bill'
    },
    success = {
        bill_canceled_sender = 'Bill canceled - #%{billId} - Amount: $%{amount} - To: %{recipient}',
        bill_canceled_sender_text = 'Bill canceled<br>#%{billId}<br>Amount: $%{amount}<br>To: %{recipient}<br><br>Access bill via /billing',
        bill_paid_recipient = 'Bill paid - #%{billId} - Amount: $%{amount} - Paid to: %{senderName} "%{account}"',
        bill_paid_recipient_text = 'Bill paid<br>#%{billId}<br>Amount: $%{amount}<br>Paid to: %{senderName} "%{account}"<br><br>Access bill via /billing',
        bill_sent = 'Bill sent - Amount: $%{amount} - To: %{recipient}',
        bill_sent_text = 'Bill sent<br>Amount: $%{amount}<br>To: %{recipient}<br><br>Access bill via /billing'
    },
    info = {
        bill_canceled_recipient = 'Bill canceled - #%{billId} - Amount: $%{amount} - Due to: %{senderName} "%{account}"',
        bill_canceled_recipient_text = 'Bill canceled<br>#%{billId}<br>Amount: $%{amount}<br>Due to: %{senderName} "%{account}"<br><br>Access bill via /billing',
        bill_paid_sender = 'Bill paid - #%{billId} - Amount: $%{amount} - Paid by: %{recipient}',
        bill_paid_sender_text = 'Bill paid<br>#%{billId}<br>Amount: $%{amount}<br>Paid by: %{recipient}<br><br>Access bill via /billing',
        bill_received = 'Bill received - Amount: $%{amount} - From: %{sender} "%{account}"',
        bill_received_text = 'Bill received<br>Amount: $%{amount}<br>From: %{sender} "%{account}"<br><br>Access bill via /billing'
    },
    menu = {
        account_name = 'Account: %{account}',
        amount = 'Amount ($)',
        amount_billed_to = 'Amount: $%{amount}<br>Billed to: %{firstName} %{lastName}',
        ask_send = 'Do you want to send a bill?',
        billing_options = 'Billing Options',
        bills_owed = 'Bills Owed',
        bills_paid = 'Bills Paid',
        cancel_bill_info = 'Date: %{date}<br>Due to: %{account}<br>Recipient: %{recipientName} (%{recipientCid})',
        cancel_bullet = '✖ Cancel',
        confirm = 'Confirm',
        confirm_bill_info = 'Bill #%{billId}<br>Date: %{date}<br>Due to: %{senderName} "%{account}"',
        confirm_cancel = 'Are you sure you want to cancel this bill? Amount: $%{amount}',
        confirm_pay = 'Are you sure you want to pay this bill? Amount: $%{amount}',
        confirm_send = 'Are you sure you want to send this bill?',
        id_amount = '#%{id} - $%{amount}',
        new_bill = 'New Bill',
        no_back = 'No, take me back!',
        no_changed_mind = 'No, I changed my mind!',
        owed_bills = 'Owed Bills',
        paid_billed_info = 'Date: %{date}<br>Due to: %{account}<br>Recipient: %{recipientName} (%{recipientCid})<br>Paid: %{datePaid}',
        paid_bills = 'Paid Bills',
        paid_bills_info = 'Date: %{date}<br>Due to: %{senderName} "%{account}"<br>Paid: %{datePaid}',
        recipient_citizenid = 'Recipient Server CID (#)',
        return_bullet = '← Return',
        send_a_bill_closest_bullet = '• Send a Bill (Closest Player)',
        send_a_bill_id_bullet = '• Send a Bill (By Server CID)',
        send_bill_for_account = 'Yes, send this bill on behalf of this account: %{account}',
        sent_bills = 'Sent Bills',
        send_new_bill_bullet = '• Send New Bill',
        total_due = 'Total Due: $%{amount}',
        total_owed = 'Total Owed: $%{amount}',
        total_paid = 'Total Paid: $%{amount}',
        unpaid_bill_info = 'Date: %{date}<br>Due to: %{senderName} "%{account}"',
        view_current_due_bullet = '• View Current Due',
        view_paid_bullet = '• View Paid',
        view_past_paid_bullet = '• View Past Paid',
        view_pending_bullet = '• View Pending',
        view_sent_bills_bullet = '• View Sent Bills',
        view_your_bills_bullet = '• View Your Bills',
        yes_cancel = 'Yes, cancel this bill!',
        yes_pay = 'Yes, I want to pay it!',
        your_bills = 'Your Bills'
    },
    other = {
        bill_pay_desc = 'Bill pay',
        bill_received_text_subject = 'Bill Received',
        bill_sent_text_subject = 'Bill Sent',
        bill_text_sender = 'Billing Department',
        chat_desc = 'Open billing menu',
        received_bill_canceled_text_subject = 'Received Bill Canceled',
        received_bill_paid_text_subject = 'Received Bill Paid',
        sent_bill_canceled_text_subject = 'Sent Bill Canceled',
        sent_bill_paid_text_subject = 'Sent Bill Paid'
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})