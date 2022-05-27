/*

	Author:		Stuart Barnley

	Date:		5th July 2017

	Purpose:	To indicate if we have duplicate offer segment offers

*/

Create Procedure Staging.[SSRS_R0137_Duplicate_ShopperSegmentOffers]
With Execute as owner
as
-------------------------------------------------------------------------------------------------------------------
-------------------------Check for duplicate Partner, Club and Shopper Segment Combinations------------------------
-------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#DuplicateOffers') IS NOT NULL DROP TABLE #DuplicateOffers
Select	i.PartnerID,
		i.ClubID,
		s.ShopperSegmentTypeID,
		Count(*) NumberofLiveOffers
Into #DuplicateOffers
From nfi.[Segmentation].[ROC_Shopper_Segment_To_Offers] as s
inner join nfi.relational.IronOffer as i
	on	s.IronOfferID = i.ID and
		s.LiveOffer = 1
Group by i.PartnerID,
		i.ClubID,
		s.ShopperSegmentTypeID
	Having Count(*) > 1

-------------------------------------------------------------------------------------------------------------------
--------------------------------------------Get information to populate report-------------------------------------
-------------------------------------------------------------------------------------------------------------------

Select	c.ClubID,
		c.ClubName,
		p.PartnerID,
		p.PartnerName,
		DO.ShopperSegmentTypeID
From #DuplicateOffers as DO
inner join nfi.relational.partner as p
	on DO.PartnerID = p.PartnerID
inner join nfi.relational.club as c
	on DO.ClubID = c.ClubID
Order by PartnerName,ClubName
