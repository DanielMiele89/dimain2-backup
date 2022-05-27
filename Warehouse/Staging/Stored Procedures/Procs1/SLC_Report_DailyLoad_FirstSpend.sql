/*
	Date:		07-10-2015

	Author:		Stuart Barnley

	Purpose:	To update the table that holds the first spend info

*/
CREATE Procedure [Staging].[SLC_Report_DailyLoad_FirstSpend]
with Execute as owner
As

Declare @msg VARCHAR(2048),@time DATETIME, @Date date
Set @Date = Getdate()
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'Staging.SLC_Report_DailyLoad_FirstSpend',
		TableSchemaName = 'Staging',
		TableName = 'Customers_Passed0GBP',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

Declare @RowNo Int

Set @RowNo = (Select Count(*) from Staging.Customers_Passed0GBP)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

SELECT @msg = 'Start - Find new customers who have passed £0.00'
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

Insert into .Staging.Customers_Passed0GBP
Select	f.ID,
		DATEADD(dd, -1, DATEDIFF(dd, 0, @Date)) as [Date],
		Cast(0.00 as Real) as FirstEarnValue, 
		'' as FirstEarnType,
		'' as MyRewardAccount
From SLC_Report.dbo.Fan as f with (nolock)
left outer join Staging.Customers_Passed0GBP as p with (nolock)
	on f.ID = p.FanID
Where	p.FanID is null and
		f.ClubCashPending > 0 and
		f.ClubID in (132,138) and
		f.AgreedTCs = 1 and
		f.Status = 1 and
		f.AgreedTCsDate is not null

SELECT @msg = 'End - Find new customers who have passed £0.00'
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

----------------------------------------------------------------------------
--------------------Find Customers who passed £0.00 today-------------------
----------------------------------------------------------------------------
SELECT @msg = 'Start - Pull off new customers who have passed £0.00 '
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#Customer') is not null 
									drop table #Customer
Select Distinct a.FanID
Into #Customer
from Staging.Customers_Passed0GBP as a with (nolock)
where [Date] = DATEADD(dd, -1, DATEDIFF(dd, 0, @Date))

Create Clustered Index IX_Customer_FanID on #Customer (FanID)

