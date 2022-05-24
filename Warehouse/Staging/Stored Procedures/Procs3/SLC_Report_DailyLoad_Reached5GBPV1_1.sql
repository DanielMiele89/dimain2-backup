/*
		
		Author:			Stuart Barnley

		Date:			05th October 2015

		Purpose:		Update tablecontaing a list of customers who have 
						reach £5 ClubCashAvailable. It also idicates if they have redeemed

		Update:			Amended to assess balances based on Warehouse table - SmartEmail.SmartEmail_OldSFD_CustomerData


*/

CREATE Procedure [Staging].[SLC_Report_DailyLoad_Reached5GBPV1_1]
with Execute as owner
As
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'SLC_Report_DailyLoad_Reached5GBP',
		TableSchemaName = 'Relational',
		TableName = 'Customers_Reach5GBP',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

Declare @RowNo Int

Set @RowNo = (Select Count(*) from [Relational].[Customers_Reach5GBP])

----------------------------------------------------------------------------------------------
---------------------------------Add extra customers to table---------------------------------
----------------------------------------------------------------------------------------------
--Add an entry for each customer that reaches £5 for the first time
Declare @Today date = getdate()

Insert into [Relational].[Customers_Reach5GBP]
Select	f.[Customer ID] as FanID,
		@Today as Reached,
		0 as Redeemed
from SmartEmail.SmartEmail_OldSFD_CustomerData as f (nolock)
left outer join [Relational].[Customers_Reach5GBP] as c with (nolock)
	on f.[Customer id] = c.FanID
Where	c.FanID is null and
		f.ClubCashAvailable > 5 
----------------------------------------------------------------------------------------------
--------------------------------Find those who reach £5 who have redeemed---------------------
----------------------------------------------------------------------------------------------
--Find customers who reach £5 who have redeemed for the first time

if object_id('tempdb..#t1') is not null drop table #t1
select Distinct c.FanID
Into #t1
from [Warehouse].[Relational].[Customers_Reach5GBP] as c with (nolock)
inner join SLC_Report.dbo.Trans t  with (nolock)
	on t.FanID = c.FanID
inner join SLC_Report.dbo.Redeem r  with (nolock)
	on r.id = t.ItemID
LEFT Outer JOIN (	select ItemID as TransID 
					from SLC_Report.dbo.trans t2  with (nolock)
					where t2.typeid=4
				) as Cancelled 
					ON Cancelled.TransID=T.ID
inner join SLC_Report.dbo.RedeemAction ra  with (nolock)
	on t.ID = ra.transid and ra.Status in (1,6)
where	t.TypeID=3 AND
		T.Points > 0 AND
		c.Redeemed = 0

----------------------------------------------------------------------------------------------
-----------------------Update the Customer Reached £5 table with redeemers--------------------
----------------------------------------------------------------------------------------------
Update [Warehouse].[Relational].[Customers_Reach5GBP]
Set Redeemed = 1
Where	FanID in (Select FanID from #t1 with (nolock)) and
		redeemed = 0

Drop table #t1

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'SLC_Report_DailyLoad_Reached5GBP' and
		TableSchemaName = 'Relational' and
		TableName = 'Customers_Reach5GBP' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = ((Select COUNT(1) from Warehouse.Relational.[Customers_Reach5GBP])-@RowNo)
where	StoredProcedureName = 'SLC_Report_DailyLoad_Reached5GBP' and
		TableSchemaName = 'Relational' and
		TableName = 'Customers_Reach5GBP' and
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