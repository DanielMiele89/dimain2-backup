
CREATE PROCEDURE [Reporting].[ERF_SpendEarn_Fetch] 
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
			, DisplayName
			, pm.PaymentMethodType
			, CASE 
				WHEN t.PublisherID IN (132, 138) 
					THEN RTRIM(LTRIM(LEFT(p.PublisherName, CHARINDEX(' ', p.PublisherName)))) 
				ELSE PublisherName
			END AS PublisherName
			, t.PublisherID
			, t.PaymentCardType
			, t.isCreditCardOnly AS isCreditCardOnly
			, SUM(Earning) AS Earnings
			, SUM(t.TranCount) AS TranCount
			, SUM(Spend) AS Spend
			, es.FundingType
		FROM Reporting.ERF_Earnings t WITH (nolock)
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
			, t.PaymentCardType
			, t.PublisherID
			, es.SourceTypeID
	) x
	WHERE (PaymentMethodType = @PaymentMethodType OR @PaymentMethodType = 'All')
		AND 
		(
			(
				x.isCreditCardOnly = @CreditCardOnly 
				AND (
					x.PaymentMethodType <> 'Debit'
					AND PaymentCardType NOT IN ('Unknown Credit')
				) 
				OR @CreditCardOnly IS NULL
			)
		)
		AND (
			CASE 
				WHEN PublisherID IN (132, 138) 
					THEN 132 
				ELSE PublisherID END = @PublisherID
			OR PublisherID = @PublisherID
			OR @PublisherID IS NULL
		)
		AND MonthDate < @ReportDate

END
