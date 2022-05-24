/*
		Author:		Stuart Barnley
		
		Date:		19th May 2016

		Purpose:	For those people that have had a MyReward account open 60 days and did not earn enough in the last calendar month

		Update:		06-04-2017 SB - Amended to deal with new cashback rate and therefore they now only need to earn £2
								  - Also converted heaps to clustered indexed tables
*/

CREATE Procedure [Staging].[SLC_Report_DailyLoad_DirectDebit60days_2_0_RetroSpectiveV1_1] (@MissingDate date,@TableName varchar(200))
--with Execute as owner
as

--Insert into staging.JobLog_Temp
--Select	StoredProcedureName = 'SLC_Report_DailyLoad_DirectDebit60days_2_0',
--		TableSchemaName = 'Staging',
--		TableName = 'SLC_Report_ProductMonitoring',
--		StartDate = GETDATE(),
--		EndDate = null,
--		TableRowCount  = null,
--		AppendReload = 'R'
----------------------------------------------------------------------------------------
-----------------------------Find Accounts and IronOfferIDs-----------------------------
----------------------------------------------------------------------------------------

if object_id('tempdb..#Accounts') is not null drop table #Accounts
			
		select BankAccountType,IssuerID,ClubID,IronOfferID
		Into #Accounts
		from SLC_Report.[dbo].[BankAccountTypeEligibility]  as a with (nolock)
		inner join staging.DirectDebit_EligibleAccounts  as e with (nolock)
			on	a.BankAccountType = e.AccountType and
				a.IssuerID = (Case when e.ClubID = 138 then 1 else 2 end)
		Where	a.DirectDebitEligible = 1 and
				e.LoyaltyFeeAccount = 1

Create Clustered Index CIX_Accounts_IronOfferID on #Accounts (IronOfferID)



----------------------------------------------------------------------------------------
------------------------------Find all current loyalty customers------------------------
----------------------------------------------------------------------------------------

if object_id('tempdb..#Loyalty') is not null drop table #Loyalty

		select	c.ID as FanID,
				c.CompositeID,
				c.SourceUID,
				c.ClubID
		Into #Loyalty
		From Staging.SLC_Report_DailyLoad_Phase2DataFields as a with (nolock)
		inner join SLC_Report.dbo.Fan as c
				on a.FanID = c.ID
		Where a.LoyaltyAccount = 1

Create Clustered Index cix_Loyalty_FanID on #Loyalty (FanID)

----------------------------------------------------------------------------------------
------------------------------find the typeID for these trans---------------------------
----------------------------------------------------------------------------------------

if object_id('tempdb..#Types') is not null drop table #Types
Select	a.AdditionalCashbackAwardTypeID,
		a.TransactionTypeID,
		a.ItemID
into	#Types
From Relational.AdditionalCashbackAwardType a
Where [Description] /*Title*/ Like '%MyRewards%' or --*** SB 2017-07-03 Both 3% and 2%
Title Like '%Credit Card%'

Create Clustered Index cix_Types_TransID_ItemID on #Types (TransactionTypeID,ItemID)

----------------------------------------------------------------------------------------
------------------------------Find out when the opened their account--------------------
----------------------------------------------------------------------------------------
Declare @MaxTranDate Date,
		@Date		 Date,
		@StartTDate  Date,
		@EndTDate	 Date,
		@TypeTDates	 Bit


Set		@MaxTranDate =   (	Select max (b.[Date])
							from #Types as a
							inner join  slc_report.dbo.trans as b
								on	a.ItemID = b.itemid and
									a.TransactionTypeID = b.TypeID
						 )
--Set		@TypeTDates = 1 -- 0 = last 35 days, 1 = last full calendar month

Set		@StartTDate =	Dateadd(month,-1,Dateadd(day,-(day(@MaxTranDate)-1),@MaxTranDate))
							
Set		@EndTDate =		Dateadd(Day,-1,Dateadd(Month,1,(@StartTDate))		)				

Set		@Date = Dateadd(day,DATEDIFF(dd, 0, GETDATE())-61,0)

--Select @MaxTranDate,@StartTDate,@EndTDate,@TypeTDates

----------------------------------------------------------------------------------------
------------------------------Find out when the opened their account--------------------
----------------------------------------------------------------------------------------

