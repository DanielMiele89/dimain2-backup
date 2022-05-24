-- =============================================
--- Author:		JEA
-- Create date: 13/01/2014
-- Description:	Returns highest single earning total since scheme launch
-- Specific report for Client Services
-- =============================================
CREATE PROCEDURE [MI].[RetailerHighestEarningFromLaunch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @StartDate DATETIME, @EndDate DATETIME

	SET @StartDate = '2013-08-08'  --launch - hardcoded
	SET @EndDate = DATEADD(MINUTE, -1,CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME))

	SELECT Earnings
	FROM
	(
		SELECT FanID, SUM(CashbackEarned) AS Earnings, ROW_NUMBER() OVER (ORDER BY SUM(CashbackEarned) DESC) AS EarnOrdinal
		FROM Relational.PartnerTrans
		WHERE TransactionDate BETWEEN @StartDate AND @EndDate
		GROUP BY FanID
	) e WHERE EarnOrdinal = 1

END