/*

	Author:		Stuart Barnley

	Date:		22nd June 2016

	Description:	For a partner it pulls list of IronOffers as well as their related Offer and Campaign Info.
					This is used purely for internal checking
*/ 


CREATE Procedure Staging.SSRS_R0125_Partner_nFI_OfferCampaign_Checking (
																		@PID int, -- This is the ID of the partner to be assessed
																		@SDate date -- this is the date from which offers should be reviewed
																	   )
As

--Declare @PID int,@SDate date

--Set @PID = 4548, @SDate = '2016-01-2015'
----------------------------------------------------------------------------------------------------
----------------------------------Find the relevant IronOffers--------------------------------------
----------------------------------------------------------------------------------------------------
Select	c.ID						as CampaignID,
		c.CampaignRef,
		o.ID						as OfferID,
		t.TypeDescription,
		cl.ClubName,
		i.ID						as IronOfferID,
		i.IronOfferName,
		i.StartDate,
		i.EndDate,
		i.IsAppliedToAllMembers,
		i.PartnerID,
		p.PartnerName
Into #t1
from Relational.IronOffer as i
inner join Relational.Offer as o
	on i.OfferID = o.id
inner join Relational.OfferType as t
	on o.OfferTypeID = t.ID
inner join Relational.Campaign as c
	on o.CampaignID = c.ID
inner join Relational.Partner as p
	on i.PartnerID = p.PartnerID
inner join Relational.Club as cl
	on i.ClubID = cl.ClubID
Where	p.PartnerID = @PID and
		i.StartDate >= @SDate

----------------------------------------------------------------------------------------------------
-----------------------------------Display the contents of the table--------------------------------
----------------------------------------------------------------------------------------------------

Select * 
From #t1
Order by CampaignID,OfferID,IronOfferID