--Declare @Category varchar(100),@StartDate Date, @EndDate Date
--Set @Category = 'Positive Reinforcement'
--Set @StartDate = '2015-10-19'
--Set @EndDate = '2015-10-25'

CREATE Procedure [Staging].[SSRS_R0107_EmailSendAssessment_LimitedAudience]  (
						@Category varchar(100),
						@StartDate Datetime, 
						@EndDate Datetime,
						@TableName varchar(500)
														)
with Execute as owner
as

-----------------------------------------------------------------------------------------
---------Create a list of campaign between two dates based on Categories Chosen----------
-----------------------------------------------------------------------------------------

if object_id('tempdb..#Campaigns') is not null drop table #Campaigns

Select ec.CampaignKey,ec.CampaignName,ec.SendDate,a.DisplayName
Into #Campaigns
from Staging.SFD_Email_Categories as a
inner join Slc_report.dbo.EmailCampaign as ec
	on Left(ec.QueryName,Len(a.QueryName)) = a.QueryName and  ---This is matching the queries being used in SFD
		Left(ec.ListName,Len(a.ListName)) = a.ListName  ---This is matching the lists being used in SFD
Where	a.Category in (@Category) and
		Cast(SendDate as Date) Between @StartDate and @EndDate  ---filtering down to chosen date range

--Select * from #Campaigns
-----------------------------------------------------------------------------------------
------------------------For chosen campaigns return send/open bounce stats---------------
-----------------------------------------------------------------------------------------
Declare @Qry nvarchar(max)

Set @Qry = '

Select	CampaignKey,
		CampaignName,
		SendDate,
		DisplayName,
		Count(FanID) as Customers,
		Sum(Opened) as Opened,
		Sum(Case
				When Bounces = 1 and Opened = 0 then 1  --- only counted as bounced if not also opened 
				Else 0
			End) as Bounced,
		Sum(Clicks) as Clicks,
		Cast(Sum(Opened) as real)/Count(FanID) as Open_PCT
--Into #Results
From
(
select	ee.FanID,
		Max(Case
				When EmailEventCodeID in (910) then 1
				Else 0
			End) as [Sent],
		Max(Case 
				When EmailEventCodeID in (1301,605) then 1  ---If opened and/or clicked it is counted as opened
				Else 0
			End) as Opened,
		Max(Case 
				When EmailEventCodeID in (605) then 1
				Else 0
			End) as Clicks,
		ec.CampaignKey,
		ec.CampaignName,
		ec.SendDate,
		ec.DisplayName,
		Max(Case 
				When EmailEventCodeID in (701,702) then 1  ---This is looking for either a soft or hard bounce
				Else 0
			End) as Bounces
from slc_report.dbo.emailevent as ee
inner join #Campaigns as ec
	on ee.campaignkey = ec.campaignkey
inner join ' + @TableName + ' as a
	on ee.FanID = a.fanID
Group by	ee.FanID,ec.CampaignKey,ec.CampaignName,ec.SendDate,
			ec.DisplayName
) as a
Group by	a.CampaignKey,a.CampaignName,a.SendDate,a.DisplayName
'
Exec SP_ExecuteSQL @Qry