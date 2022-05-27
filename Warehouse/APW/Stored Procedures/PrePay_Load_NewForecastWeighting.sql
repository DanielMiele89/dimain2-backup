/******************************************************************************
Author: Jason Shipp
Create date: 25/10/2019
Description:
	- Iterate through prepay retailers and dates requiring forecasts
	- Load last-year spends from Relational.ConsumerTransaction_MyRewards table into APW.ForecastWeighting_Staging table

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [APW].[PrePay_Load_NewForecastWeighting]

AS
BEGIN

	DECLARE @Today date = CAST(GETDATE() AS date);
	DECLARE @UpToDateNeeded date  = DATEADD(day, 65, @Today);

	-- Load prepay retailer consumer combinations

	IF OBJECT_ID('tempdb..#ConsumerCombos') IS NOT NULL DROP TABLE #ConsumerCombos;

	SELECT DISTINCT	
		pre.RetailerID
		, cc.ConsumerCombinationID
	INTO #ConsumerCombos
	FROM Warehouse.APW.PrePay_Partner pre
	INNER JOIN Warehouse.Relational.[Partner] p
		ON pre.PartnerID = p.PartnerID
	INNER JOIN Warehouse.Relational.ConsumerCombination cc
		ON p.BrandID = cc.BrandID;

	CREATE UNIQUE CLUSTERED INDEX UCIX_ConsumerCombos ON #ConsumerCombos (ConsumerCombinationID, RetailerID);
	CREATE NONCLUSTERED INDEX NCIX_ConsumerCombos ON #ConsumerCombos (RetailerID);

	-- Load calendar dates requiring forecasts per retailer

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;

	DECLARE @MinDate date = (SELECT MIN(MaxForecastDate) FROM Warehouse.APW.PrePay_MaxRetailerForecastWeighting);

	WITH 
		E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n))
		, E2 AS (SELECT n = 0 FROM E1 a CROSS JOIN E1 b)
		, Tally AS (SELECT n = 0 UNION ALL SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a CROSS JOIN E2 b) -- Create table of numbers
		, TallyDates AS (SELECT n, CalDate = DATEADD(day, n, @MinDate) FROM Tally WHERE DATEADD(day, n, @MinDate) <= @UpToDateNeeded) -- Create table of consecutive dates
	SELECT 
		mw.RetailerID
		, d.CalDate
		, DATEADD(day, -364, d.CalDate) AS LYDate -- Same date last year. -364 to maintain day of week
		, ROW_NUMBER() OVER (ORDER BY mw.RetailerID, d.CalDate) AS RowNum
	INTO #Calendar
	FROM TallyDates d
	INNER JOIN Warehouse.APW.PrePay_MaxRetailerForecastWeighting mw
		ON d.CalDate > mw.MaxForecastDate
	INNER JOIN Warehouse.APW.PrePay_Retailer r
		ON mw.RetailerID = r.RetailerID
	WHERE
		d.CalDate <= @UpToDateNeeded
	ORDER BY mw.RetailerID
		, d.CalDate;

	-- Set up iteration variables and table for storing results

	DECLARE @RowNumber int = 1;
	DECLARE @MaxRowNumber int = (SELECT MAX(RowNum) FROM #Calendar);
	DECLARE @RetailerID int;
	DECLARE @LYDate date;

	IF OBJECT_ID('tempdb..#ForecastWeightingStaging') IS NOT NULL DROP TABLE #ForecastWeightingStaging;
	CREATE TABLE #ForecastWeightingStaging (RetailerID int NOT NULL, LYDate date NOT NULL, Spend money);

	-- Iterate through retailers and last year dates and load Relational.ConsumerTransaction_MyRewards spend into temp table
	
	WHILE @RowNumber <= @MaxRowNumber
	BEGIN

		SET @RetailerID = (SELECT RetailerID FROM #Calendar WHERE RowNum = @RowNumber);
		SET @LYDate = (SELECT LYDate FROM #Calendar WHERE RowNum = @RowNumber);

		INSERT INTO #ForecastWeightingStaging (RetailerID, LYDate, Spend)
		SELECT
			@RetailerID AS RetailerID
			, @LYDate AS LYDate
			, SUM(ct.Amount) 
		FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct
		WHERE
			ct.TranDate = @LYDate
			AND ct.ConsumerCombinationID IN (SELECT ConsumerCombinationID FROM #ConsumerCombos WHERE RetailerID = @RetailerID);

		SET @RowNumber = @RowNumber + 1;

	END

	-- Load final results into Warehouse.APW.ForecastWeighting_Staging table

	INSERT INTO Warehouse.APW.ForecastWeighting_Staging (RetailerID, ForecastDate, Spend)
	SELECT
		cal.RetailerID
		, cal.CalDate
		, COALESCE(s.Spend, 0) AS Spend
	FROM #Calendar cal
	LEFT JOIN #ForecastWeightingStaging s
		ON cal.RetailerID = s.RetailerID
		AND cal.LYDate = s.LYDate;

END