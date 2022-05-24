/*

	Author:		Stuart Barnley

	Date:		23rd January 2017

	Purpose:	To find those who opened the targeted email before redeeming for Amazon Vouchers

*/
CREATE Procedure Staging.AmazonVoucherEmailOpeners
With Execute as Owner
As

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'AmazonVoucherEmailOpeners',
		TableSchemaName = 'InsightArchive',
		TableName = 'AmazonRedemptions_OpenedEmails',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

-------------------------------------------------------------------------------------------------
-----------------------------------Find the relevant Campaigns-----------------------------------
-------------------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#CampaignKeys') IS NOT NULL DROP TABLE #CampaignKeys
select ec.CampaignKey
Into #CampaignKeys
From warehouse.relational.EmailCampaign as ec
inner join warehouse.relational.CampaignLionSendIDs as cls
	on ec.CampaignKey = cls.CampaignKey
Where ec.SendDate = '2017-01-20' and
		CampaignName like '%Amazon Ear%'
Order by CampaignName

-------------------------------------------------------------------------------------------------
-------------------------Find Customers who opened an Email for this campaign--------------------
-------------------------------------------------------------------------------------------------
Select	ee.FanID,
		Min(ee.EventDateTime) as DT
Into #Cust_Amazons
from #CampaignKeys as ck
inner join warehouse.relational.EmailEvent as ee
	on ck.CampaignKey = ee.CampaignKey
Where EmailEventCodeID in (605,1301)
Group by ee.FanID

-------------------------------------------------------------------------------------------------
---------------------------------------Find Customers who have redeemed--------------------------
-------------------------------------------------------------------------------------------------

Select r.FanID,Min(RedeemDate) as Rdate
into #Reds
From Warehouse.Relational.Redemptions as r
Where	r.PartnerID = 1000005
Group by FanID

-------------------------------------------------------------------------------------------------
-------------------Create a table of Amazon openers who are not already logged-------------------
-------------------------------------------------------------------------------------------------

Select a.FanID
Into #AmazonOpeners
from #Cust_Amazons as a
Left Outer join #Reds as r
	on a.FanID = r.FanID
Left Outer join Warehouse.InsightArchive.AmazonRedemptions_OpenedEmails as o
	on a.fanid = o.FanID
Where	(a.DT < r.Rdate or r.Rdate is null) and
		o.FanID is null

-------------------------------------------------------------------------------------------------
------------------------------Add entries to table that runs report------------------------------
-------------------------------------------------------------------------------------------------
Declare @RowNo int
Insert into Warehouse.InsightArchive.AmazonRedemptions_OpenedEmails
Select	FanID,
		'2017-01-20' as EmailDate
from #AmazonOpeners
Set @RowNo = @@RowCount

-------------------------------------------------------------------------------------------------
-----------------------------Update Joblog entry with EndDate Time------------------------------
-------------------------------------------------------------------------------------------------
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'AmazonVoucherEmailOpeners' and
		TableSchemaName = 'InsightArchive' and
		TableName = 'AmazonRedemptions_OpenedEmails' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = @RowNo
where	StoredProcedureName = 'AmazonVoucherEmailOpeners' and
		TableSchemaName = 'InsightArchive' and
		TableName = 'AmazonRedemptions_OpenedEmails' and
		TableRowCount is null

/*--------------------------------------------------------------------------------------------------
---------------------------Write to Staging.Joblog table from temp----------------------------------
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
truncate table staging.JobLog_Temp