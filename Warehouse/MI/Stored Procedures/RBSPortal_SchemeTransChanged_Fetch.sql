-- =============================================
-- Author:		JEA
-- Create date: 24/04/2014
-- Description:	Retrieves transactions that
-- have changed from the ref table
-- for RBS Portal Incremental Load
-- =============================================
CREATE PROCEDURE MI.RBSPortal_SchemeTransChanged_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

    SET ANSI_NULLS OFF

	SELECT MatchID, AddedDate
	FROM MI.RBSPortal_SchemeTrans_Check t
	INNER JOIN MI.RBSPortal_Customer_Change c ON t.FanID = c.FanID

	UNION ALL

	SELECT c.MatchID, c.AddedDate
	FROM MI.RBSPortal_SchemeTrans_Check c
	LEFT OUTER JOIN MI.RBSPortal_SchemeTrans_Ref r
		ON c.MatchID = r.MatchID
		AND c.FanID = r.FanID
		AND c.Spend = r.Spend
		AND c.Earnings = r.Earnings
		AND c.AddedDate = r.AddedDate
		AND c.BrandID = c.BrandID
		AND c.OfferAboveBase = c.OfferAboveBase
	LEFT OUTER JOIN MI.RBSPortal_Customer_Change cu
		ON c.FanID = cu.FanID
	WHERE r.MatchID IS NULL AND cu.FanID IS NULL

END
