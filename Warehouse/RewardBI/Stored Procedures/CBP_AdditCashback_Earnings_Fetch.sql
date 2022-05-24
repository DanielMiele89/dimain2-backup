

-- =============================================
-- Author:		JEA
-- Create date: 03/09/2014
-- Description:	Retrieves CBP retailer transactions
-- for Reward BI population
-- =============================================
CREATE PROCEDURE [RewardBI].[CBP_AdditCashback_Earnings_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT a.CashbackEarned AS Earnings 
		, S.SchemeTransID AS SourceTransID
		, a.MatchID
		, a.FileID
		, a.RowNum
		, a.AddedDate
		, LEFT(t.[Description], 50) AS EarningType
		, CAST(0 AS MONEY) AS PublisherCommission
		, CAST(0 AS MONEY) AS RewardCommission
		
	FROM Relational.AdditionalCashbackAward a
	INNER JOIN MI.SchemeTransUniqueID s ON a.FileID = s.FileID AND a.RowNum = s.RowNum
	INNER JOIN Relational.AdditionalCashbackAwardType t ON a.AdditionalCashbackAwardTypeID = t.AdditionalCashbackAwardTypeID

END