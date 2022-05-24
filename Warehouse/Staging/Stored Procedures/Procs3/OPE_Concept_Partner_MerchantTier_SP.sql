CREATE Procedure [Staging].[OPE_Concept_Partner_MerchantTier_SP]  (@EmailDate date)
as
Begin
---------------------------------------------------------------------------
----------------------------Create table of Partner Tiers------------------
---------------------------------------------------------------------------
if object_id('tempdb..#Partner_Tiers') is not null drop table #Partner_Tiers
Select  PartnerID,
		Case
			When PartnerID in (4447,4433) then 9
			Else Coalesce(Tier,9)
		End as Tier_Level
Into #Partner_Tiers
From
(select p.PartnerID,PartnerName,Coalesce(Tier,Partner_Tier_Level) as Tier
from Warehouse.Relational.Partner as p
Left Outer Join Warehouse.Relational.Master_Retailer_Table as MRT
	on p.PartnerID = mrt.PartnerID
Left Outer join Warehouse.[Relational].[Partner_Tier] as pt
	on p.PartnerID = pt.PartnerID

) as a
---------------------------------------------------------------------------------------------------------------
-----------------------------Delete table with individual scores for OfferLife---------------------------------
---------------------------------------------------------------------------------------------------------------
	if object_id('Staging.OPE_Concept_Partner_Merchant_Tier') is not null drop table Staging.OPE_Concept_Partner_Merchant_Tier

---------------------------------------------------------------------------
----------------------------Create table of Partner Tiers------------------
---------------------------------------------------------------------------
	Select	a.PartnerID,
			Coalesce(cs.Score,0) as Merchant_Tier
	Into Staging.OPE_Concept_Partner_Merchant_Tier
	From
	(Select  PartnerID,
			Case
				When MIN(Tier_Level) = 1 then 'Gold'
				When MIN(Tier_Level) = 2 then 'Silver'
				When MIN(Tier_Level) = 3 then 'Bronze'
				Else 'Unknown'
			End as Merchant_Tier
	From #Partner_Tiers as pt
	Group By PartnerID
	) as a
	Left Outer join Staging.OPE_ConceptScore as cs
		on	a.Merchant_Tier = cs.Value
	Left Outer join Staging.ope_Concept as c
		on cs.ConceptID = c.ConceptID
	Where c.ConceptName = 'Merchant_Tier'
End