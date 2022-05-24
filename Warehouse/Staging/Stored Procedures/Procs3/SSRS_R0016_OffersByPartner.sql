/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0016.

					This is part of the Pre SFD Upload Data Assessment

	Update:			N/A
						
*/
Create Procedure Staging.SSRS_R0016_OffersByPartner
				 @LionSendID Int
as

Select Distinct 
		P.PartnerID,
		P.PartnerName,
		Case
			When a.PromotedBase  IS null and pbo.Partnerid is not null then 'N'
			When a.PromotedBase  IS null and pbo.Partnerid is null then 'N/A'
			Else a.PromotedBase
		End as PromotedBase,
		Coalesce(a.PromotedOther,'N') as PromotedOther
from warehouse.relational.Partner as p
left outer join 
(SELECT	DISTINCT 
	LionSendID,
	io.PartnerID,
	p.PartnerName,
	MAX(CASE WHEN io.PartnerID = pbo.PartnerID AND io.IronOfferID = pbo.OfferID THEN 'Y' 
		WHEN  io.IronOfferID <> pbo.OfferID THEN 'N'
		ELSE 'N/A' 
	END) as PromotedBase,
	MAX(CASE  WHEN (io.IronOfferID <> pbo.OfferID AND io.IronOfferID NOT IN (1842,1859)) OR pbo.PartnerID IS NULL THEN 'Y'
		ELSE 'N' 
	END) as PromotedOther
FROM Warehouse.lion.NominatedLionSendComponent nl
INNER JOIN Warehouse.Relational.IronOffer io
	ON nl.ItemID = io.IronOfferID
INNER JOIN Warehouse.Relational.Partner p
	ON io.PartnerID = p.PartnerID
LEFT OUTER JOIN	 (
		SELECT	DISTINCT 
			PartnerID,
			OfferID
		FROM Warehouse.Relational.partneroffers_base) pbo
	ON io.PartnerID = pbo.PartnerID
WHERE	LionSendID = @LionSendID
GROUP BY LionSendID, io.PartnerID, p.PartnerName
) as a
	on p.PartnerID = a.PartnerID
left outer join warehouse.relational.partneroffers_base as pbo
	on p.Partnerid = pbo.PartnerID
left outer join warehouse.relational.Partner_CBPDates as cbpDates
	on p.PartnerID = cbpdates.Partnerid
Where a.PartnerID is not null or cbpDates.Scheme_EndDate is null
Order by PartnerName