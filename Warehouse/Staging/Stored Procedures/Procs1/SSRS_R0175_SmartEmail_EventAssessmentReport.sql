--Use Warehouse

CREATE Procedure [Staging].[SSRS_R0175_SmartEmail_EventAssessmentReport] (@SDate Date, @EDate date)
With Execute as Owner
AS

Declare	@StartDate date,
		@EndDate date
		
Set @StartDate = @SDate
Set @EndDate = @EDate

-------------------------------------------------------------------------------------------------------------
-------------------Pull Through a List of Campaigns submitted by the new Platform----------------------------
-------------------------------------------------------------------------------------------------------------

if object_id('tempdb..#EmailCampaigns') is not null drop table #EmailCampaigns
Select	*,
		ROW_NUMBER() OVER(ORDER BY ec.CampaignKey ASC) AS RowNo
Into #EmailCampaigns
From Relational.EmailCampaign as ec
Where CampaignKey not like '%[a-z]%' and
	SendDate between @StartDate and @EndDate

Create Clustered Index cix_EmailCampaigns_CampaignKey on #EmailCampaigns (CampaignKey)

-------------------------------------------------------------------------------------------------------------
------------------------- Create a temporary table to hold the campaign stats -------------------------------
-------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#CampaignData') is not null drop table #CampaignData
Create Table #CampaignData ([CampaignKey] nvarchar(8) not null,
							[Sent] int,
							[Opened] int,
							[Clicked] int,
							[Bounces] int,
							[Unsubscribe] int,
							PRIMARY KEY (CampaignKey)
							)

-------------------------------------------------------------------------------------------------------------
--------------------------------- Loop Around to Pull Campaign Statistics -----------------------------------
-------------------------------------------------------------------------------------------------------------
Declare @RowNo int = 1,
		@RowNoMax int = (Select Max(RowNo) From #EmailCampaigns),
		@CampaignKey varchar(10)

While @RowNo <= @RowNoMax
Begin
	--************************** Select the next Cmapaign Key **************************--
	Set @CampaignKey = (Select CampaignKey from #EmailCampaigns Where RowNo = @RowNo)

	--************************** Calculate and insert Counts  **************************--
	Insert into #CampaignData
	Select	CampaignKey,
			Count(*) as [Sent],
			Sum([Opened]) as [Opened],
			Sum([Clicks]) as [Clicks],
			Sum([Bounces]) as [Bounces],
			Sum([Unsubscribe]) as [Unsubscribe]
		From (
		Select ee.FanID,
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
				ee.CampaignKey,
				Max(Case 
					When EmailEventCodeID in (701,702) then 1  ---This is looking for either a soft or hard bounce
					Else 0
				End) as Bounces,
				Max(Case 
					When EmailEventCodeID in (303,301) then 1  ---This is looking for either a soft or hard bounce
					Else 0
				End) as Unsubscribe
		From slc_report.dbo.emailevent as Ee
		Where CampaignKey = @CampaignKey
		Group by FanID,ee.CampaignKey
		) as a
		Group by a.CampaignKey
		Option (recompile)

	Set @RowNo = @RowNo+1
End

-------------------------------------------------------------------------------------------------------------
--------------------------- Format Data for final report and store in Temp Table ----------------------------
-------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#FinalStats') is not null drop table #FinalStats
Select	ec.CampaignKey,
		ec.CampaignName,
		ec.SendDate,
		cd.[Sent],
		cd.Opened,
		cd.Clicked,
		cd.Bounces,
		cd.Unsubscribe
Into #FinalStats
From #CampaignData as cd
Left Outer join #EmailCampaigns as ec
	on cd.CampaignKey = ec.CampaignKey

-------------------------------------------------------------------------------------------------------------
-------------------------------------- Display final data for Report ----------------------------------------
-------------------------------------------------------------------------------------------------------------

Select * 
from #FinalStats