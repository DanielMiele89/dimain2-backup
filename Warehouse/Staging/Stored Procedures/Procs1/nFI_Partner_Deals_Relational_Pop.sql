/*
	Author:		Stuart Barnley

	Date:		28th September 2016

	Purpose:		To populate a relationa table with the current nFI partner deals



*/

CREATE Procedure [Staging].[nFI_Partner_Deals_Relational_Pop]
WITH EXECUTE AS Owner  
As

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'nFI_Partner_Deals_Relational_Pop',
		TableSchemaName = 'Relational',
		TableName = 'nFI_Partner_Deals',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

-------------------------------------------------------------------------------------
------------------------------------Empty table--------------------------------------
-------------------------------------------------------------------------------------
Truncate Table [Relational].[nFI_Partner_Deals]

-------------------------------------------------------------------------------------
-------------------------------Populate from Staging table---------------------------
-------------------------------------------------------------------------------------

Insert into [Relational].[nFI_Partner_Deals]
Select *
From Staging.nFI_Partner_Deals_For_Reporting

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE(),
		TableRowCount = (Select Count(*) From [Relational].[nFI_Partner_Deals])
where	StoredProcedureName = 'nFI_Partner_Deals_Relational_Pop' and
		TableSchemaName = 'Relational' and
		TableName = 'nFI_Partner_Deals' and
		EndDate is null
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