SELECT @msg = 'End - Pull off new customers who have passed £0.00 - ' + 
							Cast((Select Count(*) From #Customer) as varchar)+ ' Rows'
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT
-------------------------------------------------------------------------------------------------
-------------------------Pull in list of ACA transaction types for assessment--------------------
-------------------------------------------------------------------------------------------------
SELECT @msg = 'Start - Find Additional Cashback Award Types'
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#ACATranTypes') is not null 
									drop table #ACATranTypes
Select	TransactionTypeID as [TypeID],
		[ItemID],
		b.FirstSpendText
Into #ACATranTypes
From Relational.AdditionalCashbackAwardType as a with (nolock)
inner join Staging.Text1stSpend as b with (nolock)
	on a.AdditionalCashbackAwardTypeID = b.AdditionalCashbackAwardTypeID
Where	ItemID is not null

Create Clustered Index ix_AXATranTypes_Combined on #ACATranTypes ([TypeID],[ItemID])

SELECT @msg = 'End - Find Additional Cashback Award Types - ' + 
							Cast((Select Count(*) From #ACATranTypes) as varchar)
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT
-------------------------------------------------------------------------------------------------
-------------------------------------Find the ACA Trans for earning trans------------------------
-------------------------------------------------------------------------------------------------
SELECT @msg = 'Start - Find Additional Cashback Award Trans'
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#Trans') is not null 
									drop table #Trans
Select	FanID,
		ClubCash as FirstEarnValue,
		FirstSpendText as FirstEarntype,
		DATEADD(dd, -1, DATEDIFF(dd, 0, @Date)) as FirstEarnDate
Into #Trans
From
(Select	c.FanID,
		a.FirstSpendText,
		t.ClubCash*tt.Multiplier as ClubCash,
		a.itemid,
		ROW_NUMBER() OVER(PARTITION BY c.FanID 
									ORDER BY a.ItemID Desc,t.ClubCash DESC) AS RowNo

From #Customer as c  with (nolock)
inner LOOP Join SLC_Report.dbo.Trans as t with (nolock)
	on	c.FanID = t.fanid
inner join SLC_Report.dbo.TransactionType as tt with (nolock)
	on  t.TypeID = tt.ID
inner join #ACATranTypes as a with (nolock)
	on	t.TypeID = a.TypeID and
		t.ItemID = a.ItemID
Where t.ProcessDate >= DATEADD(dd, -2, DATEDIFF(dd, 0, @Date)) and
	  t.ClubCash*tt.Multiplier > 0
) as a
Where RowNo = 1 

SELECT @msg = 'End - Find Additional Cashback Award Trans - ' + 
									Cast((select Count(*) from #Trans) as varchar)+ ' Rows'
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

-------------------------------------------------------------------------------------------------
--------------------------------Find the Match and Tran IDs for earning trans--------------------
-------------------------------------------------------------------------------------------------
SELECT @msg = 'Start - Find Partner Trans'
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#PTrans') is not null 
									drop table #PTrans
Select	c.FanID,
		m.ID as MatchID,
		t.ID as TranID,
		dcl.PartnerID,
		dcl.PartnerName,
		Case
			When pc.CardTypeID = 1 then 'credit card payment at '
            When pc.CardTypeID = 2 then 'debit card payment at '
        End as PaymentMethod,
		t.ClubCash*tt.Multiplier as ClubCash
Into #PTrans
from #Customer as c
inner LOOP join SLC_Report.dbo.Trans as t with (nolock)
	on c.FanID = t.FanID
inner join SLC_Report.dbo.TransactionType as tt with (nolock)
	on  t.TypeID = tt.ID
inner join SLC_Report.dbo.Match as M with (nolock)
	on t.MatchID = m.ID
inner join SLC_Report.dbo.RetailOutlet as ro with (nolock)
	on m.RetailOutletID = ro.id
inner join warehouse.staging.Partner_DynamicContentLabel as dcl with (nolock)
	on ro.PartnerID = dcl.PartnerID
inner join SLC_Report..Pan as p with (nolock)
        on t.PanID = p.ID
inner join SLC_Report..PaymentCard as pc with (nolock)
        on p.PaymentCardID = pc.ID
Where	m.[status] = 1 and rewardstatus in (0,1) 
		and	t.ProcessDate >= DATEADD(dd, -2, DATEDIFF(dd, 0, @Date)) 
		and	pc.CardTypeID in (1,2)
		and t.ClubCash*tt.Multiplier > 0

-------------------------------------------------------------------------------------------------
----------------------------Pick Most Important Partner Trans Entry------------------------------
-------------------------------------------------------------------------------------------------
if object_id('tempdb..#PTransNamed') is not null 
									drop table #PTransNamed
Select 	FanID,
		ClubCash as FirstEarnValue,
		TextString as FirstEarnType,
		DATEADD(dd, -1, DATEDIFF(dd, 0, @Date)) as FirstEarnDate
Into #PTransNamed

From (
		Select	pt.FanID,
				pt.PartnerID,
				pt.PartnerName,
				pt.ClubCash,
				Case
					When mrt.Tier is null then 99
					Else mrt.Tier
				End as Tier,
				PaymentMethod+pt.PartnerName as TextString,
				ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY 
								Case	
									When mrt.Tier is null then 99 
									Else mrt.Tier	
								End Asc,ClubCash Desc) 
							AS RowNo

		from #PTrans as pt with (nolock)
		Left Outer join Relational.Master_Retailer_Table as mrt with (nolock)
			on pt.PartnerID = mrt.PartnerID
	) as a

Where RowNo = 1
SELECT @msg = 'End - Find Partner Trans - ' + 
						Cast((select Count(*) from #PTransNamed) as varchar)+ ' Rows'

EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT
-------------------------------------------------------------------------------------------------
-----------------------------------------First Spend - Non DD------------------------------------
-------------------------------------------------------------------------------------------------
SELECT @msg = 'Start - Find most important first spend (Non-DD)'						

EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#FirstSpend') is not null 
									drop table #FirstSpend
Select	t.FanID,
		t.FirstEarnType,
		t.FirstEarnValue 
Into #FirstSpend
from #PTransNamed as t
Union All
Select t.FanID,
		t.FirstEarnType,
		t.FirstEarnValue  
from #Trans as t
Left Outer Join #PTransNamed as pt
	on t.FanID = pt.FanID
Where pt.FanID is null
Order by t.FanID

SELECT @msg = 'End - Find most important first spend (Non-DD) - ' + 
						Cast((select Count(*) from #FirstSpend) as varchar)+ ' Rows'

EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT

-------------------------------------------------------------------------------------------------
-----------------------------------------Update First Earn Table---------------------------------
-------------------------------------------------------------------------------------------------
SELECT @msg = 'Start - Update Warehouse.Staging.Customers_Passed0GBP'
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT
Update Warehouse.Staging.Customers_Passed0GBP
Set	FirstEarnValue = f.FirstEarnValue,
	FirstEarnType = f.FirstEarnType
from Warehouse.Staging.Customers_Passed0GBP as a
inner join #FirstSpend as f
	on a.FanID = f.FanID

SELECT @msg = 'End - Update Warehouse.Staging.Customers_Passed0GBP - '+ Cast((Select Count(*) from #FirstSpend) as Varchar)
EXEC SLC_Report.dbo.oo_TimerMessage @msg, @time OUTPUT


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Staging.SLC_Report_DailyLoad_FirstSpend' and
		TableSchemaName = 'Staging' and
		TableName = 'Customers_Passed0GBP' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = ((Select COUNT(1) from Warehouse.Staging.Customers_Passed0GBP)-@RowNo)
where	StoredProcedureName = 'Staging.SLC_Report_DailyLoad_FirstSpend' and
		TableSchemaName = 'Staging' and
		TableName = 'Customers_Passed0GBP' and
		TableRowCount is null


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
    ON OBJECT::[Staging].[SLC_Report_DailyLoad_FirstSpend] TO [crtimport]
    AS [dbo];

