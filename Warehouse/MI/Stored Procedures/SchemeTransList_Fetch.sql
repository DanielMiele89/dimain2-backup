-- =============================================
-- Author:		JEA
-- Create date: 07/06/2013
-- Description:	Fetches a list of scheme transactions for incremental load
-- =============================================
CREATE PROCEDURE [MI].[SchemeTransList_Fetch] 

AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT pt.MatchID
		, pt.FanID
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned AS Earnings
		, pt.AddedDate
		, p.BrandID
		, isnull(pt.AboveBase,0) AS AboveBase
		, pt.AddedDate As AddeDateTime
		, pt.IronOfferID
	FROM Relational.PartnerTrans pt
		INNER JOIN Relational.[Partner] p on pt.PartnerID = p.PartnerID
	WHERE pt.EligibleForCashback = 1

END
