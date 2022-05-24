-- =============================================
-- Author:		JEA
-- Create date: 27/10/2016
-- Description:	Checks partner warehouse table specifically
-- for entries that might be missing from the RBS
-- MI portal
-- =============================================
CREATE PROCEDURE [MI].[PartnersNotInPortal_LoyaltyOnly_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT P.BrandID
		, P.PartnerName AS BrandName
		, ISNULL(br.SectorID,0) AS SectorID
		, ISNULL(t.Tier,0) AS Tier
		, ISNULL(CASE T.Core WHEN 'Y' THEN 1 WHEN 'N' THEN 0 ELSE NULL END,0) AS IsCore
		, p.PartnerID
		, ISNULL(br.ChargeOnRedeem,0) AS RBSFunded
	FROM Relational.[partner] p
		LEFT OUTER JOIN Relational.Master_Retailer_Table t ON p.PartnerID = t.PartnerID
		LEFT OUTER JOIN Relational.Brand br ON p.BrandID = br.BrandID
		LEFT OUTER JOIN APW.PartnerAlternate a ON P.PartnerID = A.PartnerID
	WHERE P.PartnerID NOT IN (2527,4453,4488,4497,4498,4510,4521,4523,4535,4555,4578,4615,4685,1000000,1000001,1000002,1000003,1000004,1000005, 1000006, 1000007,4721,1000008,1000009,1000010)
	AND A.PartnerID IS NULL

	ORDER BY p.PartnerID

END