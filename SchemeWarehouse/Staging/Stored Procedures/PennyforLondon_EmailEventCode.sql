
/*
 Author:			Stuart Barnley
 Date:				29/10/2014

 Description:		This stored procedure creates the EmailEventCode table

 Notes:

*/

CREATE Procedure [Staging].[PennyforLondon_EmailEventCode]
WITH EXECUTE AS OWNER
as
Begin

Declare @RecordCount int
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_EmailEventCode',
		TableSchemaName = 'Relational',
		TableName = 'EmailEventCode',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

/*--------------------------------------------------------------------------------------------------
-----------------------------Populate EmailEventCode Table----------------------------------------------
----------------------------------------------------------------------------------------------------*/
Truncate table Relational.EmailEventCode

Insert into	Relational.EmailEventCode

select	ID			as EmailEventCodeID,
		Name		as [Description]
from	SLC_Report.dbo.EmailEventCode


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_EmailEventCode' and
		TableSchemaName = 'Relational' and
		TableName = 'EmailEventCode' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
-----------------------------Update entry in JobLog Table with Row Count------------------------------
------------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.EmailEventCode)
where	StoredProcedureName = 'Penny4London_EmailEventCode' and
		TableSchemaName = 'Relational' and
		TableName = 'EmailEventCode' and
		TableRowCount is null


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
End