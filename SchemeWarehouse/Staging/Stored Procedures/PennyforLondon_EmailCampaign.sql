
/*
 Author:			Stuart Barnley
 Date:				29/10/2014

 Description:		This stored procedure creates the EmailCampaign table

 Notes:

*/

CREATE Procedure [Staging].[PennyforLondon_EmailCampaign]
WITH EXECUTE AS OWNER
as
Begin

Declare @RecordCount int
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_EmailCampaign',
		TableSchemaName = 'Relational',
		TableName = 'EmailCampaign',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

/*--------------------------------------------------------------------------------------------------
------------------------------------Find list of PfL campaigns--------------------------------------
----------------------------------------------------------------------------------------------------*/
Select Distinct CampaignKey
Into #Campaigns
from Relational.EmailEvent
/*--------------------------------------------------------------------------------------------------
-----------------------------Populate EmailEventCode Table----------------------------------------------
----------------------------------------------------------------------------------------------------*/
Truncate table Relational.EmailCampaign

Insert into	Relational.EmailCampaign

select	 a.CampaignKey
		,a.CampaignName
		,a.SendDate
		,a.EmailsSent
		,a.EmailsDelivered
from	SLC_Report.dbo.EmailCampaign as a
inner join #Campaigns as c
	on a.CampaignKey = c.CampaignKey



/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_EmailCampaign' and
		TableSchemaName = 'Relational' and
		TableName = 'EmailCampaign' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
-----------------------------Update entry in JobLog Table with Row Count------------------------------
------------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.EmailCampaign)
where	StoredProcedureName = 'Penny4London_EmailCampaign' and
		TableSchemaName = 'Relational' and
		TableName = 'EmailCampaign' and
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