if object_id('tempdb..#OfferStartDate') is not null drop table #OfferStartDate
			
Select	l.*,
		iom.IronOfferID,
		MIN(iom.StartDate) as StartDate
into #OfferStartDate
from #Loyalty as l
inner join SLC_Report.dbo.IronOfferMember as iom
	on	l.CompositeID = iom.CompositeID and
		iom.EndDate is null
inner join #Accounts as a
	on	iom.IronofferID = a.IronOfferID

Group By l.FanID,l.CompositeID,l.ClubID,l.SourceUID,iom.IronOfferID
	Having Max(iom.StartDate) = @Date

Create Clustered Index cix_OfferStartDate_FanID on #OfferStartDate (FanID)

----------------------------------------------------------------------------------------
------------------------------find earnings in last 35 days-----------------------------
----------------------------------------------------------------------------------------								

if object_id('tempdb..#Earnings') is not null drop table #Earnings
Select	l.FanID,
		l.ClubID,
		Coalesce(Sum(Case
						When a.ItemID is not null then t.ClubCash
						Else 0
					 End),0) as CashbackEarned
Into	#Earnings
From   #OfferStartDate as l
Left Outer join slc_report.dbo.trans as t
	on	l.FanID = t.FanID and
		t.Date between @StartTDate and @EndTDate
Left Outer join #Types as a
	on	t.typeID = a.TransactionTypeID and
		t.itemid = a.ItemID
Group By l.FanID,ClubID

Create Clustered Index cix_Earnings_FanID on #Earnings (FanID)

----------------------------------------------------------------------------------------
------------------------------Isolate under 3 pound earners-----------------------------
----------------------------------------------------------------------------------------

if object_id('tempdb..#Under3') is not null drop table #Under3
Select	FanID,
		CashbackEarned
Into #Under3
From #Earnings
Where CashbackEarned < /*3*/ 2 --SB 20170406

Create Clustered Index cix_Under3_FanID on #Under3 (FanID)

----------------------------------------------------------------------------------------
-----------Find entries for accounts that earned (but not the customer)-----------------
----------------------------------------------------------------------------------------

if object_id('tempdb..#AccountEarn') is not null drop table #AccountEarn
Select	Distinct 
		u.FanID,
		u.CashbackEarned,
		t.[Date],
		t.VectorMajorID,
		t.VectorMinorID
Into #AccountEarn
from #Under3 as u
inner join slc_report.dbo.trans as t
	on u.FanID = t.FanID
Where [Date] between @StartTDate and @EndTDate and
		t.TypeID = 24 and ItemID in (66,79) --*** SB 2017-07-03 Both 3% and 2%

--Select * from #AccountEarn where fanid = 10353075

--Select * from slc_report.dbo.trans where fanid = 10353075
Create Clustered Index cix_AccountEarn_VectorIDs on #AccountEarn (VectorMajorID,VectorMinorID)

----------------------------------------------------------------------------------------
-----------Find value of accounts that earned (but not the customer)-----------------
----------------------------------------------------------------------------------------

--Select * from 
if object_id('tempdb..#AlterativeEarnings') is not null 
											drop table #AlterativeEarnings
Select	a.FanID,
		a.CashbackEarned,
		Sum(t.ClubCash) as AccountCashbackEarned
Into	#AlterativeEarnings
from #AccountEarn as a
inner join slc_report.dbo.trans as t
	on	a.VectorMajorID = t.VectorMajorID and
		a.VectorMinorID = t.VectorMinorID
Where	TypeID = 23 and ItemID in (66,79) --*** SB 2017-07-03 Both 3% and 2%
Group By a.FanID,a.CashbackEarned

Create Clustered Index cix_#AlterativeEarnings_FanID on #AlterativeEarnings (FanID)

--Select * from #AlterativeEarnings where fanid = 10353075
----------------------------------------------------------------------------------------
-------------------------------Sum earnings plus account earnings-----------------------
----------------------------------------------------------------------------------------
if object_id('tempdb..#TotalEarnings') is not null 
									   drop table #TotalEarnings
Select	e.Fanid,
		e.CashbackEarned,
		Coalesce(a.AccountCashbackEarned,0) as Other, 
		e.CashbackEarned+Coalesce(a.AccountCashbackEarned,0) as Earnings
