/*
		Date:			02nd October 2015

		Author:			Stuart Barnley

		Purpose:		To identify those customers who are Williams and Glynn account holders, who will
						be flagged in the daily feed to SmartFocus
*/
CREATE Procedure [Staging].[SLC_Report_DailyLoad_Phase2Data]
with Execute as owner
as

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'SLC_Report_DailyLoad_Phase2Data',
		TableSchemaName = 'N/A',
		TableName = 'N/A',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = ''

Declare @msg VARCHAR(2048),@time DATETIME
---------------------------------------------------------------------------------------------------------
---------------------------Create a Table of Accounts tht are Williams and Glynn-------------------------
---------------------------------------------------------------------------------------------------------
SELECT @msg = 'Build #BankAccounts Table - Start'
EXEC SLC_Report.[dbo].oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#BankAccounts') is not null 
									drop table #BankAccounts

Select	BankAccountID,
		ROW_NUMBER() OVER(ORDER BY BankAccountID Asc) AS RowNo
Into #BankAccounts
From 
(
Select Distinct ba.ID as BankAccountID
from Staging.WG_SortCodes as sc with (nolock)
inner join SLC_Report.dbo.bankaccount as ba with (nolock)
	on	sc.Sortcode = ba.SortCode and
		COALESCE(BA.[Status], 1) = 1
) as a

--Select * from #BankAccounts
Create Clustered index ix_BankAccounts_BAID 
									on #BankAccounts (BankAccountID)

SELECT @msg = 'Build #BankAccounts Table - End'
EXEC SLC_Report.[dbo].oo_TimerMessage @msg, @time OUTPUT
---------------------------------------------------------------------------------------------------------
------------------Create a Table of Customers who have a Williams and Glynn Account----------------------
---------------------------------------------------------------------------------------------------------

Declare @Chunksize int,@RowNo int, @MaxRow int,@WGCustomers int
Set @Chunksize = 250000
Set @RowNo  = 1
Set @MaxRow = (Select Max(RowNo) from #BankAccounts)

if object_id('tempdb..#CustomersWG') is not null 
									drop table #CustomersWG

Create Table #CustomersWG (FanID int, WG bit, Primary Key (FanID))

SELECT @msg = 'Total Rows = ' + CAST(@MaxRow AS VARCHAR)
EXEC SLC_Report.[dbo].oo_TimerMessage @msg, @time OUTPUT

While @RowNo <= @MaxRow
Begin
		SELECT @msg = 'Start batch RowNo = ' + CAST(@RowNo AS VARCHAR)+ '-'+ CAST(@RowNo+(@Chunksize-1) AS VARCHAR)
		EXEC SLC_Report.[dbo].oo_TimerMessage @msg, @time OUTPUT

		Insert Into #CustomersWG
		Select distinct 
				f.id as FanID,
				1 as WG
		from #BankAccounts as ba
		inner join SLC_Report.[dbo].[IssuerBankAccount] as iba with (nolock)
			on	BA.BankAccountID  = IBA.BankAccountID and
				COALESCE(IBA.CustomerStatus, 1) = 1
		inner join SLC_Report.[dbo].IssuerCustomer as ic with (nolock)
			on	iba.IssuerCustomerID = ic.id
		inner join SLC_Report.[dbo].fan as f with (nolock)
			on  ic.SourceUID = f.sourceuid and
				ic.IssuerID = (Case when ClubID = 132 then 2 else 1 end)
		Left Outer join #CustomersWG as c
			on	f.ID = c.FanID
		Where	f.ClubID in (132,138) and
				f.Status = 1 and
				f.AgreedTCs = 1 and
				ba.RowNo Between @RowNo and @RowNo+(@Chunksize-1) and
				c.FanID is null 

		SELECT @msg = 'End batch RowNo = ' + CAST(@RowNo AS VARCHAR)+ '-'+ CAST(@RowNo+(@Chunksize-1) AS VARCHAR)
		EXEC SLC_Report.[dbo].oo_TimerMessage @msg, @time OUTPUT
		Set @RowNo = @RowNo+@ChunkSize
End

Set @WGCustomers = (Select Count(*) from #CustomersWG)
SELECT @msg = 'Total Customers = ' + CAST(@WGCustomers AS VARCHAR)
		EXEC SLC_Report.[dbo].oo_TimerMessage @msg, @time OUTPUT

---------------------------------------------------------------------------------------------------------
---------------------------------------------Find those V Customers--------------------------------------
---------------------------------------------------------------------------------------------------------
SELECT @msg = 'Start V Customer selection '
		EXEC SLC_Report.[dbo].oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#VCustomers') is not null 
									drop table #VCustomers
select Distinct f.ID as FanID
Into #VCustomers
from SLC_Report.[dbo].fan as f with (nolock)
inner join SLC_Report.[dbo].IssuerCustomer as ic with (nolock)
	on	f.SourceUID = ic.SourceUID and
		(Case 
			When f.ClubID = 132 then 2
			Else 1
		 End) = ic.IssuerID
inner join SLC_Report.[dbo].IssuerCustomerAttribute as ica with (nolock)
	on	ic.ID = ica.IssuerCustomerID and
		ica.EndDate is null
where	f.ClubID in (132,138) AND
		f.AgreedTCs = 1 and
		f.Status = 1 and
		replace(ica.[Value],' ','') = 'V'

SELECT @msg = 'End V Customer selection '
		EXEC SLC_Report.[dbo].oo_TimerMessage @msg, @time OUTPUT
---------------------------------------------------------------------------------------------------------
-----------------------------------------------Find HomeMovers-------------------------------------------
---------------------------------------------------------------------------------------------------------
SELECT @msg = 'Start HomeMovers selection'
		EXEC SLC_Report.[dbo].oo_TimerMessage @msg, @time OUTPUT

Create table #Homemover (FanID int, Primary Key(FanID))

Insert into #Homemover
select fanid
from SLC_Report.[dbo].Fan as f
inner join Relational.Customer as c
	on f.ID = c.FanID
Where	Left(replace(c.Postcode,' ',''),6) <> 
							Left(replace(f.Postcode,' ',''),6) and
		len(c.postcode) >= 5 and
		len(f.Postcode) >= 5

SELECT @msg = 'End HomeMovers selection'
		EXEC SLC_Report.[dbo].oo_TimerMessage @msg, @time OUTPUT

---------------------------------------------------------------------------------------------------------
--------------------------Pull through new First DD Earn Records-----------------------------------------
---------------------------------------------------------------------------------------------------------

Declare @Date date
Set @Date = Getdate()

if object_id('tempdb..#FirstEarnDD') is not null 
									drop table #FirstEarnDD

Select * 
Into #FirstEarnDD
from
(
Select * ,
		ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY BankAccountID ASC) AS RowNo
from Staging.Customer_FirstEarnDDPhase2 as a
Where a.FirstEarnDate = DATEADD(dd, -1, DATEDIFF(dd, 0, @Date))
) as a
Where RowNo = 1
---------------------------------------------------------------------------------------------------------
--------------------------Pull through Not Earned on MY Rewards DD --------------------------------------
---------------------------------------------------------------------------------------------------------
if object_id('tempdb..#NotEarned') is not null 
									drop table #NotEarned
Select FanID,
		AccountNo as Day65AccountNo,
		a.AccountName as Day65AccountName
Into #NotEarned
from
(
Select *,
		ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY BankAccountID ASC) AS RowNo
from Staging.Customer_DDNotEarned
Where ChangeDate = DATEADD(dd, -65, DATEDIFF(dd, 0, @Date))
) as a
Where RowNo = 1
---------------------------------------------------------------------------------------------------------
--------------------------Pull through new First Non-DD Earn Records-------------------------------------
---------------------------------------------------------------------------------------------------------
if object_id('tempdb..#FirstEarn') is not null 
									drop table #FirstEarn
