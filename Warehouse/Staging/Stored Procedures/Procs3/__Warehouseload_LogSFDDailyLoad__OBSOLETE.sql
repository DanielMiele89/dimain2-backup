/*
	Author:		Stuart Barnley

	Date:		9th June 2016

	Purpose:	To keep a log of when the daily SFD Data calculation completes.

	20180625 ChrisM OBSOLETE

*/
CREATE Procedure [Staging].[__Warehouseload_LogSFDDailyLoad__OBSOLETE]
As

TRUNCATE TABLE staging.JobLog_Temp
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'Warehouseload_LogSFDDailyLoad',
		TableSchemaName = 'Staging',
		TableName = 'SFDDailyDataLog ',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

--Counts pre-population
DECLARE	@RowCount BIGINT
SET @RowCount = (SELECT COUNT(*) FROM staging.SFDDailyDataLog with (nolock))
/*--------------------------------------------------------------------------------------------------
-----------------------------Add Entry to SFDDailyDataLog table-------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Staging.SFDDailyDataLog
Select a.CompletionDate
FROM slc_report.dbo.SFDDailyDataLog as a
Left Outer join Staging.SFDDailyDataLog as b
	on a.CompletionDate = b.CompletionDate
Where b.CompletionDate is null

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Warehouseload_LogSFDDailyLoad' and
		TableSchemaName = 'Staging' and
		TableName = 'SFDDailyDataLog' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Staging.SFDDailyDataLog)-@RowCount
where	StoredProcedureName = 'Warehouseload_LogSFDDailyLoad' and
		TableSchemaName = 'Staging' and
		TableName = 'SFDDailyDataLog' and
		TableRowCount is null

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
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