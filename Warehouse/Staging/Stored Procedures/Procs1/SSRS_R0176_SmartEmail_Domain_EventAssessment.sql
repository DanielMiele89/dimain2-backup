/*

	Author:		Stuart Barnley

	Date:		26th October 2017

	Purpose:	to review the emails sent to customers in the new platform and see how the
				most common domains are responding.

*/
CREATE Procedure [Staging].[SSRS_R0176_SmartEmail_Domain_EventAssessment] (@SDate Date, @EDate Date)
With Execute as Owner
As

Declare @StartDate Date = @SDate,
		@EndDate Date = @EDate

--------------------------------------------------------------------------------------------------------------
--------------------------- Find the domain of all customers Email addresses ---------------------------------
--------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#Domains') IS NOT NULL DROP TABLE #Domains

Select	FanID,
		Email,
		RIGHT(Email,LEN(Email)-CHARINDEX('@',Email)) as Domain
Into	#Domains
From	warehouse.Relational.Customer as c
--Where	CurrentlyActive = 1 

Create Clustered index cix_Domains_Domain on #Domains (Domain)

--------------------------------------------------------------------------------------------------------------
--------------------------- Create a table of the most common domain groups ----------------------------------
--------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#DomainGroups') IS NOT NULL DROP TABLE #DomainGroups

Select 1 as ID, 'Microsoft' as DomainGroup into #DomainGroups Union All
Select 2 as ID, 'gmail' as DomainGroup Union All
Select 3 as ID, 'Yahoo' as DomainGroup Union All
Select 4 as ID, 'bt' as DomainGroup Union All
Select 5 as ID, 'sky.com' as DomainGroup Union All
Select 6 as ID, 'Other' as DomainGroup

Create Clustered Index cix_DomainGroups_ID on #DomainGroups (ID)

--------------------------------------------------------------------------------------------------------------
--------------------------- Allocate customers to a Domain Group where relevant ------------------------------
--------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
Select *
Into #Customers
From (
		Select *,
				Case
					When Domain like 'HOTMAIL.CO.UK' then 1
					When Domain like 'HOTMAIL.COM%' then 1
					When Domain like 'Outlook.com' then 1
					When Domain Like 'live.com' then 1
					When Domain Like 'live.co.uk' then 1
					When Domain Like 'msn.com' then 1
					When Domain Like 'mail.com' then 1
					When Domain like 'Googlemail.COM' then 2
					When Domain like 'gmail.com' then 2
					When Domain like 'gmail.co%' then 2
					When Domain like 'Yahoo.COM%' then 3
					When Domain like 'Yahoo.CO.UK' then 3
					When Domain like 'ymail.com' then 3
					When Domain Like 'rocketmail.com' then 3
			----------------------------------------------------------------------------------
					When Domain like 'btinternet.com' then 4
					When Domain like 'btopenworld.com' then 4
					When Domain like 'btconnect.com' then 4
					When Domain like 'bt.com' then 4
					When Domain like 'talk21.com' then 4
					When Domain Like 'Sky.com' then 5
					ELSE 6
				End as DomainCombined
		From #Domains
	 ) as a
inner join #DomainGroups as d
	on a.DomainCombined = d.ID

Create clustered index cix_#Customers_FanID on #Customers (FanID)

--------------------------------------------------------------------------------------------------------------
--------------------------- Find events for customers to assess success or NOT of emails ---------------------
--------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#DomainStats') IS NOT NULL DROP TABLE #DomainStats

Select	a.DomainCombined,
		Count(*) as [Sent],
		Count(Distinct FanID) as Customers,
		Sum([Opened]) as [Opened],
		Sum([Clicks]) as [Clicks],
		Sum([Bounces]) as [Bounces],
		Sum([Unsubscribe]) as [Unsubscribe]
Into #DomainStats
From (
Select		c.DomainCombined,
			ee.FanID,
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
					When EmailEventCodeID in (303,301) then 1
					Else 0
				End) as Unsubscribe
From #Customers as c
inner join Relational.EmailEvent as ee
	on c.FanID = ee.FanID
inner join Relational.EmailCampaign as ec
	on ee.campaignkey = ec.Campaignkey
Where ec.SendDate Between @StartDate and @EndDate and
		ec.CampaignKey not like '%[a-z]%'
Group by c.DomainCombined,ee.FanID,ee.CampaignKey
) as a
Group by a.DomainCombined

--------------------------------------------------------------------------------------------------------------
--------------------------------- Produce final stats in form suited for report ------------------------------
--------------------------------------------------------------------------------------------------------------
Select dg.DomainGroup,
		ds.Sent,
		ds.Customers,
		ds.Opened,
		ds.Clicks,
		ds.Bounces,
		ds.Unsubscribe
from #DomainStats as ds
inner join #DomainGroups as dg
	on dg.ID = ds.DomainCombined