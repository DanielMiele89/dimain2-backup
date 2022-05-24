/*
Author:		Stuart Barnley
Date:		22nd August 2013
Purpose:	Count offer audiences for RBS report
Notes:		As discussed with Kim 2 May 2012 for RBS meeting; their key concern; number of non base offers available to
			activated customers.
			
Amendment:	This version amended to use Relational.IronOffer rather than slc_report.dbo.IronOffer, remove partner base 
			offer tables because we can use continuation field
			21-01-2014 SB - Amended as running slowly, all references to activated ever or not have been removed		

			23-05-2014 SB - Turned to SP

			16-10-2017 SB - Amend to use SLC_Report
*/


Create Procedure [Staging].[SSRS_R0029_OfferStatsv1_1]
				 @StartDate Date
as

/*-------------------------------------------------------------------------------------------------
---------------------------Report 1 - Count Customers Against Each Offer---------------------------
---------------------------------------------------------------------------------------------------*/
 
--Find the offer IDs that are not Base EPOCU Offers
if object_id('tempdb..#Offer') is not null drop table #Offer
select	io.IronOfferID as OfferID,
		io.IronOfferName as OfferName,
		io.StartDate,
		io.EndDate, 
		io.TopCashbackRate,
		io.PartnerID,
		p.PartnerName
into	#Offer
from	Relational.IronOffer io
inner join Relational.Partner p 
	on io.PartnerID = p.PartnerID
where	not io.IronOfferName in ('default collateral', 'above the line collateral', 'suppressed') and
		io.StartDate >= @StartDate and
		io.continuation = 0
order by io.startdate asc

if object_id('tempdb..#OfferMember') is not null drop table #OfferMember
select	o.OfferID,
		Count(Distinct iom.CompositeID) as CustomerCount
into	#OfferMember		
from	#Offer o
		inner join SLC_Report.dbo.IronOfferMember iom on o.OfferID = iom.IronOfferID
		inner join Warehouse.Relational.Customer c on iom.CompositeID = c.CompositeID	
Group by o.OfferID

Select	o.OfferID,
		o.OfferName,
		o.StartDate,
		o.EndDate,
		o.PartnerID,
		o.TopCashBackRate,
		o.PartnerName,
		om.CustomerCount as ActivatedCount
from #Offer as o
inner join #OfferMember as om
	on o.OfferID = om.OfferID