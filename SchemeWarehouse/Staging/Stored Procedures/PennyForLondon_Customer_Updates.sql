CREATE Procedure [Staging].[PennyForLondon_Customer_Updates]
WITH EXECUTE AS OWNER
as

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'PennyForLondon_Customer_Updates',
		TableSchemaName = 'Relational',
		TableName = 'Customer',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'U'
/*--------------------------------------------------------------------------------------------------
-------------------------------------Update to add dates--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Update Relational.Customer
Set ActivatedDate = a.AgreedTCsDate,
	Activated = 1,
	DeactivatedDate = a.DeactivatedDate,
	OptedOutDate = a.Optout_Date
from Relational.Customer as c
inner join staging.Customer_Activate_Deactivate as a
	on	c.fanid = a.fanid and
		c.CurrentlyActive = 0

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'PennyForLondon_Customer_Updates' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer' and
		EndDate is null
--/*--------------------------------------------------------------------------------------------------
-------------------------------Update entry in JobLog Table with Row Count------------------------------
--------------------------------------------------------------------------------------------------------*/
----Count run seperately as when table grows this as a task on its own may take several minutes and we do
----not want it included in table creation times
--Update  Relational.JobLog_Temp
--Set		TableRowCount = (Select COUNT(*) from Relational.Customer)
--where	StoredProcedureName = 'PennyForLondon_Customer_Updates' and
--		TableSchemaName = 'Relational' and
--		TableName = 'Customer' and
--		TableRowCount is null


Insert into Relational.JobLog
select	[StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
from Relational.JobLog_Temp

truncate table Relational.JobLog_Temp
		