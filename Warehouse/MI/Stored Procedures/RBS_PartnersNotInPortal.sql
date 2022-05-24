-- =============================================
-- Author:		JEA
-- Create date: 30/07/2014
-- Description:	Returns partners yet to be added to MI_Dev (and therefore the live portal)
-- =============================================
CREATE PROCEDURE [MI].[RBS_PartnersNotInPortal]
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT P.BrandID
		, P.PartnerName AS BrandName
		, br.SectorID
		, t.Tier
		, CASE T.Core WHEN 'Y' THEN 1 WHEN 'N' THEN 0 ELSE NULL END AS IsCore
		, p.PartnerID
		, br.ChargeOnRedeem AS RBSFunded
	FROM Relational.[partner] p
		INNER JOIN MI.PartnersNotInMIPortal b on p.brandid = b.brandid
		LEFT OUTER JOIN Relational.Master_Retailer_Table t ON p.PartnerID = t.PartnerID
		LEFT OUTER JOIN Relational.Brand br ON p.BrandID = br.BrandID
	WHERE P.PartnerID != 4453
		AND P.PartnerID != 4488
		AND P.PartnerID != 4497
		AND P.PartnerID != 4498
	ORDER BY p.PartnerID

END