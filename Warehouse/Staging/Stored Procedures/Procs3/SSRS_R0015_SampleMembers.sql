/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0015.

					This pulls out a sample of 5 customers for each of the offes in 
					Iron.NominatedOfferMember (Targeted Offers) and 
					Iron.TriggerOfferMember (Trigger Offers) per Bank

Update:			N/A
					
*/
CREATE Procedure Staging.SSRS_R0015_SampleMembers
				 @StartDate Date
as
Select * from 
(select 'Targeted' as OfferType,
		io.ID as IronOfferID,
		io.name as OfferName,
		io.StartDate,
		io.EndDate,
		nom.CompositeID,
		c.email,
		c.ClubID,
		ROW_NUMBER() OVER(PARTITION BY io.id,c.ClubID ORDER BY newid() DESC) AS RowNo
from slc_report.dbo.IronOffer as io
Inner join Warehouse.iron.NominatedOffermember as nom
	on io.ID = nom.IronOfferID
inner join warehouse.relational.Customer as c
	on nom.CompositeID = c.CompositeID
Where io.startdate >= @StartDate
) as a
where RowNo <= 5
--Order by IronOfferID,RowNo
Union all
Select * from 
(select 'Trigger' as OfferType,
		io.ID as IronOfferID,
		io.name as OfferName,
		nom.StartDate,
		nom.EndDate,
		nom.CompositeID,
		c.email,
		c.ClubID,
		ROW_NUMBER() OVER(PARTITION BY io.id,c.ClubID ORDER BY newid() DESC) AS RowNo
from slc_report.dbo.IronOffer as io
Inner join Warehouse.iron.TriggerOfferMember as nom
	on io.ID = nom.IronOfferID
inner join warehouse.relational.Customer as c
	on nom.CompositeID = c.CompositeID
Where nom.startdate >= @StartDate
) as a
where RowNo <= 5
Order by IronOfferID,RowNo