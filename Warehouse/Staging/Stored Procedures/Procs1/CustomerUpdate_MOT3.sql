--Use Warehouse
Create Procedure Staging.CustomerUpdate_MOT3
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'CustomerUpdate_MOTWeekNos',
		TableSchemaName = 'Relational',
		TableName = 'CustomerJourney_MOTWeekNos',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'U'

Declare @MaxCampaignNo int
-------------------------------------------------------------------------------------------------
-----------------------------Create Weekly Campaign Emails Table---------------------------------
-------------------------------------------------------------------------------------------------
if object_id('tempdb..#Campaigns') is not null drop table #Campaigns
Select cls.CampaignKey,SendDateTime,ROW_NUMBER() OVER(ORDER BY SendDateTime Desc) AS RowNo
Into #Campaigns
from Relational.CampaignLionSendIDs as cls
inner join Relational.EmailCampaign as ec
	on cls.CampaignKey = ec.CampaignKey
Where	SendDate >= '2013-08-23' and 
		(	Left(CampaignName,10) ='RBS Engage' or Left(CampaignName,14) ='Natwest Engage')

Delete from #Campaigns
Where RowNo >=
(select Min(c.RowNo) from #Campaigns as c
inner join staging.CustomerJourney_MOTWeekNos as cj
	on c.CampaignKey = cj.CampaignKey
)

