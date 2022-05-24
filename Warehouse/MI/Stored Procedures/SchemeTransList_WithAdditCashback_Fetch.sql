-- =============================================
-- Author:		JEA
-- Create date: 07/06/2013
--MODIFIED 08/07/2014
-- Description:	Fetches a list of scheme transactions for incremental load
-- =============================================
CREATE PROCEDURE [MI].[SchemeTransList_WithAdditCashback_Fetch] 

AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT s.SchemeTransID 
		, pt.FanID
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned AS Earnings
		, pt.AddedDate
		, p.BrandID
		, isnull(pt.AboveBase,0) AS AboveBase
		, pt.AddedDate As AddeDateTime
		, pt.IronOfferID
		, CAST(0 AS TINYINT) AS AdditionalCashbackAwardTypeID
	FROM Relational.PartnerTrans pt
		INNER JOIN Relational.[Partner] p on pt.PartnerID = p.PartnerID
		INNER JOIN MI.SchemeTransUniqueID s ON pt.MatchID = s.MatchID
	WHERE pt.EligibleForCashback = 1

	UNION ALL

	SELECT s.SchemeTransID
		, a.FanID
		, a.Amount AS Spend
		, a.CashbackEarned AS Earnings
		, a.AddedDate
		, CAST(COALESCE(p.BrandID,0) AS INT) AS BrandID
		, CAST(0 AS BIT) AS AboveBase
		, a.AddedDate AS AddedDateTime
		, CAST(NULL AS INT) AS IronOfferID
		, CAST(a.AdditionalCashbackAwardTypeID AS TINYINT) AS AdditionalCashbackAwardTypeID
	FROM Relational.AdditionalCashbackAward a
		INNER JOIN MI.SchemeTransUniqueID s ON a.FileID = s.FileID and a.RowNum = s.RowNum
		LEFT OUTER JOIN Relational.PartnerTrans pt ON a.MatchID = pt.MatchID
		LEFT OUTER JOIN Relational.[Partner] p ON pt.PartnerID = p.PartnerID

END