Into	#TotalEarnings
From #Earnings as e
left outer join #AlterativeEarnings as a
	on e.FanID = a.FanID

Create Clustered Index cix_TotalEarnings_FanID on #TotalEarnings (FanID)
----------------------------------------------------------------------------------------
-------------------------------Isolate still not earned £3------------------------------
----------------------------------------------------------------------------------------
if object_id('tempdb..#StillNotEarned3') is not null 
										 drop table #StillNotEarned3
Select l.*,te.Earnings
into #StillNotEarned3
from #TotalEarnings as te
inner join #Loyalty as l
	on te.FanID = l.fanid
Where Earnings < /*3*/ 2 --SB 20170406

Create Clustered Index cix_StillNotEarned3_FanID on #StillNotEarned3 (FanID)
----------------------------------------------------------------------------------------
--------------------------------Find IssuerCustomerIDs----------------------------------
----------------------------------------------------------------------------------------
if object_id('tempdb..#IssuerCustomerID') is not null 
										  drop table #IssuerCustomerID
Select	Distinct
			F.FanID as FanID,
			f.SourceUID,
			ic.ID as IssuerCustomerID,
			f.ClubID,
			f.CompositeID
	into #IssuerCustomerID
	from #Loyalty as f
	inner join SLC_Report.[dbo].[IssuerCustomer] as ic
		on	f.SourceUID = ic.SourceUID and
			Case
				When f.CLUBID = 132 then 2
				Else 1
			End = ic.issuerID
	inner join SLC_Report.[dbo].IssuerCustomerAttribute as ica
		on	ic.ID = ica.IssuerCustomerID and
			ica.EndDate is null

Create Clustered Index cix_IssuerCustomerID_IssuerCustomerID on #IssuerCustomerID (IssuerCustomerID)

----------------------------------------------------------------------------------------
--------------------------------Find non MyReward accounts------------------------------
----------------------------------------------------------------------------------------

if object_id('tempdb..#BankAccounts') is not null 
									drop table #BankAccounts
		Select	c.FanID,
				c.SourceUID,
				c.IssuerCustomerID,
				bah.[Type],
				bah.BankAccountID,
				Right(ba.MaskedAccountNumber,3) as AccountNumber,
				a.AccountName
		into #BankAccounts
		from #IssuerCustomerID as c
		inner join SLC_Report.[dbo].[IssuerBankAccount] as iba
			on	c.IssuerCustomerID = iba.IssuerCustomerID and
				COALESCE(IBA.CustomerStatus, 1) = 1
		inner join SLC_Report.dbo.BankAccount as BA 
			ON	IBA.BankAccountID = BA.ID AND COALESCE(BA.[Status], 1) = 1
		INNER JOIN SLC_Report.dbo.BankAccountTypeHistory AS BAH 
			ON	BAH.BankAccountID = IBA.BankAccountID AND BAH.EndDate IS NULL
		Left Outer join staging.DirectDebit_EligibleAccounts as a
			on  bah.Type = a.AccountType and
			    c.ClubID = a.ClubID
		Where Left(bah.Type,1) <> 'Q'

Create Clustered Index cix_BankAccounts_FanID on #BankAccounts (FanID)

----------------------------------------------------------------------------------------
--------Remove any who is linked by account to someone who has earned over £3-----------
----------------------------------------------------------------------------------------

if object_id('tempdb..#EarnedOver3') is not null 
									drop table #EarnedOver3
Select  Distinct a.FanID as FanID1,
				 a.Earnings as Earnings1,
				 te.Earnings as Earnings2,
				 te.FanID as FanID2
Into #EarnedOver3
From #StillNotEarned3 as a
inner join #BankAccounts as ba1
	on a.fanid = ba1.FanID
inner join #BankAccounts as ba2
	on	ba1.BankAccountID = ba2.BankAccountID and
		ba1.FanID <> ba2.FanID
inner join #TotalEarnings as te
	on	ba2.FanID = te.FanID
Where te.Earnings >= /*3*/ 2 --SB 20170406

Create Clustered Index cix_EarnedOver3_FanID1 on #EarnedOver3 (FanID1)

