

	CREATE PROCEDURE [WilliamA].[BrandAuditReview_ConsumerCombination_Updates]
	AS


	IF OBJECT_ID('tempdb..#UpdatedCombos') IS NOT NULL DROP TABLE #UpdatedCombos
select		ba.BrandID
		,	ba.Narrative
		,	ba.LocationCountry
		,	ba.MCCID
		,	i.suggestedBrandID
into #UpdatedCombos
from Sandbox.WilliamA.BrandAudit ba 
join Sandbox.WilliamA.[BrandAudit_UpdatedCombos_Import] i
on ba.idRow = i.idRow
AND ba.BrandID != i.suggestedBrandID 

--Warehouse Updates

update  cc
set cc.BrandID = uc.suggestedBrandID
from Warehouse.Relational.ConsumerCombination cc
join #UpdatedCombos uc
on cc.BrandID = uc.BrandID
AND CC.Narrative = uc.Narrative
AND cc.LocationCountry = uc.LocationCountry
AND cc.MCCID = uc.MCCID

--Virgin Updates

update  cc
set cc.BrandID = uc.suggestedBrandID
from WH_Virgin.Trans.ConsumerCombination cc
join #UpdatedCombos uc
on cc.BrandID = uc.BrandID
AND CC.Narrative = uc.Narrative
AND cc.LocationCountry = uc.LocationCountry
AND cc.MCCID = uc.MCCID

--Visa Updates

update  cc
set cc.BrandID = uc.suggestedBrandID
from WH_Visa.Trans.ConsumerCombination cc
join #UpdatedCombos uc
on cc.BrandID = uc.BrandID
AND CC.Narrative = uc.Narrative
AND cc.LocationCountry = uc.LocationCountry
AND cc.MCCID = uc.MCCID




