CREATE PROCEDURE [Reporting].[ERF_Refresh_OLD]
(
	@ReportDate DATE = NULL
)
AS
BEGIN
	DECLARE @Date DATE
	IF @ReportDate IS NULL
		SET @Date = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	ELSE
		SET @Date = @ReportDate
	SET @Date = DATEADD(DAY, -1, @Date)

	----------------------------------------------------------------------
	-- Spend and Earn
	----------------------------------------------------------------------

	IF OBJECT_ID('Reporting.ERF_Earnings') IS NOT NULL 
		DROP TABLE Reporting.ERF_Earnings
	SELECT 
		SUM(te.Earnings) Earnings
		, COUNT(1) AS TranCount
		, SUM(te.Spend) AS Spend
		, te.EarningSourceID
		, te.PaymentMethodID
		, c.PublisherID
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, te.TranDate), 0) AS MonthDate
	INTO Reporting.ERF_Earnings
	FROM dbo.Transactions te
	JOIN dbo.Customer c
		ON te.FanID = c.CustomerID
	WHERE te.TranDate <= @Date
	GROUP BY te.EarningSourceID
		, c.PublisherID
		, te.PaymentMethodID
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, te.TranDate), 0)

	----------------------------------------------------------------------
	-- Redemptions/Reductions
	----------------------------------------------------------------------

	IF OBJECT_ID('Reporting.ERF_Reductions') IS NOT NULL 
		DROP TABLE Reporting.ERF_Reductions

	SELECT
		*
	INTO Reporting.ERF_Reductions
	FROM 
	(
		select  
			 c.PublisherID
			, t.PaymentMethodID
			, r.EarningSourceID
			, r.ReductionTypeID
			, DATEADD(MONTH, DATEDIFF(MONTH, 0, ReductionDate), 0) MonthDate
			, SUM(AllocatedEarning) AS earnings
		from dbo.ReductionAllocation r
		JOIN dbo.Customer c
			ON r.CustomerID = c.CustomerID
		LEFT JOIN dbo.Transactions t
			ON r.EarningID = t.TransactionID
			AND r.EarningTypeID IN (1,2)
		WHERE ReductionDate <= @Date
		GROUP BY c.PublisherID
			, PaymentMethodID
			, r.EarningSourceID
			, r.ReductionTypeID
			, DATEADD(MONTH, DATEDIFF(MONTH, 0, ReductionDate), 0)

		UNION ALL

		SELECT
			PublisherID
			, -1 AS PaymentMethodID
			, -2 AS EarningSourceID
			, ReductionTypeID
			, DATEADD(MONTH, DATEDIFF(MONTH, 0, ReductionDate), 0) MonthDate
			, SUM(Reduction) - SUM(AllocatedEarning) AS Earnings
		FROM (
			SELECT
				ReductionID
				, ReductionDate
				, Reduction
				, c.PublisherID
				, r.ReductionTypeID
				, SUM(AllocatedEarning) AllocatedEarning
			FROM dbo.ReductionAllocation r
			JOIN dbo.Customer c
				ON r.CustomerID = c.CustomerID
			WHERE ReductionDate <= @Date
			GROUP BY ReductionID, REductionDate, Reduction, c.PublisherID, ReductionTypeID
		) x
		GROUP BY 
			PublisherID
			, ReductionTypeID
			, DATEADD(MONTH, DATEDIFF(MONTH, 0, ReductionDate), 0)
	) y

	/**********************************************************************
	Cashback Totals
	***********************************************************************/
	----------------------------------------------------------------------
	-- Build Lookups
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


	-- list of transactions that have been allocated to a redemption
	IF OBJECT_ID('tempdb..#ReductionTransactions') IS NOT NULL 
		DROP TABLE #ReductionTransactions
	SELECT ra.EarningID AS TransactionID, SUM(CASE WHEN ReductionTypeID = 1 THEN AllocatedEarning ELSE 0 END) AS AllocatedEarnings
		, SUM(CASE WHEN ReductionTypeID = 2 THEN AllocatedEarning ELSE 0 END) AS AllocatedBreakage
	INTO #ReductionTransactions 
	FROM dbo.ReductionAllocation ra
	WHERE EarningTypeID in (1,2)
		AND ReductionDate <= @Date
	GROUP BY ra.EarningID

	CREATE CLUSTERED INDEX CIX ON #ReductionTransactions (TransactionID)
	----------------------------------------------------------------------
	-- Get Earnings 
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Earnings') IS NOT NULL 
		DROP TABLE #Earnings
	SELECT 
		t.EarningSourceID
		, PaymentMethodID
		, c.PublisherID
		, ed.EligibleType
		, ed.EligibleID
		, c.DeactivatedBand
		, c.DeactivatedBandID
		, SUM(Earnings) AS Earnings
		, COALESCE(SUM(rt.AllocatedEarnings), 0) AS AllocatedEarnings
		, COALESCE(SUM(rt.AllocatedBreakage), 0) AS AllocatedBreakage
	INTO #Earnings
	FROM dbo.Transactions t
	JOIN #Customers c
		ON t.FanID = c.CustomerID
	JOIN #EligibleDates ed
		ON COALESCE(t.EligibleDate, t.TranDate) BETWEEN ed.StartDate AND ed.EndDate
	LEFT JOIN #ReductionTransactions rt
		ON t.TransactionID = rt.TransactionID
	WHERE (
			t.TranDate <= @Date
			OR rt.TransactionID IS NOT NULL
		)
		AND t.AdditionalCashbackAdjustmentTypeID NOT IN (1,2,3)  -- breakage adjustments
	GROUP BY t.EarningSourceID
		, PaymentMethodID
		, c.PublisherID
		, ed.EligibleType
		, c.DeactivatedBandID
		, c.DeactivatedBand
		, ed.EligibleID
		
	----------------------------------------------------------------------
	-- Build Final Table
	----------------------------------------------------------------------
	DECLARE @MaxEligibleID INT = (SELECT MAX(EligibleID) FROM #EligibleDates) -- For column ordering

	IF OBJECT_ID('Reporting.ERF_CashbackTotals') IS NOT NULL 
		DROP TABLE Reporting.ERF_CashbackTotals

	;WITH CashbackTotals
	AS
	(
		SELECT
			EarningSourceID
			, PaymentMethodID
			, PublisherID
			, SUM(Earnings) AS Earnings
			, 'Total' AS ColumnName
			, 1 AS ColumnID
		FROM #Earnings
		GROUP BY EarningSourceID
			, PaymentMethodID
			, PublisherID

		UNION ALL

		SELECT
			EarningSourceID
			, PaymentMethodID
			, PublisherID
			, SUM(Earnings)
			, CASE WHEN ReductionTypeID =1 THEN 'Redeemed' WHEN ReductionTypeID = 2 THEN 'Breakage' END
			, CASE WHEN ReductionTypeID = 1 THEN 2 ELSE 99 END
		FROM Reporting.ERF_Reductions
		GROUP BY EarningSourceID
			, PaymentMethodID
			, PublisherID
			, ReductionTypeID

		UNION ALL

		SELECT
			EarningSourceID
			, PaymentMethodID
			, PublisherID
			, SUM(Earnings - AllocatedEarnings )
			, 'Unredeemed Earnings'
			, 3
		FROM #Earnings
		GROUP BY EarningSourceID
			, PaymentMethodID
			, PublisherID

		UNION ALL

		SELECT
			EarningSourceID
			, PaymentMethodID
			, PublisherID
			, SUM(Earnings)-SUM(AllocatedEarnings) - SUM(AllocatedBreakage) AS Earnings
			, EligibleType
			, 3 + EligibleID
		FROM #Earnings
		WHERE DeactivatedBandID < 0
		GROUP BY EarningSourceID
			, PaymentMethodID
			, PublisherID
			, EligibleType
			, EligibleID

		UNION ALL

		SELECT
			EarningSourceID
			, PaymentMethodID
			, PublisherID
			, SUM(Earnings)-SUM(AllocatedEarnings) - SUM(AllocatedBreakage) AS Earnings
			, DeactivatedBand
			, 3 + @MaxEligibleID + DeactivatedBandID
		FROM #Earnings
		WHERE DeactivatedBandID > 0
		GROUP BY EarningSourceID
			, PaymentMethodID
			, PublisherID
			, DeactivatedBand
			, DeactivatedBandID
	)
	SELECT 
		ct.*
		, es.DisplayName
		, pt.Name AS PartnerName
		, RTRIM(LTRIM(LEFT(p.Name, CHARINDEX(' ', p.Name)))) AS PublisherName
		, CASE 
			WHEN es.DisplayName LIKE '%Direct Debit%' OR es.DisplayName LIKE '%Mobile Login (Reward 3.0)%' 
				THEN 'Bank Funded' 
			WHEN es.DDCategory <> '' 
				THEN 'Debit'
			ELSE CASE PaymentMethodID WHEN 1 THEN 'Credit' WHEN 0 THEN 'Debit' ELSE 'Unknown' END  
		END AS PaymentMethod
		, es.FundingType
	INTO Reporting.ERF_CashbackTotals
	FROM CashbackTotals ct
	JOIN dbo.EarningSource es
		ON ct.EarningSourceID = es.EarningSourceID
	JOIN dbo.Publisher p
		ON ct.PublisherID = p.PublisherID
	JOIN dbo.Partner pt
		ON es.PartnerID = pt.PartnerID
	--order by ColumnID
END

