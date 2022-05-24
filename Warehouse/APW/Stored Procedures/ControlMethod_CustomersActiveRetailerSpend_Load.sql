-- =============================================
-- Author:		JEA
-- Create date: 15/06/2016
-- Description:	Fetches retailer data for customer base stats for uplift
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_CustomersActiveRetailerSpend_Load]

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
		INSERT INTO APW.CustomersActiveRetailerSpend(PartnerID
			, IsOnline
			, SpenderCount
			, TranCount
			, Spend)
		SELECT @PartnerID
			, NULL AS IsOnline
			, COUNT(DISTINCT a.CINID) AS SpenderCount
			, COUNT(*) AS TranCount
			, ISNULL(SUM(ct.Amount),0) AS Spend
		FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN APW.CustomersActive a ON ct.CINID = a.CINID
		INNER JOIN #Combos c ON ct.ConsumerCombinationID = c.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @StartDate AND @EndDate

		--insert record for offline spend
		INSERT INTO APW.CustomersActiveRetailerSpend(PartnerID
			, IsOnline
			, SpenderCount
			, TranCount
			, Spend)
		SELECT @PartnerID
			, CAST(0 AS bit) AS IsOnline
			, COUNT(DISTINCT a.CINID) AS SpenderCount
			, COUNT(*) AS TranCount
			, ISNULL(SUM(ct.Amount),0) AS Spend
		FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN APW.CustomersActive a ON ct.CINID = a.CINID
		INNER JOIN #Combos c ON ct.ConsumerCombinationID = c.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
		AND ct.IsOnline = 0

		--insert record for online spend
		INSERT INTO APW.CustomersActiveRetailerSpend(PartnerID
			, IsOnline
			, SpenderCount
			, TranCount
			, Spend)
		SELECT @PartnerID
			, CAST(1 AS bit) AS IsOnline
			, COUNT(DISTINCT a.CINID) AS SpenderCount
			, COUNT(*) AS TranCount
			, ISNULL(SUM(ct.Amount),0) AS Spend
		FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN APW.CustomersActive a ON ct.CINID = a.CINID
		INNER JOIN #Combos c ON ct.ConsumerCombinationID = c.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
		AND ct.IsOnline = 1

		DROP TABLE #Combos

		SELECT @PartnerID = MIN(PartnerID) FROM APW.ControlRetailers WHERE PartnerID > @PartnerID
		SELECT @BrandID = BrandID FROM APW.ControlRetailers WHERE PartnerID = @PartnerID

	END

END