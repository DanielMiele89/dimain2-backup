/*
Author:		Stuart Barnley
Date:		23 August 2013
Purpose:	Count offer audiences for RBS report
Notes:		As discussed with Kim 2 May 2012 for RBS meeting; their key concern; number of non base offers available to
			activated customers.
			
Amendment:	Amended to use Relational version of IronOffer table and use continuation field
			21-01-2014 SB - Amended as report was crashing when ran in SSRS, greatly simplified with all references to
							Activate vs Un-Activated removed.
			23-05-2014 SB - Turned in SP
*/


Create Procedure Staging.SSRS_R0029_CustomerStats
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
		io.PartnerID,
		p.PartnerName
into	#Offer
from	Relational.IronOffer as io
inner join Relational.Partner p 
	on io.PartnerID = p.PartnerID
where	not io.IronOfferName in ('default collateral', 'above the line collateral', 'suppressed') and
		io.StartDate >= @StartDate and
		io.Continuation = 0
order by io.startdate asc
--(317 row(s) affected)

--get the non Base EPOCU Offer Members
if object_id('tempdb..#OfferMember') is not null drop table #OfferMember
select	Count(Distinct o.OfferID) as NumberOfOffers,
		iom.CompositeID
into	#OfferMember		
from	#Offer o
		inner join Relational.IronOfferMember iom on o.OfferID = iom.IronOfferID
		inner join Relational.Customer c on iom.CompositeID = c.CompositeID
Group by iom.CompositeID
--(2,186,821 row(s) affected)		

--Report Query
Select 0 as NumberOfOffers, (Select Count(*) from Relational.customer)-(Select Count(*) from #OfferMember) as NumberofCustomers
Union all
select	NumberOfOffers,
		count(1)			as NumberOfCustomers
from	#OfferMember
group by NumberOfOffers	
order by NumberOfOffers	 asc