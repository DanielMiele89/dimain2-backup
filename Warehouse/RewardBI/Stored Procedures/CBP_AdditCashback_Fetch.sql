
-- =============================================
-- Author:		JEA
-- Create date: 05/09/2014
-- Description:	Retrieves CBP retailer transactions
-- for Reward BI population
-- =============================================
CREATE PROCEDURE [RewardBI].[CBP_AdditCashback_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT S.SchemeTransID AS SourceID
		, MAX(a.Amount) AS Spend
		, SUM(a.CashbackEarned) AS EarningsTotal
		, MIN(a.TranDate) AS TranDate
		, MIN(a.AddedDate) AS AddedDate
		, a.FanID AS CustomerID
		, CAST(1 AS INT) AS RetailerID
		, CAST('RBS-Funded Unbranded' AS VARCHAR(100)) AS RetailerName
		, CAST (1 AS TINYINT) AS PublisherID
		, CAST('RBSG' AS VARCHAR(50)) AS PublisherName
		, CAST(0 AS TINYINT) AS PaymentChannelID --FIXME
		, 0 AS IronOfferID
		, CAST(0 AS BIT) AS AboveBase
		, m.[Description] AS PaymentMethod
		, CAST(0 AS MONEY) AS PublisherCommission
		, CAST(0 AS MONEY) AS RewardCommission
		, SUM(a.CashbackEarned) AS RBSFunded
	FROM Relational.AdditionalCashbackAward a
	INNER JOIN MI.SchemeTransUniqueID S on a.FileID = s.FileID AND a.RowNum = s.RowNum
	INNER JOIN Relational.PaymentMethod m ON a.PaymentMethodID = m.PaymentMethodID
	WHERE a.MatchID IS NULL
	GROUP BY s.SchemeTransID, a.FanID, m.[Description]
	
END

