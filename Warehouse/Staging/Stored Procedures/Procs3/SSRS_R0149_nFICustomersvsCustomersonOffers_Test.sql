

Create procedure [Staging].[SSRS_R0149_nFICustomersvsCustomersonOffers_Test]
as 

/********************************************************************************************
** Name: R_0149 - nFI Scheme Customers vs Customers on Offers
** Desc: Returns the number of customers on a publisher  vs the number of customers on offers 
**		 broken down by retailer
** Auth: Zoe Taylor
** Date: 01/02/2017
*********************************************************************************************
** Change History
** ---------------------
** #No		Date		Author			Description 
** --		--------	-------			------------------------------------
** 1    
*********************************************************************************************/



-- ***********************************************************************************************
-- **			 get number of customers on the scheme by counting the fanid's in the			**
-- **						customer table and grouping by clubid 								**
-- ***********************************************************************************************
if object_id('tempdb..#schemecustomers') is not null drop table #schemecustomers 
select 
		cl.clubname, 
		cl.clubid, 
		count(distinct cu.fanid) [noofcustomers]
into #schemecustomers
from nfi.relational.customer cu
left join nfi.relational.club cl
		on cl.clubid = cu.clubid
where cu.status = 1
and cl.clubid <> 12
group by cl.clubname, cl.clubid



-- ***********************************************************************************************
-- **			 Gets the current live offers - excludes quidco and base offers					**
-- ***********************************************************************************************
if object_id('tempdb..#CurrentIronOffers') is not null drop table #CurrentIronOffers 
select distinct 
		io.clubid,  
		io.partnerid, 
		io.ID [IronOfferID],
		io.StartDate, io.EndDate
into #CurrentIronOffers
from nfi.relational.ironoffer io
where io.startdate <= getdate() and (io.enddate > getdate() or io.enddate is null)
and io.issignedoff = 1
and io.clubid <> 12
and (io.ironoffername not like '%base%' and io.ironoffername not like '%spare%')
and io.[IsAppliedToAllMembers] = 0




-- ***********************************************************************************************
-- **		Looks at the current live offers and looks for members currently on the offer		**
-- ***********************************************************************************************
if object_id('tempdb..#CustomersOnOffers') is not null drop table #CustomersOnOffers 
select cio.clubid, cio.PartnerID, isnull(count(distinct iom.CompositeID), 0) [NoOfCustomers]
into #CustomersOnOffers
from #CurrentIronOffers cio
left join SLC_Report.dbo.IronOfferMember iom
	on cio.IronOfferID = iom.IronOfferID
where iom.startdate <= getdate() and (iom.enddate > getdate() or iom.enddate is null)
group by cio.ClubID, cio.PartnerID




-- ***********************************************************************************************
-- **		 displays values from both queries above to compare number of customers				**
-- **					on scheme compared to number of customers on offers						**
-- ***********************************************************************************************
Select 
		p.partnername, 
		p.partnerid, 
		sc.clubname, 
		sc.noofcustomers [cust_on_scheme], 
		--cpo.IronOfferID, 
		sum(co.NoOfCustomers) [cust_on_offers],  
		sum(co.NoOfCustomers) - sc.noofcustomers [differencescheme/offers]
from #schemecustomers sc 
inner join #CustomersOnOffers co
		on co.ClubID = sc.ClubID
inner join nfi.relational.partner p
		on p.partnerid = co.partnerid
group by sc.clubname,sc.noofcustomers, p.partnername, p.partnerid--, cpo.IronOfferID
--having sum(co.NoOfCustomers) - sc.noofcustomers <> 0
order by p.PartnerName, sc.ClubName