----------------------------------------------------------------------------------------
--------------------------------Create Final list of Customers--------------------------
----------------------------------------------------------------------------------------
Declare @StartDate Date,@EndDate Date

Set @StartDate = NULL -- '2015-07-01'
Set @EndDate = @MissingDate--Dateadd(day,DATEDIFF(dd, 0, GETDATE())-60,0)
Set @StartDate = (Case
					When @StartDate is null then @EndDate
					Else @StartDate
				End)


----------------------------------------------------------------------------------------
--------------------------------Create Final list of Customers--------------------------
----------------------------------------------------------------------------------------
if object_id('Tempdb..#FinalCustomers') is not null 
									drop table #FinalCustomers
Select te.*,StartDate
Into #FinalCustomers
from #TotalEarnings as te
inner join #StillNotEarned3 as a
	on te.FanID = a.FanID
Left Outer join  #EarnedOver3 as e
	on a.FanID = e.FanID1
inner join #OfferStartDate as o
	on te.FanID = o.FanID
Where e.FanID1 is null and
		Cast(o.StartDate as date) Between @StartDate and @EndDate

Create Clustered Index cix_FinalCustomers_FanID on #FinalCustomers (FanID)
----------------------------------------------------------------------------------------
--------------------------------Add Account Names to list-------------------------------
----------------------------------------------------------------------------------------
if object_id('tempdb..#FinalCustomersAccounts') is not null 
									drop table #FinalCustomersAccounts

Select a.*,ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY Case
														When AccountName1 like '%Black%' then 1
														When AccountName1 like '%Plat%' then 2
														When AccountName1 like '%Silve%' then 3
														Else 4
													 End ASC) AS RowNo
Into #FinalCustomersAccounts
From (
Select	a.FanID,
		Replace(b.AccountName1,' account','') as AccountName1
from #FinalCustomers as a
inner join slc_report.dbo.FanSFDDailyUploadData_DirectDebit as b
	on a.FanID = b.FanID
Where AccountName1 is not null
Union All
Select	a.FanID,
		Replace(b.AccountName2,' account','') as AccountName2
from #FinalCustomers as a
inner join slc_report.dbo.FanSFDDailyUploadData_DirectDebit as b
	on a.FanID = b.FanID
Where AccountName2 is not null
Union All
Select	a.FanID,
		Replace(b.AccountName3,' account','') as AccountName3
from #FinalCustomers as a
inner join slc_report.dbo.FanSFDDailyUploadData_DirectDebit as b
	on a.FanID = b.FanID
Where AccountName3 is not null
) as a


Delete from #FinalCustomersAccounts Where RowNo > 1

--Select * from #FinalCustomersAccounts as b
--left Outer join Staging.SLC_Report_ProductMonitoring as a
--	on b.FanID = a.FanID
--Where a.FanID is null

--Truncate Table Staging.SLC_Report_ProductMonitoring
Declare @Qry nvarchar(max)

Set @Qry = '
Select	a.FanID as [Customer ID],
		a.AccountName1--,
		--NULL,
		--NULL
Into '+@TableName+'
from #FinalCustomersAccounts as a'

Exec Sp_ExecuteSQL @Qry

--/*--------------------------------------------------------------------------------------------------
-----------------------------Update entry in JobLog Table with End Date-------------------------------
------------------------------------------------------------------------------------------------------*/
--Update  staging.JobLog_Temp
--Set		EndDate = GETDATE(),
--		TableRowCount = (Select Count(FanID) From Staging.SLC_Report_ProductMonitoring)
--where	StoredProcedureName = 'SLC_Report_DailyLoad_DirectDebit60days_2_0_Retro' and
--		TableSchemaName = 'Staging' and
--		TableName = 'SLC_Report_ProductMonitoring' and
--		EndDate is null

--/*--------------------------------------------------------------------------------------------------
-----------------------------------------  Update JobLog Table ---------------------------------------
------------------------------------------------------------------------------------------------------*/
--Insert into staging.JobLog
--select [StoredProcedureName],
--	[TableSchemaName],
--	[TableName],
--	[StartDate],
--	[EndDate],
--	[TableRowCount],
--	[AppendReload]
--from staging.JobLog_Temp

--TRUNCATE TABLE staging.JobLog_Temp