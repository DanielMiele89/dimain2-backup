/*
Author:		Stuart Barnley
Date:		22nd November 2013
Purpose:	Storing pending and available balances for assessment to prove database is updating
		
Update:							
*/

CREATE PROCEDURE [Staging].[WarehouseLoad_Cashback_Balances_V1_0]
AS
BEGIN


If (Select Count(*) from Staging.Customer_CashbackBalances where [date] = cast(getdate() as date)) = 0
Begin

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Cashback_Balances_V1_0',
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
Declare @RowCount int
Set @RowCount = (Select Count(*) from Staging.Customer_CashbackBalances)



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

--ALTER INDEX IDX_CCA ON Staging.Customer_CashbackBalances REBUILD
--ALTER INDEX IDX_CCP ON Staging.Customer_CashbackBalances REBUILD
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Cashback_Balances_V1_0' and
		TableSchemaName = 'Staging' and
		TableName = 'Customer_CashbackBalances' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Staging.Customer_CashbackBalances) - @RowCount
where	StoredProcedureName = 'WarehouseLoad_Cashback_Balances_V1_0' and
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

End