CREATE PROCEDURE [Staging].[PennyforLondon_DonationFilesStatus_PfL]
WITH EXECUTE AS OWNER
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_DonationFilesStatus_PfL',
		TableSchemaName = 'Relational',
		TableName = 'DonationFileStatus_PfL',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

----------------------------------------------------------------------------------------
-----------------------Populate Table - DonationFilesStatus_PfL-------------------------
----------------------------------------------------------------------------------------
Truncate Table Relational.DonationFileStatus_PfL
Insert into Relational.DonationFileStatus_PfL
Select ID as [DonationFileStatus_PfL_ID]
      ,[Description]
From SLC_Report.pfl.[DonationFileStatus]


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_DonationFilesStatus_PfL' and
		TableSchemaName = 'Relational' and
		TableName = 'DonationFileStatus_PfL' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.DonationFileStatus_PfL)
where	StoredProcedureName = 'Penny4London_DonationFilesStatus_PfL' and
		TableSchemaName = 'Relational' and
		TableName = 'DonationFileStatus_PfL' and
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