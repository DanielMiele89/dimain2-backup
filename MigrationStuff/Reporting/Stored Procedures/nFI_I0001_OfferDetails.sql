CREATE PROCEDURE [Reporting].[nFI_I0001_OfferDetails] (@PartnerID int, @CampaignRef Varchar(15))
WITH EXECUTE AS OWNER
As
select	i.ID as IronOfferID,
		i.StartDate,
		i.EndDate,
		i.IsSignedOff,
		i.PartnerID,
		p.PartnerName,
		i.OfferID,
		t.TypeDescription,
		c.CampaignRef,
		Max(Case
				When pcr.TypeID = 1 and Status = 1 then CommissionRate
				Else 0
			End) as Top_Cashback,
		Max(Case
				When pcr.TypeID = 2 and Status = 1 then CommissionRate
				Else 0
			End) as Top_Commission
from relational.ironoffer as i
inner join relational.offer as o
	on i.OfferID = o.id
inner join Relational.Campaign as c
	on o.CampaignID = c.id
inner join relational.OfferType as t
	on o.OfferTypeID = t.ID
Left Outer join relational.IronOffer_PartnerCommissionRule as pcr
	on i.ID = pcr.IronOfferID
inner join relational.partner as p
	on i.PartnerID = p.PartnerID
--Where PartnerID in (4319)
Where (p.PartnerID = @PartnerID or c.CampaignRef = @CampaignRef)
Group by i.ID,i.StartDate,i.EndDate,i.IsSignedOff,i.PartnerID,p.PartnerName,i.OfferID,t.TypeDescription,c.CampaignRef
Order by CampaignRef