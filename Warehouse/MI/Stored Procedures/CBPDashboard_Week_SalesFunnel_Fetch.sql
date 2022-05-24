-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Returns sales funnel information for the weekly CBP dashboard
-- =============================================
CREATE PROCEDURE MI.CBPDashboard_Week_SalesFunnel_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @Tiers TABLE(TierID TINYINT PRIMARY KEY, TierName VARCHAR(10) NOT NULL)

	INSERT INTO @Tiers(TierID, TierName)
	VALUES(1, 'Gold')
		, (2, 'Silver')
		, (3, 'Bronze')

	SELECT s.FunnelStatus, s.TierID, s.StatusDesc, s.TierName, COUNT(DISTINCT f.BrandID) AS ProspectCount
	FROM (SELECT s.ID AS FunnelStatus, s.StatusDesc, t.TierID, t.TierName 
				FROM MI.SalesFunnel_Status s
				CROSS JOIN @Tiers t
				WHERE S.ID != 10) s
	LEFT OUTER JOIN --always return an entry for all statuses for all tiers
	(
		SELECT f.BrandID, f.FunnelStatus, t.Tier
		FROM MI.SalesFunnel f
		INNER JOIN (SELECT BrandID, MAX([Date]) AS FinalDate  --return only the latest status of a brand
					FROM MI.SalesFunnel
					GROUP BY BrandID) c ON F.BrandID = C.BrandID AND f.[Date] = c.FinalDate
		INNER JOIN MI.SalesFunnelTier t ON f.BrandID = t.BrandID
	) f ON s.FunnelStatus = f.FunnelStatus AND S.TierID = F.Tier
	GROUP BY s.FunnelStatus, s.TierID, s.StatusDesc, s.TierName

END