CREATE PROCEDURE [FIFO].[Reporting_ERF_Build]
(
	@ReportDate DATE = NULL
)
AS
BEGIN
	/**********************************************************************
	Currently just doing the assumed queries that are required
	-- more steps to follow but this is the main section
	***********************************************************************/

	DECLARE @Date DATE
	IF @ReportDate IS NULL
	BEGIN
		SET @Date = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
		SET @Date = DATEADD(DAY, -1, @Date)
	END
	ELSE
		SET @Date = @ReportDate

	--SET @Date = '2022-03-31'

	----------------------------------------------------------------------
	-- Customers
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#EligibleDates') IS NOT NULL 
		DROP TABLE #EligibleDates
	SELECT
		1 AS EligibleID, 'Earnings Eligible for Redemption' AS EligibleType, CAST('1900-01-01' AS DATE) StartDate, @Date EndDate
	INTO #EligibleDates
	UNION ALL
	SELECT
		2 AS EligibleID, 'Potential Cashback Liability', DATEADD(DAY, 1, @Date), '9999-01-01'

	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL 
		DROP TABLE #Customers
	SELECT 
		c.CustomerID
		, db.DeactivatedBandID
		, db.DeactivatedBand
		, c.PublisherID
	INTO #Customers
	FROM dbo.Customer c
	JOIN dbo.DeactivatedBand db
		ON DATEDIFF(DAY, c.DeactivatedDate, @Date) BETWEEN db.DeactivatedBandMin AND db.DeactivatedBandMax
		OR (DeactivatedDate IS NULL AND db.DeactivatedBandID = -1)

	CREATE CLUSTERED INDEX CIX ON #Customers (CustomerID)

	----------------------------------------------------------------------
	-- Spend and Earn
	----------------------------------------------------------------------

	DROP TABLE IF EXISTS Reporting.ERF_Earnings
	SELECT 
		te.PublisherID
		, te.PaymentMethodID
		, te.EarningSourceID
		, pc.PaymentCardType
		, ed.EligibleType
		, ed.EligibleID
		, c.DeactivatedBand
		, c.DeactivatedBandID
		, SUM(Earning) Earning
		, COUNT(1) AS TranCount
		, SUM(Spend) AS Spend
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0) AS MonthDate
		, HASHBYTES('MD5', 
			CONCAT(te.PublisherID
				, ',', te.PaymentMethodID
				, ',', te.EarningSourceID
				, ',', pc.PaymentCardType
				, ',', ed.EligibleType
				, ',', ed.EligibleID
				, ',', c.DeactivatedBand
				, ',', c.DeactivatedBandID
			)
		) AS MD5
	INTO Reporting.ERF_Earnings
	FROM dbo.Transactions te
	JOIN #Customers c
		ON te.CustomerID = c.CustomerID
	JOIN #EligibleDates ed
		ON te.EligibleDate BETWEEN ed.StartDate AND ed.EndDate
	JOIN dbo.PaymentCard pc
		ON te.PaymentCardID = pc.PaymentCardID
	WHERE TranDate <= @Date
		AND te.EarningSourceID NOT IN 
		(
			2160 -- Breakage - Optout (from SLCPointsNegative)
			, 2158 -- Breakage - Deceased (from SLCPointsNegative)
			, 2159 -- Breakage - Deactivation (from SLCPointsNegative)
			, 2174 -- Breakage Negative Adjustment (from TransactionType)
		)
	GROUP BY te.PublisherID
		, te.PaymentMethodID
		, te.EarningSourceID
		, pc.PaymentCardType
		, ed.EligibleType
		, ed.EligibleID
		, c.DeactivatedBand
		, c.DeactivatedBandID
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0)


	----------------------------------------------------------------------
	-- Reductions
	----------------------------------------------------------------------
	DROP TABLE IF EXISTS Reporting.ERF_Reductions

	SELECT  
		r.PublisherID
		, r.PaymentMethodID
		, r.EarningSourceID
		, pc.PaymentCardType
		, ed.EligibleType
		, ed.EligibleID
		, c.DeactivatedBand
		, c.DeactivatedBandID
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, r.ReductionDate), 0) MonthDate
		, SUM(CASE WHEN r.isBreakage = 0 THEN r.EarningAllocated ELSE 0 END) AS EarningsAllocated
		, SUM(CASE WHEN r.isBreakage = 1 THEN r.EarningAllocated ELSE 0 END) AS BreakageAllocated
		, HASHBYTES('MD5', 
			CONCAT(r.PublisherID
				, ',', r.PaymentMethodID
				, ',', r.EarningSourceID
				, ',', pc.PaymentCardType
				, ',', ed.EligibleType
				, ',', ed.EligibleID
				, ',', c.DeactivatedBand
				, ',', c.DeactivatedBandID
			)
		) AS MD5
	INTO Reporting.ERF_Reductions
	FROM FIFO.ReductionAllocations r
	JOIN #Customers c
		ON r.CustomerID = c.CustomerID
	JOIN #EligibleDates ed
		ON r.EarningDate BETWEEN ed.StartDate AND ed.EndDate
	JOIN dbo.PaymentCard pc
		ON r.PaymentCardID = pc.PaymentCardID
	WHERE ReductionDate <= @Date
	GROUP BY r.PublisherID
		, r.PaymentMethodID
		, r.EarningSourceID
		, pc.PaymentCardType
		, ed.EligibleType
		, ed.EligibleID
		, c.DeactivatedBand
		, c.DeactivatedBandID
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, r.ReductionDate), 0)

	
	----------------------------------------------------------------------
	-- Cashback Totals
	----------------------------------------------------------------------

	DROP TABLE IF EXISTS #EarnRedeem
	SELECT
		ISNULL(r.PublisherID, e.PublisherID) AS PublisherID
		, ISNULL(r.PaymentMethodID, e.PaymentMethodID) AS PaymentMethodID
		, ISNULL(r.EarningSourceID, e.EarningSourceID) AS EarningSourceID
		, ISNULL(r.PaymentCardType, e.PaymentCardType) AS PaymentCardType
		, ISNULL(r.EligibleType, e.EligibleType) AS EligibleType
		, ISNULL(r.EligibleID, e.EligibleID) AS EligibleID
		, ISNULL(r.DeactivatedBand, e.DeactivatedBand) AS DeactivatedBand
		, ISNULL(r.DeactivatedBandID, e.DeactivatedBandID) AS DeactivatedBandID
		, ISNULL(SUM(e.Earning), 0)			AS Earnings
		, ISNULL(SUM(r.EarningsAllocated), 0) AS EarningsAllocated
		, ISNULL(SUM(r.BreakageAllocated), 0) AS BreakageAllocated
	INTO #EarnRedeem
	FROM Reporting.ERF_Reductions r
	FULL OUTER JOIN Reporting.ERF_Earnings e
		ON r.MD5 = e.MD5
		AND r.MonthDate = e.MonthDate
	GROUP BY ISNULL(r.PublisherID, e.PublisherID) 
		, ISNULL(r.PaymentMethodID, e.PaymentMethodID)
		, ISNULL(r.EarningSourceID, e.EarningSourceID)
		, ISNULL(r.PaymentCardType, e.PaymentCardType)
		, ISNULL(r.EligibleType, e.EligibleType) 
		, ISNULL(r.EligibleID, e.EligibleID) 
		, ISNULL(r.DeactivatedBand, e.DeactivatedBand) 
		, ISNULL(r.DeactivatedBandID, e.DeactivatedBandID) 

	DROP TABLE IF EXISTS Reporting.ERF_CashbackTotals2
	;WITH Tbl
	AS
	(
		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, SUM(r.Earnings) AS Earnings
			, 'Total' AS ColumnName
			, 1 AS ColumnID
		FROM #EarnRedeem r
		GROUP BY r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
		
		UNION ALL

		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, SUM(r.EarningsAllocated) AS Earnings
			, 'Redeemed' AS ColumnName
			, 2 AS ColumnID
		FROM #EarnRedeem r
		GROUP BY r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType

		UNION ALL

		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, SUM(r.BreakageAllocated) AS Earnings
			, 'Breakage' AS ColumnName
			, 99 AS ColumnID
		FROM #EarnRedeem r
		GROUP BY r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType

		UNION ALL

		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, SUM(r.Earnings - r.EarningsAllocated - r.BreakageAllocated) AS Earnings
			, 'Unredeemed Earnings' AS ColumnName
			, 3 AS ColumnID
		FROM #EarnRedeem r
		GROUP BY r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType

		UNION ALL

		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, SUM(r.Earnings - r.EarningsAllocated - r.BreakageAllocated) AS Earnings
			, EligibleType AS ColumnName
			, 3+EligibleID AS ColumnID
		FROM #EarnRedeem r
		WHERE DeactivatedBandID < 0
		GROUP BY r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, EligibleID
			, EligibleType

		UNION ALL

		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, SUM(r.Earnings - r.EarningsAllocated - r.BreakageAllocated) AS Earnings
			, DeactivatedBand AS ColumnName
			, 5+DeactivatedBandID AS ColumnID
		FROM #EarnRedeem r
		WHERE DeactivatedBandID < 0
		GROUP BY r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, DeactivatedBandID
			, DeactivatedBand
	)
	SELECT 
		t.* 
		, es.SourceName AS DisplayName
		, pt.RetailerName AS PartnerName
		, CASE 
			WHEN t.PublisherID IN (132, 138) 
				THEN RTRIM(LTRIM(LEFT(p.PublisherName, CHARINDEX(' ', p.PublisherName)))) 
			ELSE PublisherName
		END AS PublisherName
		, pm.PaymentMethodType AS PaymentMethod
		, es.FundingType
	INTO Reporting.ERF_CashbackTotals2
	FROM Tbl t
	JOIN dbo.EarningSource es
		ON t.EarningSourceID = es.EarningSourceID
	JOIN dbo.Publisher p
		ON t.PublisherID = p.PublisherID
	JOIN dbo.PaymentMethod pm
		ON t.PaymentMethodID = pm.PaymentMethodID
	JOIN dbo.Partner pt
		ON es.PartnerID = pt.PartnerID
	
END


