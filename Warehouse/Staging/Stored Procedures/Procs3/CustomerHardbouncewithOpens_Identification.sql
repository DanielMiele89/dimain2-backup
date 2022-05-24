/*
	Author:		Stuart Barnley

	Date:		January 13th 2016

	Purpose:	To isolate a group of customers that we believe are marked as hard bounced but
				have subsequently opened and email. It can then be decided if these customer
				should be reintroduced to MyRewards.

	Updates:	NA

*/

CREATE Procedure Staging.CustomerHardbouncewithOpens_Identification (@Date Date,@TableName varchar(200))
As
---------------------------------------------------------------------------------------------------
---------------------------Find customers who have bounced since @StartDate -----------------------
---------------------------------------------------------------------------------------------------
if object_id('tempdb..#HBs') is not null drop table #HBs
select FanID,EventDate as HBDate,ec.CampaignKey as HB_CampaignKey
into #HBs
from Warehouse.relational.EmailEvent as ee
inner join Warehouse.relational.EmailCampaign as ec
	on ee.CampaignKey = ec.CampaignKey
where	ee.EmailEventCodeID = 702 and
		ee.EventDate >= @Date

---------------------------------------------------------------------------------------------------
-------------------------------Find customers who have opened an email since-----------------------
---------------------------------------------------------------------------------------------------
if object_id('tempdb..#t1') is not null drop table #t1
select Distinct b.*,ee.EventDate,ee.CampaignKey
into #t1
From Warehouse.relational.EmailEvent as ee
inner join #HBS as b
	on ee.fanid = b.fanid
inner join warehouse.relational.EmailCampaign as ec
	on ee.CampaignKey = ec.CampaignKey
Where	ee.EmailEventCodeID = 1301 and
		ee.EventDate > HBDate and
		ec.SendDate > b.HBDate
Order by b.FanID,ee.EventDate

---------------------------------------------------------------------------------------------------
---------Pull off a list of customers who are active and hardbounced that can be updated-----------
---------------------------------------------------------------------------------------------------
Declare @Qry nvarchar(Max)
Set @Qry = '
if object_id('+char(39)+@TableName+CHAR(39)+') is not null drop table ' + @TableName + '

			Select Distinct t.FanID
			Into '+@TableName+'
			from #t1 as t
			inner join warehouse.relational.customer as c
				on t.fanid = c.fanid
			Where	c.Hardbounced = 1 and
			c.CurrentlyActive = 1
			'
--Select @Qry
Exec SP_ExecuteSQL @Qry