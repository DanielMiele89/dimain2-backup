CREATE PROCEDURE [Reporting].[ERF_Reduction_Fetch]
(
	@ReportDate DATE = NULL
	, @PaymentMethodType VARCHAR(30) = NULL
	, @CreditCardOnly BIT = NULL
	, @PublisherID INT = NULL
)
AS
BEGIN

	DECLARE @StartDate DATE = DATEADD(YEAR, -1, @ReportDate)

	IF @ReportDate IS NULL
		SET @ReportDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	ELSE
		SET @ReportDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ReportDate), 0)

	SET @StartDate = DATEADD(YEAR, -1, @ReportDate)
	SET @PaymentMethodType = ISNULL(@PaymentMethodType, 'All')
	SET @ReportDate = ISNULL(@ReportDate, GETDATE())
	

	SELECT
		*
	FROM
	(
		SELECT
			CASE WHEN MonthDate < @StartDate THEN '1900-01-01' ELSE MonthDate END AS MonthDate
			, es.DisplayName
			, pm.PaymentMethodType
			, CASE 
				WHEN t.PublisherID IN (132, 138) 
					THEN RTRIM(LTRIM(LEFT(p.PublisherName, CHARINDEX(' ', p.PublisherName)))) 
				ELSE PublisherName
			END AS PublisherName
			, t.isCreditCardOnly
			, t.PaymentCardType
			, SUM(EarningsAllocated) AS Earnings
			, es.FundingType
			, t.PublisherID
		FROM Reporting.ERF_Reductions t
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
			CASE WHEN MonthDate < @StartDate THEN '1900-01-01' ELSE MonthDate END
			, es.DisplayName
			, pm.PaymentMethodType
			, CASE 
				WHEN t.PublisherID IN (132, 138) 
					THEN RTRIM(LTRIM(LEFT(p.PublisherName, CHARINDEX(' ', p.PublisherName)))) 
				ELSE PublisherName
			END
			, t.isCreditCardOnly
			, es.isBankFunded
			, es.FundingType
			, t.PublisherID
			, t.PaymentCardType
	) x
	WHERE (PaymentMethodType = @PaymentMethodType OR @PaymentMethodType = 'All')
		AND (
			CASE 
				WHEN PublisherID IN (132, 138) 
					THEN 132 
				ELSE PublisherID 
			END = @PublisherID
			OR @PublisherID IS NULL
		)
		AND 
		(
			(
				x.isCreditCardOnly = @CreditCardOnly 
				AND (
					x.PaymentMethodType NOT IN ('Debit')
					AND PaymentCardType NOT IN ('Unknown Credit')
				) 
				OR @CreditCardOnly IS NULL
			)
		)
		AND MonthDate < @ReportDate

END
