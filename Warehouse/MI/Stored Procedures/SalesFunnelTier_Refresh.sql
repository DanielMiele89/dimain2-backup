-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Ensures that all brands in the sales funnel have a corresponding tier
-- =============================================
CREATE PROCEDURE MI.SalesFunnelTier_Refresh 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @StartDate DATE = DATEADD(DAY, -4, DATEADD(YEAR, -1, GETDATE())), @EndDate DATE = DATEADD(DAY, -4, GETDATE())

    CREATE TABLE #Combinations(ConsumerCombinationID INT PRIMARY KEY, BrandID SMALLINT NOT NULL)
	CREATE TABLE #BrandSpend(BrandID SMALLINT PRIMARY KEY, Spend MONEY NOT NULL)

	INSERT INTO #Combinations(ConsumerCombinationID, BrandID)
	SELECT ConsumerCombinationID, BrandID
	FROM Relational.ConsumerCombination
	WHERE BrandID IN (SELECT DISTINCT f.BrandID
						FROM MI.SalesFunnel f
						LEFT OUTER JOIN MI.SalesFunnelTier t ON F.BrandID = t.BrandID
						WHERE t.BrandID IS NULL)

	INSERT INTO #BrandSpend(BrandID, Spend)
	SELECT c.BrandID, SUM(ct.Amount)
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combinations c ON ct.ConsumerCombinationID = c.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	GROUP BY c.BrandID

	INSERT INTO MI.SalesFunnelTier(BrandID, Tier)
	SELECT BrandID, CASE WHEN Spend > 150000000 THEN 1 WHEN Spend > 25000000 THEN 2 ELSE 3 END AS Tier
	FROM #BrandSpend

	DROP TABLE #Combinations
	DROP TABLE #BrandSpend

END
