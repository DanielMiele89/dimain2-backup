CREATE Procedure [Staging].[R_0122_nFIPartnersNo_Valid_Matcher] (@StartDate DATE)
As

DECLARE @SDate AS DATE
SET @SDate = @StartDate

select Distinct p.ID as PartnerID,
				p.Name as PartnerName,
				tv.Name as Matcher,
				MerchantAcquirer,
				I.StartDate as Offer_StartDate,
				i.EndDate as Offer_EndDate,
				i.IronOfferName,
				c.ClubName,
				ps.Name as PartnerStatus
from nfi.relational.IronOffer as i
inner join nfi.relational.club as c
	on i.ClubID = c.clubid
inner join slc_report.dbo.partner as p
	on i.partnerID = p.ID
inner join slc_report.dbo.PartnerStatus as ps
	on p.Status = ps.ID
inner join slc_report.dbo.TransactionVector as tv
	on p.Matcher = tv.ID
Where	MerchantAcquirer = 'Other' and
		tv.ID not in (10,11,12,19,32,41)
		and StartDate >= @StartDate and
		IsSignedOff = 1
Order by p.Name

