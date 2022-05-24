/*
	
	Author:		Stuart Barnley

	Date:		29th December 2015

	Purpose:	To give some possible entries to be added to Staging.BrandMatch to
				make MIDI more effective. This is for brands that have no current
				entries
				
*/

CREATE Procedure Staging.SSRS_R0113_BrandsNotInBrandMatch
as
-----------------------------------------------------------------------------------------
--------------------------------Find Brands without entries------------------------------
-----------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
select b.BrandID,b.BrandName,bc.SectorName
Into #Brands
from Relational.Brand b with (Nolock)
Left Outer Join Staging.BrandMatch bm with (Nolock)
	on b.BrandID = bm.BrandID
inner join Relational.BrandSector as bc with (Nolock)
	on b.SectorID = bc.SectorID
Where bm.BrandID is null

-----------------------------------------------------------------------------------------
--------------------------------Find Brands without entries------------------------------
-----------------------------------------------------------------------------------------
Select	b.SectorName,
		b.BrandID,
		b.BrandName,
		left(cc.Narrative,15) as Narrative_25,
		Count(*) as RecordsMatched,
		m.MCC,
		m.MCCDesc
From warehouse.relational.consumercombination as cc with (Nolock)
inner join #Brands as b
	on cc.BrandID = b.BrandID
inner join warehouse.relational.MCCList as m with (Nolock)
	on cc.MCCID = m.MCCID
Where cc.BrandID <> 943 and cc.LocationCountry = 'GB'
Group by	b.SectorName,b.BrandID,b.BrandName,
			left(cc.Narrative,15),m.MCC,m.MCCDesc
		Having Count(*) > 8
Order by BrandName,BrandID,left(cc.Narrative,15),m.MCC