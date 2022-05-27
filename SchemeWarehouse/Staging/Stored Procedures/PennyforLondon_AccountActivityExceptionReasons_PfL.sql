CREATE PROCEDURE [Staging].[PennyforLondon_AccountActivityExceptionReasons_PfL]
WITH EXECUTE AS OWNER
AS
BEGIN
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_AccountActivityExceptionReasons_PfL',
		TableSchemaName = 'Relational',
		TableName = 'AccountActivityExceptionReasons_PfL',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
----------------------------------------------------------------------------------------------
-----------------------Populate Table - AccountActivityExceptionReasons_PfL-------------------
----------------------------------------------------------------------------------------------
Truncate Table Relational.AccountActivityExceptionReasons_PfL
Insert into Relational.AccountActivityExceptionReasons_PfL
Select ID as ReasonID
      ,Reason as ReasonDesc
      ,AccrueDonations
	  ,MakeDonations
From SLC_Report.pfl.AccountActivityExceptionReasons
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_AccountActivityExceptionReasons_PfL' and
		TableSchemaName = 'Relational' and
		TableName = 'AccountActivityExceptionReasons_PfL' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.AccountActivityExceptionReasons_PfL)
where	StoredProcedureName = 'Penny4London_AccountActivityExceptionReasons_PfL' and
		TableSchemaName = 'Relational' and
		TableName = 'AccountActivityExceptionReasons_PfL' and
		TableRowCount is null
	
Insert into Relational.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from Relational.JobLog_Temp

TRUNCATE TABLE Relational.JobLog_Temp
End