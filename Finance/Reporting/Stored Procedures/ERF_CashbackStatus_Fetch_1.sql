

CREATE PROCEDURE [Reporting].[ERF_CashbackStatus_Fetch]
(
	@ReportDate DATE = NULL
	, @PaymentMethodType VARCHAR(30) = NULL
	, @CreditCardOnly BIT = NULL
	, @PublisherID INT = NULL
)
AS
BEGIN

	IF @ReportDate IS NULL
	BEGIN
		SET @ReportDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	END
	ELSE
		SET @ReportDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ReportDate), 0)

	SET @PaymentMethodType = ISNULL(@PaymentMethodType, 'All')
	SET @PublisherID = CASE WHEN @PublisherID IN (132, 138) THEN 132 ELSE @PublisherID END
	
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
		, ISNULL(r.isCreditCardOnly, e.isCreditCardOnly) AS isCreditCardOnly
		, ISNULL(r.MonthDate, e.MonthDate) AS MonthDate
		, ISNULL(SUM(e.Earning), 0)			AS Earnings
		, ISNULL(SUM(r.EarningsAllocated), 0) AS EarningsAllocated
		, ISNULL(SUM(r.BreakageAllocated), 0) AS BreakageAllocated
	INTO #EarnRedeem
	FROM Reporting.ERF_Reductions r
	FULL OUTER JOIN Reporting.ERF_Earnings e
		ON r.PublisherID = e.PublisherID 
		AND r.PaymentMethodID = e.PaymentMethodID
		AND r.EarningSourceID = e.EarningSourceID
		AND r.PaymentCardType = e.PaymentCardType
		AND r.EligibleType = e.EligibleType 
		AND r.EligibleID = e.EligibleID 
		AND r.DeactivatedBand = e.DeactivatedBand 
		AND r.DeactivatedBandID = e.DeactivatedBandID 
		AND r.isCreditCardOnly = e.isCreditCardOnly
		AND r.MonthDate = e.MonthDate
	WHERE (
			CASE 
				WHEN ISNULL(r.PublisherID, e.PublisherID) IN (132, 138) 
					THEN 132 
				ELSE  ISNULL(r.PublisherID, e.PublisherID) 
			END = @PublisherID
			OR @PublisherID IS NULL
		)
		AND 
		(
			(
				ISNULL(r.isCreditCardOnly, e.isCreditCardOnly) = @CreditCardOnly 
				AND (
					ISNULL(r.PaymentMethodID, e.PaymentMethodID) <> 0
					AND ISNULL(r.PaymentCardType, e.PaymentCardType) NOT IN ('Unknown Credit')
				) 
				OR @CreditCardOnly IS NULL
			)
		)
		AND ISNULL(r.MonthDate, e.MonthDate) < @ReportDate
	GROUP BY ISNULL(r.PublisherID, e.PublisherID) 
		, ISNULL(r.PaymentMethodID, e.PaymentMethodID)
		, ISNULL(r.EarningSourceID, e.EarningSourceID)
		, ISNULL(r.PaymentCardType, e.PaymentCardType)
		, ISNULL(r.EligibleType, e.EligibleType) 
		, ISNULL(r.EligibleID, e.EligibleID) 
		, ISNULL(r.DeactivatedBand, e.DeactivatedBand) 
		, ISNULL(r.DeactivatedBandID, e.DeactivatedBandID) 
		, ISNULL(r.isCreditCardOnly, e.isCreditCardOnly)
		, ISNULL(r.MonthDate, e.MonthDate)

	DROP TABLE IF EXISTS Reporting.ERF_CashbackTotals
	;WITH Tbl
	AS
	(
		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly
			, SUM(r.Earnings) AS Earnings
			, 'Total' AS ColumnName
			, 1 AS ColumnID
		FROM #EarnRedeem r
		GROUP BY 
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly 

		UNION ALL

		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly
			, SUM(r.EarningsAllocated)  AS Earnings
			, 'Redeemed' AS ColumnName
			, 2 AS ColumnID
		FROM #EarnRedeem r
		GROUP BY 
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly 

		UNION ALL

		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly
			, SUM(r.BreakageAllocated) AS Earnings
			, 'Breakage' AS ColumnName
			, 99 AS ColumnID
		FROM #EarnRedeem r
		GROUP BY 
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly 

		UNION ALL

		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly
			, SUM(r.Earnings - r.EarningsAllocated) AS Earnings
			, 'Unredeemed Earnings' AS ColumnName
			, 3 AS ColumnID
		FROM #EarnRedeem r
		GROUP BY 
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly 

		UNION ALL

		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly
			, SUM(r.Earnings - r.EarningsAllocated - r.BreakageAllocated) AS Earnings
			, EligibleType AS ColumnName
			, 3+EligibleID AS ColumnID
		FROM #EarnRedeem r
		WHERE DeactivatedBandID < 0
		GROUP BY 
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly 
			, r.eligibleid
			, r.eligibletype

		UNION ALL

		SELECT
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly
			, SUM(r.Earnings - r.EarningsAllocated - r.BreakageAllocated) AS Earnings
			, DeactivatedBand AS ColumnName
			, 5+DeactivatedBandID AS ColumnID
		FROM #EarnRedeem r
		WHERE DeactivatedBandID > 0
		GROUP BY 
			r.PublisherID
			, r.PaymentMethodID
			, r.EarningSourceID
			, r.PaymentCardType
			, r.isCreditCardOnly 
			, r.deactivatedbandid
			, r.deactivatedband
	)
	SELECT 
		t.* 
	INTO Reporting.ERF_CashbackTotals
	FROM Tbl t


	SELECT
		*
	FROM
	(
		SELECT
			es.DisplayName
			, pm.PaymentMethodType
			, CASE 
				WHEN t.PublisherID IN (132, 138) 
					THEN RTRIM(LTRIM(LEFT(p.PublisherName, CHARINDEX(' ', p.PublisherName)))) 
				ELSE PublisherName
			END AS PublisherName
			, t.isCreditCardOnly
			, t.PaymentCardType
			, SUM(Earnings) AS Earnings
			, es.FundingType
			, t.PublisherID
			, t.ColumnName
			, t.ColumnID
		FROM Reporting.ERF_CashbackTotals t
		JOIN dbo.EarningSource es
			ON t.EarningSourceID = es.EarningSourceID
		JOIN dbo.Publisher p
			ON t.PublisherID = p.PublisherID
		JOIN dbo.PaymentMethod pm
			ON CASE 
					WHEN t.PaymentMethodID = 2 
							AND (es.PartnerID <> -1 OR es.SourceTypeID = 21) 
					THEN -1 
					WHEN es.SourceTypeID = 25
						AND es.isBankFunded = 1
					THEN 2
				ELSE t.PaymentMethodID 
			END = pm.PaymentMethodID
		JOIN dbo.Partner pt
			ON es.PartnerID = pt.PartnerID
		GROUP BY
			es.DisplayName
			, pm.PaymentMethodType
			, CASE 
				WHEN t.PublisherID IN (132, 138) 
					THEN RTRIM(LTRIM(LEFT(p.PublisherName, CHARINDEX(' ', p.PublisherName)))) 
				ELSE PublisherName
			END
			, t.isCreditCardOnly
			, es.isBankFunded
			, es.FundingType
			, t.PaymentCardType
			, t.PublisherID
			, t.ColumnName
			, t.ColumnID
	) x
	WHERE (PaymentMethodType = @PaymentMethodType OR @PaymentMethodType = 'All')

END




