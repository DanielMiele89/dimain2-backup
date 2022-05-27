/*
	Author:			Stuart Barnley

	Date:			17th Match 2016

	Purose:			To return a list of customers that opened an email promoting and 
					particular MyRewards Merchant campaign

*/
CREATE Procedure [MI].[MyRewards_Campaign_EmailOpens] (@CSR varchar(30), @TableName varchar(200))
With execute as owner
As

--Select @CSR = 'FC029'

Declare @MinStartDate date, 
	@MaxEndDate date

-------------------------------------------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
if object_id('tempdb..#Offers') is not null drop table #Offers
Select	i.IronOfferID,
	i.StartDate,
	i.EndDate
Into	#Offers
From Relational.IronOffer as i with (nolock)
Inner join Relational.IronOffer_Campaign_HTM as a with (nolock)
	on i.IronOfferID = a.IronOfferID
Where ClientServicesRef = @CSR
-------------------------------------------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------

Set @MinStartdate = (Select Min(StartDate) From #Offers)
Set @MaxEndDate   = (Select Max(EndDate) From #Offers)

-------------------------------------------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
if object_id('tempdb..#CampaignKeys') is not null drop table #CampaignKeys
Select Distinct ec.CampaignKey,LionSendID
Into #CampaignKeys
From Relational.EmailCampaign as ec with (nolock)
inner join Relational.CampaignLionSendIDs as cls with (nolock)
	on ec.CampaignKey = cls.CampaignKey
Where 	ec.SendDate >= @MinStartDate and
	ec.SendDate < @MaxEndDate
-------------------------------------------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
if object_id('tempdb..#OfferMembers') is not null drop table #OfferMembers
Select 	lsc.FanID,
		lsc.LionSendID,
		lsc.IronOfferID
Into 	#OfferMembers
From Relational.LionSendComponent as lsc with (nolock)
inner join (Select Distinct LionSendID From #CampaignKeys) as ck
	on lsc.LionSendID = ck.LionSendID
inner join #Offers as o
	on lsc.IronOfferID = o.IronOfferID

-------------------------------------------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
if object_id('tempdb..#Opens') is not null drop table #Opens
Select 	Distinct
		om.FanID,
		om.IronOfferID,
		ee.CampaignKey
Into 	#Opens
From #OfferMembers as om
inner join #CampaignKeys as ck
	on om.LionSendID = ck.LionSendID
inner join Relational.emailevent as ee with (nolock)
	on ck.CampaignKey = ee.CampaignKey
Where 	om.FanID = ee.FanID and
	ee.EmailEventCodeID in (1301,605)
-------------------------------------------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
Declare @Qry nvarchar(max)
Set @Qry = '

Select	FanID,
		IronOfferID,
		Count(Distinct CampaignKey) as EmailsOpened
into	'+@TableName+'
from #Opens
Group by FanID,IronOfferID
'

Exec SP_ExecuteSQL @Qry