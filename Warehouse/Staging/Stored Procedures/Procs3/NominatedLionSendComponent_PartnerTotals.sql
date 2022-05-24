--Use Warehouse
--Declare @NatWest int, @RBS int
--Set @NatWest = 199
--Set @RBS = 198
/*
	Author:		Stuart Barnley
	Date:		11-06-2014

	Purpose:	This produces Partner level offer counts from the LionSends

*/
Create Procedure Staging.NominatedLionSendComponent_PartnerTotals 
			@RBS int, @NatWest int
as
----------------------------------------------------------------------------------
-------------------------------Find Offer Counts----------------------------------
----------------------------------------------------------------------------------
if object_id('tempdb..#POC') is not null drop table #POC
Select PartnerID, PartnerName, [NatWest],[RBS]
Into #POC
from
(
Select  p.PartnerID,
		p.PartnerName,
		Case
			When LionSendID = @NatWest then 'NatWest'
			Else 'RBS'
		End as Bank,
		Count(*) as CustomerCount
from Lion.NominatedLionSendComponent as nlsc
inner join Relational.IronOffer as i
	on nlsc.ItemID = i.IronOfferID
inner join Relational.partner as p
	on i.PartnerID = p.PartnerID
Where LionSendID in (198,199)
Group by p.PartnerID,
		 p.PartnerName,
		Case
			When LionSendID = @NatWest then 'NatWest'
			Else 'RBS'
		End 
) as a
Pivot
( Sum(CustomerCount)
For Bank in ([NatWest],[RBS])
) PivotTable
Order by PartnerName
----------------------------------------------------------------------------------
-----------------Display Offer Counts for both Banks and Totals-------------------
----------------------------------------------------------------------------------

SELECT  P.PartnerID,
		p.PartnerName,
		Coalesce(a.NatWest,0) as NatWest,
		Coalesce(a.RBS,0) as RBS,
		Coalesce(a.NatWest+a.RBS,0) as Total
FROM Warehouse.Staging.BrandCompetitor_String w
inner join warehouse.relational.partner as p
	on w.BrandID = p.BrandID
Left Outer join #POC as a
	on p.PartnerID = a.PartnerID
	Order by PartnerName