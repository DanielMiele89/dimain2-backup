CREATE PROCEDURE [Staging].[PennyforLondon_AccountActivityExceptions_PfL]
WITH EXECUTE AS OWNER
AS
BEGIN
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_AccountActivityExceptions_PfL',
		TableSchemaName = 'Relational',
		TableName = 'AccountActivityExceptions_PfL',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
----------------------------------------------------------------------------------------
-----------------------Populate Table - AccountActivityExceptions_PfL-------------------
----------------------------------------------------------------------------------------
Truncate Table Relational.AccountActivityExceptions_PfL
Insert into Relational.AccountActivityExceptions_PfL
Select ID as Exceptions_PfL_ID
      ,MemberID as FanID
      ,ReasonID
      ,StartDate
	  ,EndDate
From SLC_Report.pfl.[AccountActivityExceptions] as a
inner join Relational.Customer as c
	on a.MemberID = c.FanID
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_AccountActivityExceptions_PfL' and
		TableSchemaName = 'Relational' and
		TableName = 'AccountActivityExceptions_PfL' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.AccountActivityExceptions_PfL)
where	StoredProcedureName = 'Penny4London_AccountActivityExceptions_PfL' and
		TableSchemaName = 'Relational' and
		TableName = 'AccountActivityExceptions_PfL' and
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