CREATE PROCEDURE [Reporting].[ERF_Fetch_Reductions]
(
	@ReportDate DATE = NULL
	, @PaymentMethodType VARCHAR(30) = NULL
)
AS
BEGIN

	DECLARE @StartDate DATE = DATEADD(YEAR, -1, @ReportDate)

	IF @ReportDate IS NULL
	BEGIN
		SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
		SET @StartDate = DATEADD(YEAR, -1, @StartDate)
	END
	ELSE
		SET @StartDate = @ReportDate

	SET @PaymentMethodType = ISNULL(@PaymentMethodType, 'All')
	SET @ReportDate = ISNULL(@ReportDate, GETDATE())
	

	SELECT
		*
	FROM
	(
		SELECT
			CASE WHEN MonthDate < @StartDate THEN '1900-01-01' ELSE MonthDate END AS MonthDate
			, es.DisplayName
			, CASE WHEN es.isBankFunded = 1 THEN 'Bank Funded' ELSE pm.PaymentMethodType END AS PaymentMethodType
			, CASE 
				WHEN t.PublisherID IN (132, 138) 
					THEN RTRIM(LTRIM(LEFT(p.PublisherName, CHARINDEX(' ', p.PublisherName)))) 
				ELSE PublisherName
			END AS PublisherName
			, t.isCreditCardOnly
			, SUM(EarningAllocated) AS Earnings
			, SUM(t.TranCount) AS TranCount
			, SUM(Spend) AS Spend
			, es.FundingType
		FROM Reporting.ERF_Reductions t
		JOIN dbo.EarningSource es
			ON t.EarningSourceID = es.EarningSourceID
		JOIN dbo.Publisher p
			ON t.PublisherID = p.PublisherID
		JOIN dbo.PaymentMethod pm
			ON t.PaymentMethodID = pm.PaymentMethodID
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
	) x
	WHERE (PaymentMethodType = @PaymentMethodType OR (@PaymentMethodType = 'All'))
		AND MonthDate < @ReportDate

END