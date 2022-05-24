-- =============================================
-- Author:		JEA
-- Create date: 06/06/2016
-- Description:	Fetches retailer data for calculating control stats
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_ControlRetailerSpend_Load]

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @PartnerID INT, @BrandID SMALLINT, @StartDate DATE, @EndDate DATE

	--set start and end dates to those of the most recent complete calendar month
	SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @EndDate = DATEADD(DAY, -1, @StartDate)
	SET @StartDate = DATEADD(MONTH, -1, @StartDate)

	--select the lowest partner ID and iterate up through the loop
	SELECT @PartnerID = MIN(PartnerID) FROM APW.ControlRetailers
	SELECT @BrandID = BrandID FROM APW.ControlRetailers WHERE PartnerID = @PartnerID

	WHILE @PartnerID IS NOT NULL
	BEGIN

		--gather the combos of each brand
		CREATE TABLE #Combos(ConsumerCombinationID INT PRIMARY KEY)

		INSERT INTO #Combos(ConsumerCombinationID)
		SELECT ConsumerCombinationID
		FROM Relational.ConsumerCombination
		WHERE BrandID = @BrandID

		--insert record for all spend
		INSERT INTO APW.ControlRetailerSpend(PartnerID
			, PseudoActivatedMonthID
			, IsOnline
			, SpenderCount
			, TranCount
			, Spend)
		SELECT @PartnerID
			, a.PseudoActivatedMonthID
			, NULL AS IsOnline
			, COUNT(DISTINCT a.CINID) AS SpenderCount
			, COUNT(*) AS TranCount
			, SUM(ct.Amount) AS Spend
		FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN APW.ControlAdjusted a ON ct.CINID = a.CINID
		INNER JOIN #Combos c ON ct.ConsumerCombinationID = c.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
		GROUP BY a.PseudoActivatedMonthID
		ORDER BY PseudoActivatedMonthID

		--insert record for offline spend
		INSERT INTO APW.ControlRetailerSpend(PartnerID
			, PseudoActivatedMonthID
			, IsOnline
			, SpenderCount
			, TranCount
			, Spend)
		SELECT @PartnerID
			, a.PseudoActivatedMonthID
			, CAST(0 AS bit) AS IsOnline
			, COUNT(DISTINCT a.CINID) AS SpenderCount
			, COUNT(*) AS TranCount
			, SUM(ct.Amount) AS Spend
		FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN APW.ControlAdjusted a ON ct.CINID = a.CINID
		INNER JOIN #Combos c ON ct.ConsumerCombinationID = c.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
		AND ct.IsOnline = 0
		GROUP BY a.PseudoActivatedMonthID
		ORDER BY PseudoActivatedMonthID

		--insert record for online spend
		INSERT INTO APW.ControlRetailerSpend(PartnerID
			, PseudoActivatedMonthID
			, IsOnline
			, SpenderCount
			, TranCount
			, Spend)
		SELECT @PartnerID
			, a.PseudoActivatedMonthID
			, CAST(1 AS bit) AS IsOnline
			, COUNT(DISTINCT a.CINID) AS SpenderCount
			, COUNT(*) AS TranCount
			, SUM(ct.Amount) AS Spend
		FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN APW.ControlAdjusted a ON ct.CINID = a.CINID
		INNER JOIN #Combos c ON ct.ConsumerCombinationID = c.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
		AND ct.IsOnline = 1
		GROUP BY a.PseudoActivatedMonthID
		ORDER BY PseudoActivatedMonthID

		DROP TABLE #Combos

		SELECT @PartnerID = MIN(PartnerID) FROM APW.ControlRetailers WHERE PartnerID > @PartnerID
		SELECT @BrandID = BrandID FROM APW.ControlRetailers WHERE PartnerID = @PartnerID

	END

	--set adjusted spenders
	UPDATE s
	SET adj_Spenders = s.SpenderCount * a.RRAdjustmentFactor
	FROM APW.ControlRetailerSpend s
	INNER JOIN APW.ControlAdjustmentFactor a ON s.PseudoActivatedMonthID = a.PseudoActivatedMonthID

	--set adjusted spend
	UPDATE s
	SET adj_Spend = CASE WHEN s.SpenderCount > 0 THEN (s.Spend/s.SpenderCount*a.SPSAdjustmentFactor) * adj_Spenders ELSE 0 END
	FROM APW.ControlRetailerSpend s
	INNER JOIN APW.ControlAdjustmentFactor a ON s.PseudoActivatedMonthID = a.PseudoActivatedMonthID

	--set adjusted tran count
	UPDATE s
	SET adj_Txns = CASE WHEN s.TranCount > 0 AND s.Spend > 0 THEN adj_Spend/((s.Spend/TranCount) *  a.ATVAdjustmentFactor) ELSE 0 END
	FROM APW.ControlRetailerSpend s
	INNER JOIN APW.ControlAdjustmentFactor a ON s.PseudoActivatedMonthID = a.PseudoActivatedMonthID

END