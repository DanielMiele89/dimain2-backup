/*
	Author:		Stuart Barnley
	Date:		21-01-2014

	Purpose:	Created to return a list of all Above base offers, rates and member counts

	Notes:		21-01-2014 SB - Latest version - Would not run on SSRS, it kept crashing, has 
								been restructured to deal with the growing population causing 
								slow down.

				23-05-2014 SB - Turned in to SP

Declare @StartDate date
Set @StartDate = 'Aug 01, 2013'
*/
Create Procedure Staging.SSRS_R0027_AboveBase_Offers
				 @StartDate Date
as
-------------------------------------------------------------------
----------------Find List of Above Base Offers---------------------
-------------------------------------------------------------------
if object_id('tempdb..#Offers') is not null drop table #Offers
select	i.IronOfferID,
	p.PartnerName,
	i.IronOfferName,
	i.TopCashbackRate as CashbackRate,
	i.StartDate,
	i.EndDate
into #Offers
from warehouse.relational.ironoffer as i
inner join warehouse.relational.partner as p
	on i.PartnerID = p.PartnerID
Where	i.IsTriggerOffer = 0 and i.Abovebase = 1
	AND i.StartDate >=@StartDate
Order by i.IronOfferID
-------------------------------------------------------------------
----------------Find List of Above Base Offers---------------------
-------------------------------------------------------------------
Select	i.PartnerName,
		i.IronOfferName,
		i.CashbackRate,
		Count (Distinct CompositeID) as NoOfCustomers,
		i.StartDate,
		i.EndDate
from #Offers as i
inner join slc_report.dbo.ironoffermember as iom
	on i.IronOfferID = iom.Ironofferid
Group by i.IronOfferID,PartnerName,IronOfferName,i.StartDate,i.EndDate,i.CashbackRate