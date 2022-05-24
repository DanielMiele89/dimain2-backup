/*
Author:		Stuart Barnley
Date:		22nd November 2013
Purpose:	Storing pending and available balances for assessment to prove database is updating
		
Update:		9th November 2016 SB -	Removal to Table check as this is taking 30 mins on
									it's own to run	
ChrisM 20161116 use @@ROWCOUNT instead of counting rows in table - see comments
*/

CREATE PROCEDURE [Staging].[WarehouseLoad_Cashback_Balances_V1_1]
AS
BEGIN


--If (Select Count(*) from Staging.Customer_CashbackBalances where [date] = cast(getdate() as date)) = 0
--Begin

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Cashback_Balances_V1_1',
		TableSchemaName = 'Staging',
		TableName = 'Customer_CashbackBalances',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

----------------------------------------------------------------------------------------------------
----------------------------------Find out existing Customer table size-----------------------------
----------------------------------------------------------------------------------------------------
--This section works out how many rows are in the table before the addition
-- set transaction isolation level read uncommitted
Declare @RowCount int
--Set @RowCount = (Select Count(*) from Staging.Customer_CashbackBalances) -- ChrisM 20161116 comment out, this takes two minutes (twice!)



--ALTER INDEX IDX_CCA ON Staging.Customer_CashbackBalances DISABLE
--ALTER INDEX IDX_CCP ON Staging.Customer_CashbackBalances DISABLE
----------------------------------------------------------------------------------------------------
------------Copy balances from slc_report.dbo.FANID for Active customers into table-----------------
----------------------------------------------------------------------------------------------------
Insert Into Staging.Customer_CashbackBalances
Select	f.ID as FanID,
		ClubCashPending,
		ClubCashAvailable,
		Cast(Getdate() as date) as [Date]
from SLC_Report.dbo.Fan as f with (nolock)
Where	AgreedTCs = 1 and 
		Status = 1 and 
		clubid in (132,138)
SET @RowCount = @@ROWCOUNT -- ChrisM 20161116 uncomment 

--ALTER INDEX IDX_CCA ON Staging.Customer_CashbackBalances REBUILD
--ALTER INDEX IDX_CCP ON Staging.Customer_CashbackBalances REBUILD
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Cashback_Balances_V1_1' and
		TableSchemaName = 'Staging' and
		TableName = 'Customer_CashbackBalances' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = @RowCount -- ChrisM 20161116 use @@ROWCOUNT
where	StoredProcedureName = 'WarehouseLoad_Cashback_Balances_V1_1' and
		TableSchemaName = 'Staging' and
		TableName = 'Customer_CashbackBalances' and
		TableRowCount is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
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

End

--End