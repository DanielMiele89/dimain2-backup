/*
		Author:			Stuart Barnley
		
		Date:			06th July 2015
		
		Description		This stored procedure finds Loyalty DD data

		-- CJM/NB 20161116 Perf
		-- CJM 20170203 Perf
		-- CJM 20180302 Perf
		
*/

CREATE PROCEDURE [Staging].[SLC_Report_DailyLoad_CBP_ProcessDirectDebitStats_SFD_DIMAIN]
with Execute as Owner
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @TodayDate DATE = GETDATE()									

	--------------------------------------------------------------------------------------
	--------------------------- Find list of all DD IronOffers ---------------------------
	--------------------------------------------------------------------------------------
	if object_id('tempdb..#OffersAccountsAll') is not null drop table #OffersAccountsAll
	select	Distinct ba.IronOfferID
	Into #OffersAccountsAll
	from [SLC_Report].[dbo].IronOffer as i 
	inner join [SLC_Report].[dbo].[BankAccountTypeEligibility] as ba 
		on i.ID = ba.IronOfferID
	inner join [SLC_Report].[dbo].IronOfferClub as ioc
		on i.ID = ioc.IronOfferID
	Where	i.StartDate <= @TodayDate and
			ba.DirectDebitEligible = 1
	-- (6 rows affected) / 00:00:00


	--------------------------------------------------------------------------------------
	------------------Find list of eligible IronOffers and AccountTypes-------------------
	--------------------------------------------------------------------------------------
	if object_id('tempdb..#OffersAccounts') is not null drop table #OffersAccounts
	select	ba.IronOfferID,
			ba.BankAccountType,
			ba.CustomerSegment,
			ioc.ClubID
	Into #OffersAccounts
	from .[SLC_Report].[dbo].IronOffer as i
	inner join [SLC_Report].[dbo].[BankAccountTypeEligibility] as ba 
		on i.ID = ba.IronOfferID
	inner join [SLC_Report].[dbo].IronOfferClub as ioc
		on i.ID = ioc.IronOfferID
	Where	i.StartDate <= @TodayDate and
			(i.EndDate >= @TodayDate or i.EndDate is null) and
			ba.DirectDebitEligible = 1
	-- (10 rows affected) / 00:00:01


	--------------------------------------------------------------------------------------
	--------------------------------List of TranTypes and ItemIDs-------------------------
	--------------------------------------------------------------------------------------		
	if object_id('tempdb..#TranTypes') is not null drop table #TranTypes
									
	select	TransactionTypeID,
			ItemID
	Into #TranTypes
	from Warehouse.relational.additionalcashbackawardType
	Where Title like 'Direct Debit%'

	CREATE CLUSTERED INDEX ucx_Stuff ON #TranTypes (ItemID, TransactionTypeID)
	-- (3 rows affected) / 00:00:01


	--------------------------------------------------------------------------------------
	--------------------------Create list of Customers with RowNo-------------------------
	--------------------------------------------------------------------------------------
	if object_id('tempdb..#Customers') is not null drop table #Customers
	Select	*,
			CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS INT) AS RowNo --CJM/NB
	into #Customers
	From (
		Select	-- Distinct
				F.ID as FanID,
				f.SourceUID,
				ic.ID as IssuerCustomerID,
				-----------
				Max(Case
						When ica.Value is null then ''
						When ica.Value = 'V' then 'V'
						Else ''
					End) as CustomerSegment,
				--Coalesce(ica.Value,'') as CustomerSegment,
				-----------
				f.ClubID,
				f.CompositeID
		from [SLC_Report].[dbo].Fan as f
		inner join [SLC_Report].[dbo].IronOfferMember as iom
			on	f.CompositeID = iom.CompositeID and
				(	iom.StartDate <= @TodayDate or iom.StartDate is null	) and
				(	iom.EndDate >= @TodayDate or iom.EndDate is null		)
		inner join #OffersAccounts as oa
			on iom.IronOfferID = oa.IronOfferID
		inner join [SLC_Report].[dbo].[IssuerCustomer] as ic
			on	f.SourceUID = ic.SourceUID and
				Case
					When f.CLUBID = 132 then 2
					Else 1
				End = ic.issuerID
		inner join [SLC_Report].[dbo].IssuerCustomerAttribute as ica
			on	ic.ID = ica.IssuerCustomerID 
			and ica.EndDate is null
			and ica.AttributeID = 1 --CJM/NB
		Group by F.ID,f.SourceUID,ic.ID,f.ClubID,f.CompositeID
	) as a
