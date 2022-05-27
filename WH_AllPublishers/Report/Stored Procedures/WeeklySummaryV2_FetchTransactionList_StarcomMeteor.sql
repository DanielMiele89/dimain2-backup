
CREATE PROCEDURE [Report].[WeeklySummaryV2_FetchTransactionList_StarcomMeteor] (@RetailerID INT)
AS 
BEGIN

SET NOCOUNT ON;
	
	/*
	SELECT *
	FROM [SLC_Report].[dbo].[Partner]
	WHERE Name LIKE '%ferries%'
	*/

	--	DECLARE @RetailerID int = 4842
	DECLARE @Today DATE = GETDATE();

	IF @Today < '2021-11-16' SET @Today = '2021-11-12'

	DECLARE @MinStartDate date = (SELECT MIN(StartDate) FROM [SLC_Report].[dbo].[IronOffer] WHERE PartnerID = @RetailerID); -- Sky go live date
	DECLARE @MaxEndDate date = DATEADD(day, -1, @Today);
	DECLARE @RetailerName VARCHAR(50) = (SELECT Name FROM [SLC_Report].[dbo].[Partner] WHERE ID = @RetailerID)
	SET @RetailerName = REPLACE(@RetailerName, '’', '')

	;WITH
		E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n))
	,	E2 AS (SELECT n = 0 FROM E1 a CROSS JOIN E1 b)
	,	Tally AS (SELECT n = 0 UNION ALL SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a CROSS JOIN E2 b) -- Create table of numbers
	,	TallyDates AS (SELECT n, CalDate = DATEADD(day, n, @MinStartDate) FROM Tally WHERE DATEADD(day, n, @MinStartDate) <= @MaxEndDate) -- Create table of consecutive dates
	,	Calendar AS (	SELECT	CalDate AS StartDate
							,	DATEADD(DAY, 1, CalDate) AS EndDate
						FROM TallyDates
						WHERE CalDate <= @MaxEndDate)

	-- If pointing to AllPublisherWarehouse SchemeTrans
	SELECT	@RetailerName AS RetailerName
		,	ca.StartDate
		,	ca.StartDate AS EndDate
		,	CONVERT(VARCHAR(50), '') AS TargetedCardholders
		,	COALESCE(COUNT(DISTINCT pt.MaskedCardNumber), 0) AS UniqueSpenders
		,	COALESCE(COUNT(pt.ID), 0) AS Transactions
		,	COALESCE(SUM(pt.Price), 0) AS Sales
		,	CONVERT(VARCHAR(50), '') AS SpendPerSpender
		,	CONVERT(VARCHAR(50), '') AS Salestocostratio
		,	COALESCE(SUM(pt.NetAmount), 0) AS Investment
		,	CONVERT(VARCHAR(50), '') AS BlendedCashbackRate
		,	CONVERT(VARCHAR(50), '') AS PurchaseRate
		,	CONVERT(VARCHAR(50), '') AS ATV
		,	CONVERT(VARCHAR(50), '') AS ATF
	FROM Calendar ca
	LEFT JOIN [SLC_REPL].[RAS].[PANless_Transaction] pt
		ON ca.StartDate <= pt.TransactionDate
		AND pt.TransactionDate < ca.EndDate
		AND pt.PartnerID = @RetailerID
		AND NOT EXISTS (SELECT 1
						FROM [SLC_REPL].[dbo].[CRT_File] fi
						WHERE pt.FileID = fi.ID
						AND fi.MatcherShortName IN ('VGN', 'AMX', 'VSI', 'VSA', 'VBC'))	--	Excluded as these are included in SchemeTrans
	GROUP BY	ca.StartDate
			,	ca.StartDate
	ORDER BY	ca.StartDate


END
