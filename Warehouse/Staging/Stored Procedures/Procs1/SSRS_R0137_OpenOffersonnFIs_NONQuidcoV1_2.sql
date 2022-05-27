/*

	Author:		Stuart Barnley

	Date:		9th November 2016

	Purpose:	To list all offer eligible for nFis (non Quidco), that are NOT All Members Applied


*/

Create Procedure [Staging].[SSRS_R0137_OpenOffersonnFIs_NONQuidcoV1_2] (@Date Date)
With Execute as Owner
As


----------------------------------------------------------------------------------
-------------------------------Find list of offers--------------------------------
----------------------------------------------------------------------------------
--Declare @Date date = '2017-03-16'


select --p.PartnerID,
	p.PartnerName, c.ClubName,i.*
Into #Offers
From nFI.Relational.IronOffer as i
inner join nfi.Relational.Partner as p
	on i.PartnerID = p.PartnerID
inner join nfi.relational.club as c
	on i.ClubID = c.ClubID
where	startdate <= @Date and
		(EndDate is null or EndDate > @Date) and
		(IsSignedOff = 1 or StartDate > getdate()) and
		--IsAppliedToAllMembers = 0 and
		c.clubid <> 12
Order by ClubName,PartnerName,p.PartnerID

Select	o.*,
		s.LiveOffer,
		ShopperSegmentTypeID,
		Case
			When wo.IronOfferID is not null then 'Yes'
			Else 'No'
		End as WelcomeOffersTable,
		Case
			When a.IronOffer2nd is not null then 'Yes'
			Else 'No'
		End as SecondaryOfferTable
From #Offers as o
left Outer join nFI.[Segmentation].[ROC_Shopper_Segment_To_Offers] as s
	on o.ID = s.IronOfferID
Left Outer Join warehouse.Iron.WelcomeOffer as wo
	on o.ID = wo.IronOfferID
Left Outer Join nfi.[Selections].[Roc_Offers_Primary_to_Secondary] as a
	on o.id = a.IronOffer2nd
Order by o.ID