Select * from #Campaigns
Set @MaxCampaignNo = (Select Max(RowNo) from #Campaigns)
-----------------------------------------------------------------------------------------------
-------------------------------Find new records to be added - S & R------------------------------------
-----------------------------------------------------------------------------------------------
Insert into Warehouse.Staging.CustomerJourney_MOTWeekNos
Select	Distinct 
		c.FanID,
		0 as MOT1_WeekNo,
		3 as MOT1_Cycles,
		0 as MOT2_WeekNo,
		3 as MOT2_Cycles,
		3 as MOT3,
		NUll as CampaignKey
from Warehouse.relational.Customer as c
left Outer join Warehouse.Staging.CustomerJourney_MOTWeekNos as mot
	on c.FanID = mot.FanID
inner join Warehouse.Relational.CustomerJourney as cj
	on c.FanID = cj.FanID and cj.EndDate is null
Where	CurrentlyActive = 1 and 
		mot.FanID is null and
		(cj.CustomerJourneyStatus like 'Saver%' or cj.CustomerJourneyStatus = 'Redeemer%')
-----------------------------------------------------------------------------------------------------
-------------------------------------Find new records to be added - S & R------------------------------------
-----------------------------------------------------------------------------------------------------
Insert into Warehouse.Staging.CustomerJourney_MOTWeekNos
Select	Distinct 
		c.FanID,
		0 as MOT1_WeekNo,
		1 as MOT1_Cycles,
		0 as MOT2_WeekNo,
		1 as MOT2_Cycles,
		0 as MOT3,
		NUll as CampaignKey
from Warehouse.relational.Customer as c
left Outer join Warehouse.Staging.CustomerJourney_MOTWeekNos as mot
	on c.FanID = mot.FanID
inner join Warehouse.Relational.CustomerJourney as cj
	on c.FanID = cj.FanID and cj.EndDate is null
Where	CurrentlyActive = 1 and 
		mot.FanID is null and
		Not (cj.CustomerJourneyStatus like 'Saver%' or cj.CustomerJourneyStatus = 'Redeemer%')

---------------------------------------------------------------------------------------------------
-----------------------------Create Table of people who need assessing-----------------------------
---------------------------------------------------------------------------------------------------
--Set @MaxCampaignNo = (Select Max(RowNo) from #Campaigns)
if object_id('tempdb..#ThoseToBeAssessed') is not null drop table #ThoseToBeAssessed
Select	sfd.[Customer ID],
		sfd.CJS,
		sfd.WeekNumber,
		sfd.CampaignKey
Into #ThoseToBeAssessed
from Warehouse.Relational.SFD_PostUploadAssessmentData as sfd
inner join #Campaigns as cur
	on sfd.CampaignKey = cur.CampaignKey

---------------------------------------------------------------------------------------------------
---------------------Create Table of people who have received subsequent email---------------------
---------------------------------------------------------------------------------------------------
if object_id('tempdb..#Emailed') is not null drop table #Emailed
Select * 
Into #Emailed
from
(select	ee.CampaignKey,
		a.CJS,
		a.WeekNumber,
		ee.FanID,
		Max(Case
				When ee.EmailEventCodeID in (901,910,605,1301) then 1
				Else 0
			End) as Received,
		Max(Case
				When ee.EmailEventCodeID = 702 then 1
				Else 0
			End) as Bounced

from #ThoseToBeAssessed as a
inner join warehouse.Relational.EmailEvent as ee
	on a.[Customer ID] = ee.FanID
inner join #Campaigns as c
	on c.CampaignKey = ee.CampaignKey
Where a.CampaignKey = ee.campaignKey
Group by ee.CampaignKey,ee.FanID,a.CJS,a.WeekNumber
) as a
Where Received = 1 and Bounced = 0
Order by a.FanID 
--(1181824 row(s) affected)
---------------------------------------------------------------------------------------------------
-----------------------------------------On-going----------------------------------------
---------------------------------------------------------------------------------------------------
Update Warehouse.Staging.CustomerJourney_MOTWeekNos
Set MOT1_Cycles = 3,
	MOT1_WeekNo = 0,
	CampaignKey = e.CampaignKey
from #Emailed as e
inner join Warehouse.Staging.CustomerJourney_MOTWeekNos as mot
	on e.FanID = mot.fanid
Where cjs = 'M1O'

Update Warehouse.Staging.CustomerJourney_MOTWeekNos
Set MOT2_Cycles = 3,
	MOT2_WeekNo = 0,
	CampaignKey = e.CampaignKey
from #Emailed as e
inner join Warehouse.Staging.CustomerJourney_MOTWeekNos as mot
	on e.FanID = mot.fanid
Where cjs = 'M2O'


Update Warehouse.Staging.CustomerJourney_MOTWeekNos
Set MOT3_WeekNo = e.WeekNumber,
	CampaignKey = e.CampaignKey
from #Emailed as e
inner join Warehouse.Staging.CustomerJourney_MOTWeekNos as mot
	on e.FanID = mot.fanid
Where cjs = 'M3'

Update Warehouse.Staging.CustomerJourney_MOTWeekNos
Set CampaignKey = e.CampaignKey
from #Emailed as e
inner join Warehouse.Staging.CustomerJourney_MOTWeekNos as mot
	on e.FanID = mot.fanid
Where cjs in ('SAV','Red')

Update Warehouse.Staging.CustomerJourney_MOTWeekNos
Set CampaignKey = e.CampaignKey,
	MOT1_WeekNo = e.WeekNumber,
	MOT1_Cycles = 
			Case
				When mot.mot1_WeekNo = 7 and e.WeekNumber = 2 then  2
				Else MOT1_Cycles
			End
from #Emailed as e
inner join Warehouse.Staging.CustomerJourney_MOTWeekNos as mot
	on e.FanID = mot.fanid
Where cjs in ('M1')

Update Warehouse.Staging.CustomerJourney_MOTWeekNos
Set CampaignKey = e.CampaignKey,
	MOT2_WeekNo = e.WeekNumber,
	MOT2_Cycles = 
			Case
				When mot.mot2_WeekNo = 10 and e.WeekNumber = 2 then  2
				Else MOT2_Cycles
			End
from #Emailed as e
inner join Warehouse.Staging.CustomerJourney_MOTWeekNos as mot
	on e.FanID = mot.fanid
Where cjs in ('M2')
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'CustomerUpdate_MOTWeekNos' and
		TableSchemaName = 'Relational' and
		TableName = 'CustomerJourney_MOTWeekNos' and
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