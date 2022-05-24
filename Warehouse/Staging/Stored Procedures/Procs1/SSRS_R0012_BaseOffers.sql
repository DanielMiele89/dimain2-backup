/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0012.

					This pulls off the data related to the base offers so they
					can be passed on for checking, the data pulled includes the
					Ad Space weightings.

	Update:			N/A
					
*/
Create Procedure Staging.SSRS_R0012_BaseOffers
as

if object_id('tempdb..#Offers') is not null drop table #Offers

Select 	i.IronOfferID,
	i.IronOfferName,
	p.PartnerID,
	p.PartnerName,
	i.StartDate,
	i.EndDate,
	Max(Case
		When pcr.Status = 1 and pcr.TypeID = 1 then CommissionRate
		Else Null
	    End) as CashbackRate,
	Max(Case
		When pcr.Status = 1 and pcr.TypeID = 2 then CommissionRate
		Else Null
	    End) as CommissionRate,
	i.IsSignedOff,
	i.[AreEligibleMembersCommitted],
	i.Clubs
into #Offers
from Warehouse.relational.ironoffer as i
Left Outer join slc_report.dbo.PartnerCommissionRule as pcr
	on i.IronOfferID = pcr.RequiredIronOfferID
inner join Warehouse.relational.partner as p
	on i.PartnerID = p.PartnerID 
Where Continuation = 1
Group by  i.IronOfferID,i.IronOfferName,p.PartnerID,p.PartnerName,
	  i.StartDate,i.EndDate,i.IsSignedOff,i.[AreEligibleMembersCommitted],i.Clubs
----------------------------------------------------------------------------------------
-----------------------------Add Ad Weightings to data set------------------------------
----------------------------------------------------------------------------------------
Select o.*,
		Max(Case	
				When a.AdSpaceID = 8 then a.[Weight] 
				Else -1
			End) as [Hero_Retail_Banner_8],
		Max(Case	
				When a.AdSpaceID = 15 then a.[Weight] 
				Else -1
			End) as [Retail_Recommendation_Item_15],
		Max(Case	
				When a.AdSpaceID = 23 then a.[Weight] 
				Else -1
			End) as [Regular_Offer_23]
from #Offers as o
inner join slc_report.dbo.IronOfferAdSpace as a
	on o.IronOfferID = a.IronOfferID and a.AdSpaceID in (8,15,23)
Group by o.IronOfferID,o.IronOfferName,o.PartnerID,o.PartnerName,o.StartDate,
		 o.EndDate,o.CashbackRate,o.CommissionRate,o.IsSignedOff,
		 o.[AreEligibleMembersCommitted],o.Clubs