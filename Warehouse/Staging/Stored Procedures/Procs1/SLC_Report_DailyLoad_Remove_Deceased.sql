/*
	Author:			Stuart Barnley

	Date:			25th Jan 2016


	Purpose:		To change the daily feed settings from instigating
					positive reinforcement or welcome emails

	Updates:		N/A

*/
CREATE Procedure	[Staging].[SLC_Report_DailyLoad_Remove_Deceased]
with Execute as owner
as

-----------------------------------------------------------------------------------
------------------------------------Add Entry to JobLog----------------------------
-----------------------------------------------------------------------------------

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'Staging.SLC_Report_DailyLoad_Remove_Deceased',
		TableSchemaName = 'N/A',
		TableName = 'N/A',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = ''

-----------------------------------------------------------------------------------
------Final a list of customers who are currently active but deemed Deceased-------
-----------------------------------------------------------------------------------

Select F.ID
Into #Deceased
from SLC_Report.dbo.Fan as F with (nolock)
Where	AgreedTCs = 1 and
		AgreedTCsDate is not null and
		Status = 1 and
		DeceasedDate is not null

Create Clustered Index IX_Deceased_FanID on #Deceased (ID)

-----------------------------------------------------------------------------------
-----Update fields so that customers do not get positive reinforcement emails------
-----------------------------------------------------------------------------------

Update	Staging.SLC_Report_DailyLoad_Phase2DataFields
Set		FirstEarnType = '',
		Reached5GBP = '1900-01-01',
		Day65AccountName = '',
		Homemover = 0,
		MyRewardAccount = ''
Where FanID in (Select ID as FanID from #Deceased with (nolock))

-----------------------------------------------------------------------------------
------Update customer records to make sure they are not sent Welcome CC Emails-----
-----------------------------------------------------------------------------------

Update SLC_Report.dbo.FanSFDDailyUploadData
Set WelcomeEmailCode = NULL
--from SLC_Report.dbo.FanSFDDailyUploadData as a
Where FanID in (Select ID from #Deceased with (nolock))


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Staging.SLC_Report_DailyLoad_Remove_Deceased' and
		TableSchemaName = 'N/A' and
		TableName = 'N/A' and
		EndDate is null

/*--------------------------------------------------------------------------------------------------
---------------------------------------  Update JobLog Table ---------------------------------------
----------------------------------------------------------------------------------------------------*/
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