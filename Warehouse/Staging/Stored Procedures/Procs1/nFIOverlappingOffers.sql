
CREATE PROCEDURE staging.nFIOverlappingOffers
as BEGIN


if object_id('tempdb..#offers') is not null drop table #offers
Select ID as IronOfferID
Into #Offers
From slc_report..IronOffer
where id in (
13835
)

select io.*
from SLC_Report..IronOffer IO
inner join #Offers O on io.ID=o.IronOfferID


Delete from Warehouse.iron.OfferMemberClosure 
where IronOfferID in 
		(Select IronOfferID from #Offers)


Insert into Warehouse.iron.OfferMemberClosure
Select	'2018-01-11 23:59:59.000' as EndDate,
		iom.IroNofferID,
		iom.CompositeID,
		iom.StartDate
From slc_report.dbo.IronOfferMember as iom
inner join slc_report.dbo.fan as f
	on iom.compositeID = f.CompositeID
Inner join #Offers o
	on o.IronOfferID = iom.IronOfferID
Where f.SourceUID in ('2C6ZJPZXvipWjHGPn2GD')
		

Select *
From Warehouse.iron.OfferMemberClosure omc
Inner join #Offers o
	on o.IronOfferid = omc.IronOfferID


Insert into Warehouse.Iron.OfferProcessLog
Select	o.IronOfferID,
		1 IsUpdate,
		0 Processed,
		null as ProcessedDate
From #Offers o

Select * 
From Warehouse.Iron.OfferProcessLog
Order by 1 Desc

select *
from slc_repl..IronOfferMember
where ironofferid = 13835


END