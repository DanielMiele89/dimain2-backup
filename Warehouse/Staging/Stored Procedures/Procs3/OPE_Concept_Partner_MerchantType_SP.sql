CREATE Procedure [Staging].[OPE_Concept_Partner_MerchantType_SP] (@EmailDate date)
as
Begin
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
	Where c.ConceptName = 'Merchant_Type'
---------------------------------------------------------------------------------------------------------------
--------------------------------------------Create Partner Values----------------------------------------------
---------------------------------------------------------------------------------------------------------------
--Declare @EmailDate date
--Set @EmailDate = 'Nov 06, 2014'
Select	p.PartnerID,
		p.partnerName,
		Case
			When	pob.PartnerID IS not null then 'Core'
			When	NCB.PartnerID IS not null then 'Non-Core'
			When	mrt.PartnerID IS not null and
					mrt.Core = 'N' then 'Campaign'
			When	poc.PartnerID IS not null then 'POC'
			Else 'Unknown'
		End as MerchantType
Into #MerchantTypes	
		
from Relational.Partner as p
Left Outer join Relational.PartnerOffers_Base as pob
	on	p.PartnerID = pob.PartnerID and
		pob.StartDate <= @EmailDate and
		(pob.EndDate is null or pob.EndDate >= @EmailDate)
Left Outer join Relational.Partner_NonCoreBaseOffer as ncb
	on p.PartnerID = ncb.PartnerID and
		ncb.StartDate <= @EmailDate and
		(ncb.EndDate is null or ncb.EndDate >= @EmailDate)
Left Outer join Relational.Master_Retailer_Table as mrt
	on p.PartnerID = mrt.PartnerID
Left Outer Join (Select Distinct PartnerID from relational.IronOffer as i 
					Where IronOfferName in ('exclusive') and (EndDate is null or EndDate >=  @EmailDate)) as poc
	on p.PartnerID = poc.PartnerID


---------------------------------------------------------------------------------------------------------------
-----------------------------Delete table with individual scores for OfferLife---------------------------------
---------------------------------------------------------------------------------------------------------------
	if object_id('Staging.OPE_Concept_Partner_Merchant_Type') is not null drop table Staging.OPE_Concept_Partner_Merchant_Type

---------------------------------------------------------------------------
----------------------------Create table of Partner Tiers------------------
---------------------------------------------------------------------------
	Select	Distinct
			mt.PartnerID,
			Coalesce(s.Score,0) as Merchant_Type
	Into Staging.OPE_Concept_Partner_Merchant_Type
	from #MerchantTypes as mt
	Left Outer join #Scores as s
		on mt.MerchantType = s.Value
End