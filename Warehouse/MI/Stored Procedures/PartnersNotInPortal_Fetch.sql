-- =============================================
-- Author:		JEA
-- Create date: 12/10/2016
-- Description:	Returns partners yet to be added to MI_Dev (and therefore the live portal)
-- =============================================
CREATE PROCEDURE [MI].[PartnersNotInPortal_Fetch]
	WITH EXECUTE AS 'ProcessOp'
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
		, P.nFI
	FROM (	SELECT p.PartnerID, p.PartnerName, p.BrandID, CAST('' AS varchar(3)) AS nFI
			FROM Relational.[partner] p
			UNION ALL
			SELECT p.PartnerID, p.PartnerName, CAST(0 AS smallint) as BrandID, CAST('nFI' AS varchar(3)) AS nFI
			FROM nFI.Relational.[partner] p
			LEFT OUTER JOIN Relational.[Partner] pr ON p.PartnerID = pr.PartnerID
			WHERE pr.PartnerID IS NULL) P
		LEFT OUTER JOIN Relational.Master_Retailer_Table t ON p.PartnerID = t.PartnerID
		LEFT OUTER JOIN Relational.Brand br ON p.BrandID = br.BrandID
		LEFT OUTER JOIN APW.PartnerAlternate a ON P.PartnerID = A.PartnerID
	WHERE P.PartnerID NOT IN (4453,4488,4497,4498,4510,4521,4535,4555, 4615,1000000,1000001,1000002,1000003,1000004,1000005, 1000006,1000007,1000008,1000009,1000010)
	AND A.PartnerID IS NULL

	ORDER BY p.PartnerID

END