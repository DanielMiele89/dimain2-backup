/*
	Author:			Stuart Barnley
	
	Date:			2016-02-12
	
	Purpose:		This checks to make sure all new offers have associated members.

	Update:			N/A
	
*/

Create Procedure [iron].[OfferMemberAddition_PostChecks] (@SDate date)
As
Declare @StartDate date

Set @StartDate = @SDate


---------------------------------------------------------------------------------
---------------------------------Get a List of Offers----------------------------
---------------------------------------------------------------------------------
if object_id('tempdb..#offers') is not null drop table #offers
Select	i.ID as IronOfferID,
		i.Name as IronOfferName,
		p.ID as PartnerID,
		p.Name as PartnerName
Into #offers
From slc_report.dbo.IronOffer as i with (nolock)
inner join slc_report.dbo.IronOfferClub as c with (nolock)
	on i.ID = c.IronOfferID
inner join slc_report..Partner as p
	on i.PartnerID = p.ID
Where	startdate = @StartDate and
		c.clubid in (132,138)

---------------------------------------------------------------------------------
-------------------Check how many members have been assigned---------------------
---------------------------------------------------------------------------------

Select	o.IronOfferID,
		o.IronOfferName,
		o.PartnerID,
		o.PartnerName,
		Count(Distinct oma.CompositeID) as Members
From #offers as o with (nolock)
left outer join warehouse.iron.OfferMemberAddition as oma with (nolock)
	on o.IronOfferID = oma.IronOfferID
Group by o.IronOfferID,o.IronOfferName,o.PartnerID,o.PartnerName
Order by IronOfferID