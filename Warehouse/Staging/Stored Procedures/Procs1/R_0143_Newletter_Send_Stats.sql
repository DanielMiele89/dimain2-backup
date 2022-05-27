CREATE Procedure [Staging].[R_0143_Newletter_Send_Stats]
With Execute as owner
As
Select	l.LionSendID,
		l.ActiveCustomers,
		l.Newsletter_able_Customers,
		l.LoadedByDI/Slots as CustomersSelectedByDI,
		l.LoadedByDI as [RowsSelectedByDI],
		l.HyphenCustomers,
		l.LoadedByGAS/Slots as CustomersSelectedByGAS,
		l.LoadedByGAS as RowsSelectedByGAS,
		l.EmailsSent as [CustomersEmailed],
		l.NoPaymentCards
From warehouse.staging.LionSendLoads as l
Where LionSendID >= 430