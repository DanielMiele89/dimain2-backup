--LionSendID	Offer Type	Offer Slot	Partner Name	IronOfferID	Email
/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0017.

					This pulls out a sample set of customers who have been loaded
					for the weekly email

Update:			N/A
					
*/
CREATE Procedure [Staging].[SSRS_R0017_SampleMembers_V1_1]
				 @LionSendID Int
as

if object_id('tempdb..#PO') is not null drop table #PO
select	DISTINCT
	PartnerName,i.Continuation,IronOfferID
Into #PO
from Lion.NominatedLionSendComponent as nlsc
inner join relational.IronOffer as i
	on nlsc.ItemID = i.IronOfferID
inner join Relational.Partner as p
	on i.PartnerID = p.PartnerID
Where nlsc.LionSendID = @LionSendID
--Group by PartnerName,i.Continuation

Select	a.LionSendID,
		a.OfferType,
		a.ItemRank,
		a.PartnerName,
		a.IronOfferID,
		a.Email
From
(Select	nlsc.LionSendID,
		Case
			When Continuation = 1 then 'Base Offer'
			Else 'Non Base Offer'
		End as OfferType,
		nlsc.ItemRank,
		p.PartnerName,
		p.IronOfferID,
		c.Email,
		ROW_NUMBER() OVER(PARTITION BY p.IronOfferID ORDER BY c.Email) AS RowNo
from Lion.NominatedLionSendComponent as nlsc
inner join Relational.Customer as c
	on nlsc.CompositeId = c.CompositeID
inner join #po as p
	on nlsc.ItemID = p.IronOfferID
Where nlsc.LionSendID = @LionSendID
) as a
Where RowNo <= 5