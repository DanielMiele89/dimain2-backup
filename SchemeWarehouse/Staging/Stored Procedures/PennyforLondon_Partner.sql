
/*
 Author:			Stuart Barnley
 Date:				05/12/2014

 Description:		This stored procedure creates the Partner table

 Notes:

*/

CREATE Procedure [Staging].[PennyforLondon_Partner]asBegin
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_Partner',
		TableSchemaName = 'Relational',
		TableName = 'Partner',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
----------------------------------------------------------------------------------------
------------------------------Populate Partner table-------------------------------------
----------------------------------------------------------------------------------------
Truncate Table Relational.Partner

Insert into	Relational.Partner
Select 0 as PartnerID, 'Transport For London' as PartnerName

Insert into	Relational.Partner
select	psd.PartnerID,
		P.Name as PartnerName
		
from	Relational.PartnerSchemeDates psd with (nolock)
		Inner Join SLC_Report.dbo.Partner p with (nolock) on psd.PartnerID = p.ID

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_Partner' and
		TableSchemaName = 'Relational' and
		TableName = 'Partner' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
-----------------------------Update entry in JobLog Table with Row Count------------------------------
------------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Partner)
where	StoredProcedureName = 'Penny4London_Partner' and
		TableSchemaName = 'Relational' and
		TableName = 'Partner' and
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