-- (2152094 rows affected) / 00:01:41

	CREATE CLUSTERED INDEX ucx_Stuff ON #Customers (IssuerCustomerID)
	CREATE NONCLUSTERED INDEX IX_FanID ON #Customers (FanID)

																		
	--------------------------------------------------------------------------------------
	--------------------------------- Create Temporary Tables ----------------------------
	--------------------------------------------------------------------------------------

	if object_id('tempdb..#Accounts') is not null drop table #Accounts
	Create Table #Accounts (	id int identity(1,1) not null,
								FanID int not null, 
								SourceUID varchar(20) not null, 
								IssuerCustomerID int not null, 
								CustomerSegment varchar(8), 
								clubid int not null,
								CompositeID bigint not null,
								RowNo int not null,
								[Type] Varchar(3) not null,
								BankAccountID int not null,
								AccountNumber varchar(3) not null,
								AlreadyValid bit not null,
								Nominee bit not null
								)

	if object_id('tempdb..#FirstTrans') is not null drop table #FirstTrans
	Create Table #FirstTrans (	FanID int not null, 
								FirstTran date not null,
								Primary Key (FanID)
							 )

	---------------************ Create table to hold First Eligible for DD Date****************----------------							
	if object_id('tempdb..#FirstEligible') is not null drop table #FirstEligible
	Create Table #FirstEligible (  FanID int not null, 
								   FirstEligibleDate date not null,
								   Primary Key (FanID)
								)
							
	---------------************ Create table to hold Eligible Account Names and Numbers ****************----------------							
	if object_id('tempdb..#EligibleAccounts') is not null drop table #EligibleAccounts
	Create Table #EligibleAccounts(	FanID int not null,
									AccountName varchar(40) not null,
									AccountNumber varchar(3) not null,
									RowNo int not null
								  )

	---------------************ Create table to hold whether the nominee has been changed by RBS data feed ****************----------------							
	if object_id('tempdb..#RBSNomChange') is not null drop table #RBSNomChange
	Create Table #RBSNomChange(	FanID int not null )


	-- Find where the Nominee has been changed by the data feed
	-- To be uncommented once the one off file additions from the start of the program end
	INSERT INTO #RBSNomChange (FanID)
	Select Distinct f.ID as FanID
	from 
	(
	select	
			Case
				When ic.IssuerID = 2 then 132
				Else 138
			End as ClubID,
			SourceUID
	from [SLC_Report].[dbo].DDCashbackNominee as nc
	inner join [SLC_Report].[dbo].IssuerCustomer as ic
		on nc.IssuerCustomerID = ic.ID
	Where	ChangeSourceType  = 3 --3	= RBS Feed 
			and 
			StartDate = Dateadd(day,DATEDIFF(dd, 0, @TodayDate)-1,0) --or EndDate >= Dateadd(day,DATEDIFF(dd, 0, @TodayDate)-2,0))
	) as a
	inner join [SLC_Report].[dbo].Fan as f
		on	a.SourceUID = f.SourceUID and
			a.ClubID = f.ClubID
	-- (298 rows affected) / 00:00:38


	-- loop was here

	--Pull list of accounts
	Insert into #Accounts
	Select	c.*,
			bah.[Type],
			bah.BankAccountID,
			Right(ba.MaskedAccountNumber,3) as AccountNumber,
			Case
				When oa.CustomerSegment IS null then 1
				When oa.CustomerSegment = c.CustomerSegment then 1
				Else 0
			End as AlreadyValid,
			0 as Nominee
	from #Customers as c
	inner join [SLC_Report].[dbo].[IssuerBankAccount] as iba
		on	c.IssuerCustomerID = iba.IssuerCustomerID 
		--and COALESCE(IBA.CustomerStatus, 1) = 1
		AND (IBA.CustomerStatus = 1 OR IBA.CustomerStatus IS NULL)
	inner join [SLC_Report].[dbo].BankAccount as BA 
		ON	IBA.BankAccountID = BA.ID 
		--AND COALESCE(BA.[Status], 1) = 1
		AND (BA.[Status] = 1 OR BA.[Status] IS NULL)
	INNER JOIN [SLC_Report].[dbo].BankAccountTypeHistory AS BAH 
		ON	BAH.BankAccountID = IBA.BankAccountID AND BAH.EndDate IS NULL	
	inner join #OffersAccounts as oa
		on	oa.BankAccountType = bah.[Type] and
			oa.ClubID = c.ClubID
	-- (2160478 rows affected) / 00:00:11


	
	--Update Nominee Field			
	Update a
		Set Nominee = 1
	from #Accounts as a
	inner join [SLC_Report].[dbo].DDCashbackNominee as dd
		on	a.BankAccountID = dd.BankAccountID and
			a.IssuerCustomerID = dd.IssuerCustomerID and
			dd.enddate is null
	-- (1484719 rows affected) / 00:00:08

	
	--Update Already Valid - Non V Customers on V accounts with V members
	Update #Accounts
		Set AlreadyValid = 1
	from #Accounts as a
	inner join [SLC_Report].[dbo].[IssuerBankAccount] as iba
			on	a.BankAccountID = iba.BankAccountID 
			--AND COALESCE(IBA.CustomerStatus, 1) = 1	
			AND (IBA.CustomerStatus = 1 OR IBA.CustomerStatus IS NULL)
			and a.IssuerCustomerID <> iba.IssuerCustomerID
	inner join [SLC_Report].[dbo].IssuerCustomerAttribute as ica
			on	iba.IssuerCustomerID = ica.IssuerCustomerID 
			and ica.EndDate is null
	inner join #OffersAccounts as oa
		on	oa.BankAccountType = a.[Type] 
		and oa.ClubID = a.ClubID
	Where	AlreadyValid = 0 and
			(oa.CustomerSegment is null or oa.CustomerSegment = ica.Value) 
	-- (0 rows affected) / 00:00:01

	/*
	-- Find the First Tran Date
	Insert Into #FirstTrans
	Select	c.FanID,
			Min([ProcessDate]) as FirstTrans
	from #Customers as c
	inner  
	join [SLC_Report].[dbo].Trans as t  --CJM/NB
		on c.FanID = t.FanID
	inner join #TranTypes as tt
		on	t.TypeID = tt.TransactionTypeID and
			t.ItemID = tt.ItemID
	Group by c.FanID
	-- (1574584 rows affected) / 00:01:15
	*/

	;WITH Preagg AS (
		SELECT	c.FanID, t.TypeID, t.ItemID,
				Min([ProcessDate]) as FirstTrans
		FROM #Customers as c
		INNER hash JOIN [SLC_Report].[dbo].Trans as t  --CJM/NB
			ON c.FanID = t.FanID
		GROUP BY c.FanID, TypeID, ItemID 
	)
	INSERT INTO #FirstTrans
	SELECT t.FanID, 
		Min(FirstTrans) as FirstTrans
	FROM Preagg t
	INNER JOIN #TranTypes as tt
		ON	t.TypeID = tt.TransactionTypeID 
		AND t.ItemID = tt.ItemID
	GROUP BY t.FanID
	-- (1579598 rows affected) / 00:00:40 (00:05:02 in DIDEVTEST with different indexing)


			
	-- Find the First Eligible Date
	Insert Into #FirstEligible
	Select	 c.FanID,
				Min(iom.StartDate) as FirstEligibleDate
	From #Customers as c
	inner join [SLC_Report].[dbo].IronOfferMember as iom
		on c.CompositeID = iom.CompositeID
	inner join #OffersAccountsAll as oaa
		on iom.IronOfferID = oaa.IronOfferID
	Group by c.FanID
	-- (2152094 rows affected) / 00:00:04

	
	-- Delete Invalid Accounts
	Delete from #Accounts Where	AlreadyValid = 0 
	-- 0 / 00:00:01

	CREATE INDEX ix_Stuff ON #Accounts ([clubid],[Type]) INCLUDE ([FanID],[AccountNumber])
	-- 00:00:09
	
	-- Find account Names and numbers 
	Insert into #EligibleAccounts
	Select	a.FanID,
		a.AccountName,
		a.AccountNumber,
		ROW_NUMBER() OVER(PARTITION BY a.FanID ORDER BY a.Ranking ASC
			--
			,
			Case
				When a.AccountName like '%Black%' then 1
				When a.AccountName like '%Plat%' then 2
				When a.AccountName like '%Silver%' then 3
				Else 4
			End
			--
			) AS RowNo

	From
	(
		Select	a.FanID,
				e.AccountName,
				Min(e.Ranking) as Ranking,
				Min(a.AccountNumber) as AccountNumber
		from #Accounts as a
		inner join Warehouse.staging.DirectDebit_EligibleAccounts as e
			on	a.Type = e.AccountType and
				a.clubid = e.ClubID 				
		Group by a.FanID, e.AccountName--, e.Ranking
	) as a	
	-- (2156899 rows affected) / 00:00:35
		

	---------------************ Truncate final storeage table ****************----------------							
	TRUNCATE TABLE [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] -- COMMENTED OUT FOR TESTING ######################################################
			
	-- Correlate data	
	INSERT INTO [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] -- COMMENTED OUT FOR TESTING ################################################################
	SELECT	FanID,
			Case
				When AccountName1 is null then 0
				Else 1
			End as OnTrial,
			Coalesce(Nominee,0) as Nominee,
			FirstDDEarn,
			AccountName1,
			AccountName2,
			AccountName3,
			Coalesce(Over3Accounts,0) as Over3Accounts,
			AccountNumber1,
			AccountNumber2,
			AccountNumber3,
			FirstEligibleDate,
			RBSNomineeChange
	From
	(
	Select	c.FanID,
			MAX(Cast(a.Nominee as Int)) as Nominee,
			Max(Case
					When ea.RowNo = 1 then ea.AccountName
					Else NULL
				End) as AccountName1,
			Max(Case
					When ea.RowNo = 2 then ea.AccountName
					Else NULL
				End) as AccountName2,
			Max(Case
					When ea.RowNo = 3 then ea.AccountName
					Else NULL
				End) as AccountName3,
			Max(Case
					When ea.RowNo > 3 then 1
					Else 0
				End) as Over3Accounts,
			Max(Case
					When ea.RowNo = 1 then ea.AccountNumber
					Else NULL
				End) as AccountNumber1,
			Max(Case
					When ea.RowNo = 2 then ea.AccountNumber
					Else NULL
				End) as AccountNumber2,
			Max(Case
					When ea.RowNo = 3 then ea.AccountNumber
					Else NULL
				End) as AccountNumber3,
			Min(ft.FirstTran) as FirstDDEarn,
			MIN(fe.FirstEligibleDate) as FirstEligibleDate,
			Max(CASE WHEN nc.FanID IS NOT NULL THEN 1 ELSE 0 END) as RBSNomineeChange
	From #Customers as c
	left outer join #Accounts as a
		on c.FanID = a.FanID
	Left Outer join #EligibleAccounts as ea
		on c.FanID = ea.FanID
	left outer Join #FirstTrans as ft
		on c.FanID = ft.fanid
	LEFT OUTER Join #FirstEligible AS fe
		ON c.FanID = fe.FanID
	LEFT OUTER Join #RBSNomChange AS nc
		ON c.FanID = nc.FanID
	Where not exists (
		select 1 FROM [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit]
		where FanID = c.FanID) --Messy hack to deal with duplicate IssuerCustomer records
	Group by c.FanID,ft.FirstTran
	) as a


END

