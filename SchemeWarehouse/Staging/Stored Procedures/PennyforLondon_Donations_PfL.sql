CREATE PROCEDURE [Staging].[PennyforLondon_Donations_PfL]
WITH EXECUTE AS OWNER
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_Donations_PfL',
		TableSchemaName = 'Relational',
		TableName = 'Donations_PfL',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

----------------------------------------------------------------------------------------
-----------------------Populate Table - DonationFilesStatus_PfL-------------------------
----------------------------------------------------------------------------------------
Truncate Table Relational.Donations_PfL
Insert into Relational.Donations_PfL
Select d.[ID] as [Donations_PfL_ID]
      ,d.[FileID] as [DonationFiles_PfL_ID]
      ,d.[MemberID] as [FanID]
      ,d.[Amt] as [Amount]
      ,d.[PanID]
      ,d.[Status] as [DonationsStatus_PfL_ID]
      ,d.[AuthRef]
	  ,d.[Excess]
From SLC_Report.pfl.[Donations] as d
inner join Relational.DonationFiles_PfL as df
	on d.FileID = df.DonationFiles_PfL_ID
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_Donations_PfL' and
		TableSchemaName = 'Relational' and
		TableName = 'Donations_PfL' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Donations_PfL)
where	StoredProcedureName = 'Penny4London_Donations_PfL' and
		TableSchemaName = 'Relational' and
		TableName = 'Donations_PfL' and
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