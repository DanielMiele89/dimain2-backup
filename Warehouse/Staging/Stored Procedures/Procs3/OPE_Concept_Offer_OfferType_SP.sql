CREATE Procedure [Staging].[OPE_Concept_Offer_OfferType_SP] (@EmailSendDate Date)
as
---------------------------------------------------------------------------
----------------------------Create table of Partner Tiers------------------
---------------------------------------------------------------------------
if object_id('tempdb..#Scores') is not null drop table #Scores
Select  Value,
		Score
Into #Scores
From Staging.OPE_ConceptScore as cs
	inner join Staging.ope_Concept as c
		on cs.ConceptID = c.ConceptID
	Where c.ConceptName = 'Offer_Type'
-----------------------------------------------------------------------------
-----------------------------Set Offer_Type Values---------------------------
-----------------------------------------------------------------------------
if object_id('tempdb..#OfferType_Values') is not null drop table #OfferType_Values
Select	o.IronOfferID,
		Case
			When i.Continuation = 1 then 'Base'
			When ltrim(rtrim(i.IronOfferName)) = 'Base' then 'Base'
			When ct.IsTrigger = 1 then 'Trigger'
			When ctl.Description = 'Strategic Campaign' then 'Strategic'
			When ctl.Description like 'Tactical%' then 'Tactical'
			Else 'Unknown'
		End as Offer_Type,
		ct.CampaignTypeID
Into #OfferType_Values
from Staging.OPE_Offers_TobeScored as o
inner join Relational.IronOffer as i
	on o.IronOfferID = i.IronOfferID
Left Outer join Relational.IronOffer_Campaign_HTM as htm
	on i.IronOfferID = htm.IronOfferID
Left Outer join Staging.IronOffer_Campaign_Type as ct
	on htm.ClientServicesRef = ct.ClientServicesRef
left outer join Staging.IronOffer_Campaign_Type_Lookup as ctl
	on ct.CampaignTypeID = ctl.CampaignTypeID
Where	IsDefaultCollateral = 0 and
		IronOfferName not like '%Above the line%' and
		IronOfferName <> 'Spare'
		

---------------------------------------------------------------------------------------------------------------
-----------------------------Delete table with individual scores for OfferLife---------------------------------
---------------------------------------------------------------------------------------------------------------
	if object_id('Staging.OPE_Concept_Offer_Offer_Type') is not null drop table Staging.OPE_Concept_Offer_Offer_Type

-----------------------------------------------------------------------------
-----------------------------Set Offer_Type Scores---------------------------
-----------------------------------------------------------------------------
Select	mt.IronOfferID,
		Coalesce(s.Score,0) as Offer_Type
	Into Staging.OPE_Concept_Offer_Offer_Type
	from #OfferType_Values as mt
	Left Outer join #Scores as s
		on mt.Offer_Type = s.Value