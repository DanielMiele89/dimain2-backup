
CREATE Procedure [Staging].[SLC_Report_DailyLoad_LoyaltyPhase2]
with Execute as owner
as

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'SLC_Report_DailyLoad_LoyaltyPhase2',
		TableSchemaName = 'N/A',
		TableName = 'N/A',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = ''

Declare @msg VARCHAR(2048),@time DATETIME, @Date date
			
			
			Set @Date = GETDATE()
			
			SELECT @msg = 'Start Get list of accounts and IronOfferIDs'
			EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT
			
			
			if object_id('tempdb..#Accounts') is not null drop table #Accounts
			
			select BankAccountType,IssuerID,ClubID,IronOfferID
			Into #Accounts
			from SLC_Report.[dbo].[BankAccountTypeEligibility]  as a with (nolock)
			inner join staging.DirectDebit_EligibleAccounts  as e with (nolock)
				on	a.BankAccountType = e.AccountType and
					a.IssuerID = (Case when e.ClubID = 138 then 1 else 2 end)
			Where	a.DirectDebitEligible = 1 and
					e.LoyaltyFeeAccount = 1
					
			SELECT @msg = 'End Get list of accounts and IronOfferIDs'
			EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT
			
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------
			SELECT @msg = 'Start Get list of active Offers'
			EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT
			
			if object_id('tempdb..#Offer') is not null drop table #Offer
			
			Select Distinct i.ID as IronOfferID 
			Into #Offer
			from #Accounts as a
			inner join SLC_Report.[dbo].ironoffer as i with (nolock)
			on	a.IronOfferID  = i.id and
				i.StartDate <= @Date and
				(i.EndDate >= @Date or i.EndDate is null)
		
			SELECT @msg = 'End Get list of active Offers'
			EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

			--Select * from #Offer
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------
			SELECT @msg = 'Start Get list of active Offer members'
			EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

		if object_id('tempdb..#LoyaltyAccounts') is not null drop table #LoyaltyAccounts
		
		select Distinct 
				f.ID as FanID,
				SourceUID,
				Case
					When ClubID = 132 then 2
					Else 1
				End as IssuerID
		Into #LoyaltyAccounts
		from #Offer as o
		inner LOOP join SLC_Report.[dbo].IronOfferMember as iom with (nolock)
			on	o.IronOfferID = iom.IronOfferID and
				iom.StartDate <= @Date and
				(iom.EndDate >= @Date or iom.EndDate is null)
		inner join SLC_Report.[dbo].Fan as f with (nolock)
			on iom.CompositeID = f.CompositeID
		Where	f.ClubID in (132,138) and
				f.[Status] = 1 and
				f.AgreedTCs = 1
		
		Create Clustered Index ix_LoyaltyAccounts_FanID on #LoyaltyAccounts (FanID)
		
		SELECT @msg = 'End Get list of active Offer members - '+ Cast((Select Count(*) from #LoyaltyAccounts) as varchar)
		EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT
		-------------------------------------------------------------------------------------
		------------------------Populate Ware table for later use----------------------------
		-------------------------------------------------------------------------------------		
		Truncate Table Warehouse.Staging.LoyaltyPhase2Customers

		Insert into Warehouse.Staging.LoyaltyPhase2Customers
		Select FanID from #LoyaltyAccounts

		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------		
						
		SELECT @msg = 'Start - Loyalty members First Earn'
		EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT
		
		if object_id('tempdb..#FirstEarn_Row') is not null drop table #FirstEarn_Row
		
		Select	la.FanID,
				la.IssuerID,
				Min(t.ID) as FirstTranID,
				t.IssuerBankAccountID
		Into #FirstEarn_Row
		from
		(Select TransactionTypeID,ItemID
		From Warehouse.Relational.AdditionalCashbackAwardType
		Where Title Like '%Direct Debit%MyRewards%'
		) as a
		inner join SLC_Report.[dbo].Trans as t with (nolock)
			on	a.TransactionTypeID = t.TypeID and
				a.ItemID = t.ItemID
		inner join SLC_Report.dbo.TransactionType as tt with (nolock)
			on  t.TypeID = tt.ID
		inner join #LoyaltyAccounts as la
			on	t.FanID = la.FanID
		Where	t.ClubCash*tt.Multiplier > 0 and
				t.ProcessDate = DATEADD(dd, -1, DATEDIFF(dd, 0, @Date))
		Group by la.FanID,t.IssuerBankAccountID,la.IssuerID
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------
		if object_id('tempdb..#FirstDDEarn') is not null drop table #FirstDDEarn
		Select	ft.FanID,
				t.ProcessDate as FirstEarndate,
				t.Date as Trandate,
				t.ClubCash,
				t.Price,
				ft.IssuerBankAccountID,
				IssuerID
		Into #FirstDDEarn
		from #FirstEarn_Row as ft
		inner join SLC_Report.[dbo].Trans as t
			on ft.FirstTranID = t.ID
		inner join SLC_Report.dbo.TransactionType as tt with (nolock)
			on  t.TypeID = tt.ID
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------	
		Insert into Warehouse.Staging.Customer_FirstEarnDDPhase2	
		Select	a.FanID,
				a.ClubCash as FirstEarnValue,
				DATEADD(dd, -1, DATEDIFF(dd, 0, @Date)) as FirstEarndate,
				bah.BankAccountID,
				replace(ea.AccountName,'Account','account') as MyRewardAccount
		from #FirstDDEarn as a
		inner join SLC_Report.[dbo].IssuerBankAccount as iba
			on a.IssuerBankAccountID = iba.ID
		inner JOIN SLC_Report.[dbo].BankAccountTypeHistory AS BAH 
			ON	BAH.BankAccountID = IBA.BankAccountID AND 
				BAH.StartDate <= TranDate and 
				(BAH.EndDate IS NULL or BAH.EndDate >= Trandate)
		inner join warehouse.Staging.DirectDebit_EligibleAccounts as ea
			on	bah.[Type] = ea.AccountType and
				a.IssuerID = (Case when ea.ClubID = 132 then 2 else 1 end)
		Left Outer Join Warehouse.Staging.Customer_FirstEarnDDPhase2 as f
			on	a.FanID = f.fanid and
				bah.BankAccountID = f.BankAccountID
		
		SELECT @msg = 'End - Loyalty members First Earn - '+ Cast((Select Count(*) from #FirstEarn_Row) as varchar)
		EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------	
				
		--Select * 
		--From #LoyaltyAccounts as la
		--inner join issuer
		
		if object_id('tempdb..#AccountNames') is not null drop table #AccountNames
		
		Select	la.FanID,
				Replace(e.AccountName,'Account','account') as AccountName,
				ba.ID as BankAccountID,
				ba.MaskedAccountNumber,
				ic.ID as IssuerCustomerID,
				ba.Date AccountSD,
				ba.Status,
				ba.Date BADate,
				ba.LastStatusChangeDate,
				BAh.StartDate as TypeSD,
				e.ID as Ranking
		into #AccountNames
		from #LoyaltyAccounts as la
		inner loop join SLC_Report.[dbo].IssuerCustomer as ic
			on	la.SourceUID = ic.SourceUID and
				la.IssuerID = ic.IssuerID
		inner join SLC_Report.[dbo].[IssuerBankAccount] as iba
			on	ic.ID = iba.IssuerCustomerID and
				COALESCE(IBA.CustomerStatus, 1) = 1
		inner join SLC_Report.[dbo].BankAccount as BA 
			ON	IBA.BankAccountID = BA.ID AND COALESCE(BA.[Status], 1) = 1
		INNER JOIN SLC_Report.[dbo].BankAccountTypeHistory AS BAH 
			ON	BAH.BankAccountID = IBA.BankAccountID AND BAH.EndDate IS NULL	
		inner join staging.DirectDebit_EligibleAccounts  as e
			on	bah.Type = e.AccountType and
				la.IssuerID = (Case When e.ClubID = 132 Then 2 Else 1 End) and
				e.LoyaltyFeeAccount = 1
		Left Outer join Warehouse.Staging.Customer_FirstEarnDDPhase2 as dde
			on	la.FanID = dde.FanID and
				ba.ID = dde.BankAccountID
		Where dde.FanID is null

		
		if object_id('tempdb..#NomineeAccounts') is not null drop table #NomineeAccounts
		Select	
				a.FanID,
				a.BankAccountID,
				a.AccountName,
				right(MaskedAccountNumber,3) as AccountNo,
				CAST(ChangedDate as date) as ChangeDate
		Into #NomineeAccounts
		from #AccountNames as a
		inner join SLC_Report.[dbo].DDCashbackNominee as dd
			on	a.BankAccountID = dd.BankAccountID and
				a.IssuerCustomerID = dd.IssuerCustomerID and
				dd.enddate is null
		
		Truncate Table Staging.Customer_DDNotEarned

		Insert into Staging.Customer_DDNotEarned
		Select	FanID,
				BankAccountID,
				AccountName,
				AccountNo,
				ChangeDate
				
		from #NomineeAccounts

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'SLC_Report_DailyLoad_LoyaltyPhase2' and
		TableSchemaName = 'N/A' and
		TableName = 'N/A' and
		EndDate is null

/*--------------------------------------------------------------------------------------------------
---------------------------------------  Update JobLog Table ---------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp
GO
GRANT EXECUTE
    ON OBJECT::[Staging].[SLC_Report_DailyLoad_LoyaltyPhase2] TO [crtimport]
    AS [dbo];

