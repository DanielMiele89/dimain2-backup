-- =============================================
-- Author: Suraj Chahal
-- Create date: 16/07/2014
-- Description: Checking the Collateral Email Links to ensure they have been entered correctly
-- =============================================
CREATE PROCEDURE [Staging].[SSRS_R0040_Partner_EmailLinkCheck]

AS
BEGIN
	SET NOCOUNT ON;

SELECT	p.PartnerID,
        p.PartnerName,
        i.IronOfferID,
        i.IronOfferName,
        CAST(i.StartDate AS DATE) as StartDate,
        CAST(i.EndDate AS DATE) as EndDate,
        MAX(CASE WHEN CollateralTypeID = 49 THEN [Text] ELSE '' END) as EmailImageLink,
        MAX(CASE WHEN CollateralTypeID = 51 THEN [Text] ELSE '' END) as EmailRetailerLink
FROM Warehouse.Relational.[Partner] p
INNER JOIN Warehouse.Relational.IronOffer i
	ON p.PartnerID = i.PartnerID
INNER JOIN slc_report..Collateral c
	ON i.IronOfferID = c.IronOfferID
WHERE	IronOfferName LIKE '%Default%'
	AND (EndDate IS NULL OR EndDate >= CAST(GETDATE() AS DATE))
GROUP BY p.PartnerID, p.PartnerName, i.IronOfferID, i.IronOfferName, i.StartDate, i.EndDate
ORDER BY IronOfferID


END