/*
	
	Author:			Stuart Barnley
	Date:			9th December 2014
	
	Description:	This builds a table of Exposures for each offer
	
*/
CREATE Procedure [Staging].[OPE_Concept_OfferSoW_Offer_OfferExposure_SP_Test] (@EmailSendDate Date)
As

--Declare @EmailSendDate date
--Set @EmailSendDate = 'Nov 06, 2014'
Declare @LionSendID_Min int
Set @LionSendID_Min = 
	(select Max(LionSendID)
	 From Warehouse.Relational.CampaignLionSendIDs as cls
	 inner join Warehouse.Relational.EmailCampaign as ec
			on cls.CampaignKey = ec.CampaignKey
	 Where ec.SendDate < @EmailSendDate)
---------------------------------------------------------------------------------------
------------------Create Table of Partners who have been Sow'ed------------------------
---------------------------------------------------------------------------------------

if object_id('tempdb..#T1') is not null 
								drop table #T1
Select PartnerID 
Into #T1
from Staging.OPE_SOWRunDate

---------------------------------------------------------------------------------------
--------------------------------- Create Table of Offers ------------------------------
---------------------------------------------------------------------------------------
if object_id('tempdb..#Offers') is not null 
								drop table #Offers
Select s.IronOfferID,
		i.PartnerID,
		ROW_NUMBER() OVER(ORDER BY s.IronOfferID ) AS RowNo
into #Offers
From Staging.OPE_Offers_TobeScored as s
inner join Relational.IronOffer as i
	on s.IronOfferID = i.IronOfferID
Where Continuation = 0
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
Select o.IronOfferID,a.HTMID
Into #OfferHTM
from 
(Select HTMID 
from warehouse.relational.HeadroomTargetingModel_Groups as g
Where HTMID >= 10
Union All
Select 0 as HTMID
) as a
,#Offers as o



---------------------------------------------------------------------------------------
--------------------------------- Create Table of Offers ------------------------------
---------------------------------------------------------------------------------------
	if object_id('tempdb..#OfferMembers') is not null 
								drop table #OfferMembers
	Select	s.IronOfferID,
			Case
				When t.PartnerID IS null then 0
				Else SoW.HTMID 
			End as HTMID,
			Count(Distinct iom.CompositeID) as Members,
			Count(lsc.CompositeID) as Exposures
	into #OfferMembers
	from #Offers as s
	inner join Relational.IronOffer as i
		on	s.IronOfferID = i.IronOfferID and
			i.Continuation = 0
	Left Outer join Relational.IronOfferMember as iom
		on	s.IronOfferID = iom.IronOfferID
	Inner join warehouse.relational.Customer as c
		on	iom.CompositeID = c.CompositeID
	Left Outer join relational.LionSendComponent_Test as lsc
	on	s.IronOfferID = lsc.IronOfferID and
		lsc.FanID = c.FanID and
		lsc.LionSendID <= @LionSendID_Min
	Left Outer join Warehouse.Relational.ShareOfWallet_Members as SoW
		on	c.FanID = SoW.FanID and
			i.PartnerID = SoW.PartnerID and
			SoW.EndDate is null
	left Outer Join #T1 as t
		on  i.PartnerID = t.PartnerID
	Where (t.PartnerID is null or SoW.FanID is not null)
	Group By s.IronOfferID,
			Case
				When t.PartnerID IS null then 0
				Else SoW.HTMID 
			End
---------------------------------------------------------------------------------------
------------------------------- Create Table of Exposure Rates ------------------------
---------------------------------------------------------------------------------------
if object_id('tempdb..#ExposurePct') is not null 
								drop table #ExposurePct
Select *
Into #ExposurePct
from 
(
Select	e.IronOfferID,
		HTMID,
		Members,
		Exposures,
		Round((Cast(Exposures as real)/Members)*4,0)/4 as OfferExposures
from #OfferMembers as e
) as a
Order by IronOfferID
---------------------------------------------------------------------------------------
------------------------- Create Concept Table of Exposure Scores ---------------------
---------------------------------------------------------------------------------------
if object_id('Staging.OPE_Concept_OfferSoW_Offer_Exposure_History') is not null 
								drop table Staging.OPE_Concept_OfferSoW_Offer_Exposure_History

Select	oh.IronOfferID,
		oh.HTMID,
		Case
			When ep.IronOfferID IS null then 100
			When ope.Value IS null then 0
			Else ope.Score
		End as Offer_Exposure_History
Into Staging.OPE_Concept_OfferSoW_Offer_Exposure_History
From #OfferHTM as oh
Left Outer join #ExposurePct as ep
	 on	oh.IronOfferID = ep.IronOfferID and
		oh.HTMID = ep.HTMID	
Left Outer join Staging.OPE_ConceptScore as ope
	on	ep.OfferExposures = Cast(ope.Value as SmallMoney) and
		ope.ConceptID = 8