
Create Procedure [SLC_Report_DailyLoad_FirstSpendDD_RetroRun]
As

Declare @Date date

Set @Date = DATEADD(dd, -0, DATEDIFF(dd, 2, getdate()))
Select @Date

			-------------------------------------------------------------------------------------
			----------------------------------List of Eligible Accounts--------------------------
			-------------------------------------------------------------------------------------
			
			if object_id('tempdb..#Accounts') is not null drop table #Accounts
			
			select BankAccountType,IssuerID,ClubID,IronOfferID,e.AccountName
			Into #Accounts
			from SLC_Report.[dbo].[BankAccountTypeEligibility]  as a with (nolock)
			inner join staging.DirectDebit_EligibleAccounts  as e with (nolock)
				on	a.BankAccountType = e.AccountType and
					a.IssuerID = (Case when e.ClubID = 138 then 1 else 2 end)
			Where	a.DirectDebitEligible = 1 and
					e.LoyaltyFeeAccount = 1 and
					Left(e.AccountName,6) like 'Reward' 
			-------------------------------------------------------------------------------------
			-------------------------------------find offers-------------------------------------
			-------------------------------------------------------------------------------------
			if object_id('tempdb..#Offer') is not null drop table #Offer
			
			Select Distinct i.ID as IronOfferID 
			Into #Offer
			from #Accounts as a
			inner join SLC_Report.[dbo].ironoffer as i with (nolock)
			on	a.IronOfferID  = i.id and
				i.StartDate <= @Date and
				(i.EndDate >= @Date or i.EndDate is null)

		-------------------------------------------------------------------------------------
		----------------------------------find offer membership------------------------------
		-------------------------------------------------------------------------------------

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
			on	iom.CompositeID = f.CompositeID
		left Outer join Staging.Customer_FirstEarnDDPhase2 as a
			on	f.id = a.FanID and
				a.FirstEarnDate < @Date
		Where	f.ClubID in (132,138) and
				f.[Status] = 1 and
				f.AgreedTCs = 1 and
				a.fanid is null
		
		Create Clustered Index ix_LoyaltyAccounts_FanID on #LoyaltyAccounts (FanID)


		-------------------------------------------------------------------------------------
		------------------------------------find first trans---------------------------------
		-------------------------------------------------------------------------------------
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
				cast(t.ProcessDate as date) = DATEADD(dd, -0, DATEDIFF(dd, 0, @Date))
		Group by la.FanID,t.IssuerBankAccountID,la.IssuerID
		-------------------------------------------------------------------------------------
		------------------------------------retrieve spend-----------------------------------
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

		--Select * from #FirstDDEarn
		-------------------------------------------------------------------------------------
		------------------------------Earnings against accounts------------------------------
		-------------------------------------------------------------------------------------
		if object_id('tempdb..#Earnings') is not null drop table #Earnings
		Select	a.FanID,
				a.ClubCash as FirstEarnValue,
				DATEADD(dd, -1, DATEDIFF(dd, 0, @Date)) as FirstEarndate,
--				bah.BankAccountID,
				replace(ea.AccountName,'Account','account') as MyRewardAccount,
				ROW_NUMBER() OVER(PARTITION BY a.FanID ORDER BY a.ClubCash ASC) AS RowNo
		into #Earnings
		from #FirstDDEarn as a
		inner join SLC_Report.[dbo].IssuerBankAccount as iba
			on a.IssuerBankAccountID = iba.ID
		inner JOIN SLC_Report.[dbo].BankAccountTypeHistory AS BAH 
			ON	BAH.BankAccountID = IBA.BankAccountID AND 
				BAH.StartDate <= TranDate and 
				(BAH.EndDate IS NULL or BAH.EndDate >= Trandate)
		inner join #Accounts as ea
			on	bah.[Type] = ea.BankAccountType and
				a.IssuerID = (Case when ea.ClubID = 132 then 2 else 1 end)

		Truncate table Staging.SLC_Report_FirstSpendDD_Retro

		Insert into Staging.SLC_Report_FirstSpendDD_Retro
		Select FanID,FirstEarnValue, FirstEarndate,MyRewardAccount
		From #Earnings
		Where RowNo = 1