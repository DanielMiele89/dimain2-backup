/*
Author:		Stuart Barnley
Date:		31st January 2014
Purpose:	Attempt to create a staging table of unsusbscribe dates from:
					1. SLC Update
					2. Email Unsubscribe
					3. SFD deemed Unsubscribed

Update:		06-02-2014 SB - Updated to correct JobLog_temp part of code
			20-02-2014 SB - Updated to remove Warehouse references
*/
CREATE PROCEDURE [WHB].[Customer_UnsubscribeCampaigns_V1_1]
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_temp
Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
		TableSchemaName = 'Relational',
		TableName = 'Customer_UnsubscribeDates',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------


	IF OBJECT_ID('tempdb..#UnsubscribedCustomers') IS NOT NULL DROP TABLE #UnsubscribedCustomers
	SELECT	FanID
	INTO #UnsubscribedCustomers
	FROM [Relational].[Customer]
	WHERE Unsubscribed = 1

	CREATE CLUSTERED INDEX CIX_FanID ON #UnsubscribedCustomers (FanID)
	
	IF OBJECT_ID('tempdb..#EmailCampaign') IS NOT NULL DROP TABLE #EmailCampaign
	SELECT	ec.CampaignKey
		,	ec.SendDate
	INTO #EmailCampaign
	FROM [SLC_Report].[dbo].[EmailCampaign] ec
	WHERE EXISTS (	SELECT 1
					FROM [Relational].[CampaignLionSendIDs] cls
					WHERE ec.CampaignKey = cls.CampaignKey)

	CREATE CLUSTERED INDEX CIX_CampaignKey ON #EmailCampaign (CampaignKey)


	Truncate table Staging.Customer_LastEmailReceived
	Insert into Staging.Customer_LastEmailReceived
	Select * 
	from 
	(select	c.FanID,
			ec.SendDate,
			ec.CampaignKey,
			ROW_NUMBER() OVER(PARTITION BY c.FanID ORDER BY ec.SendDate DESC) AS RowNo
	 from #UnsubscribedCustomers as c
	 inner join relational.emailevent as ee
		on c.fanid = ee.fanid
	 inner join #EmailCampaign as ec
		on ee.CampaignKey = ec.CampaignKey
	) as a
	Where RowNo = 1

Truncate table Relational.Customer_UnsubscribeDates
Insert Into Relational.Customer_UnsubscribeDates
Select cud.FanID,cud.EventDate,CampaignKey,cud.Accuracy

from Staging.Customer_UnsubscribeDates as cud
Left Outer join  staging.Customer_LastEmailReceived as ler
	on	cud.FanID = ler.FanID and
		cud.EventDate >= Cast(ler.SendDate as date) and
		cud.EventDate < dateadd(day,21,Cast(ler.SendDate as date))

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Staging.Customer_UnsubscribeDates)
where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Relational' and
		TableName = 'Customer_UnsubscribeDates' and
		TableRowCount is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with EndDate--------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = getdate()
where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Relational' and
		TableName = 'Customer_UnsubscribeDates' and
		EndDate is null

Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp
truncate table staging.JobLog_Temp