Select a.FanID,
		a.FirstEarnValue,
		a.FirstEarnType
Into #FirstEarn
from Staging.Customers_Passed0GBP as a
Left Outer join Staging.Customer_FirstEarnDDPhase2 as b
	on a.fanid = b.fanID
Where	b.FanID is null and
		a.[Date] = DATEADD(dd, -1, DATEDIFF(dd, 0, @Date)) and
		len(FirstEarnType) > 0

---------------------------------------------------------------------------------------------------------
-----------------------------Conbine data together for final dataset-------------------------------------
---------------------------------------------------------------------------------------------------------
if object_id('tempdb..#t1') is not null 
									drop table #t1

Select	f.ID as FanID,
		Case
			When l.FanID is null then 0
			Else 1
		End as LoyaltyAccount,
		Case
			When v.FanID is null then 0
			Else 1
		End as IsLoyalty,
		coalesce(wg.wg,0) as WG,
		Case
			When fe.FirstEarnDate is not null then fe.FirstEarnDate
			When fe2.FanID is not null then DATEADD(dd, -1, DATEDIFF(dd, 0, @Date))
			Else '1900-01-01' 
		End as FirstEarnDate,
		Case when fe.FanID is not null then 'direct debit frontbook'
			 Else Coalesce(fe2.FirstEarnType,'')
		End as FirstEarnType,
		coalesce(fe.FirstEarnValue,fe2.FirstEarnValue,0) as FirstEarnValue,
		coalesce(Reached,'1900-01-01') as Reached5GBP,
		Coalesce(ne.Day65AccountName,'') as Day65AccountName,
		Coalesce(ne.Day65AccountNo,'') as Day65AccountNo,
		Case
			When h.FanID is null then 0
			Else 1
		End as Homemover,
		Coalesce(fe.AccountName,'') as MyRewardAccount	
Into #t1
from slc_report.dbo.Fan as f
left outer join #CustomersWG as wg
	on	f.id = WG.FanID
left Outer join #VCustomers as V
	on	f.id = v.FanID
Left Outer join #Homemover as h
	on	f.id = h.FanID
left outer join Warehouse.Staging.Customers_Passed0GBP as a
	on	f.id = a.FanID and
		a.Date = @Date
Left Outer join Warehouse.Staging.LoyaltyPhase2Customers as l
	on	f.id = l.FanID
Left Outer join #FirstEarnDD as fe
	on	f.id = fe.FanID
Left Outer join #FirstEarn as fe2
	on f.id = fe2.FanID
Left Outer join Warehouse.[Relational].[Customers_Reach5GBP] as g5
	on	f.id = g5.FanID and
		g5.Redeemed = 0
Left Outer join #NotEarned as ne
	on	f.id = ne.FanID
Where	status = 1 and
		AgreedTCs = 1 and
		ClubID in (132,138)

Truncate Table Warehouse.Staging.SLC_Report_DailyLoad_Phase2DataFields

Insert into Warehouse.Staging.SLC_Report_DailyLoad_Phase2DataFields
Select *
From #t1



/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'SLC_Report_DailyLoad_Phase2Data' and
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
    ON OBJECT::[Staging].[SLC_Report_DailyLoad_Phase2Data] TO [crtimport]
    AS [dbo];

