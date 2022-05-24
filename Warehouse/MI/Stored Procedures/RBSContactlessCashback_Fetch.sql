-- =============================================
-- Author:		JEA
-- Create date: 19/10/2014
-- Description:	Retrieves contactless cashback
-- =============================================
CREATE PROCEDURE MI.RBSContactlessCashback_Fetch
	WITH EXECUTE AS OWNER 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT a.FileID
		, a.RowNum
		, a.FanID
		, CASE WHEN pt.PartnerID IS NULL THEN 1 WHEN b.ChargeOnRedeem = 1 THEN 2 ELSE 3 END AS TranTypeID
		, a.Amount
		, a.CashbackEarned AS Earnings
		, a.AddedDate
	FROM Relational.AdditionalCashbackAward a
		LEFT OUTER JOIN Relational.PartnerTrans pt ON a.MatchID = pt.MatchID
		LEFT OUTER JOIN Relational.[Partner] p ON pt.PartnerID = p.PartnerID
		LEFT OUTER JOIN Relational.Brand b ON p.BrandID = b.BrandID
	WHERE a.AdditionalCashbackAwardTypeID = 1

END
