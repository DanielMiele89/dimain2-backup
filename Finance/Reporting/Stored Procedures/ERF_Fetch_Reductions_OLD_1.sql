CREATE PROCEDURE [Reporting].[ERF_Fetch_Reductions_OLD]
(
	@ReportDate DATE
	, @PaymentMethodType VARCHAR(30)
)
AS
BEGIN

	
	DECLARE @StartDate DATE = DATEADD(YEAR, -1, @ReportDate)

	IF OBJECT_ID('tempdb..#Reductions') IS NOT NULL 
		DROP TABLE #Reductions
	
	select
		CASE WHEN MonthDate < @StartDate THEN '1900-01-01' ELSE MonthDate END AS MonthDate 
		, es.SourceName
		, es.DisplayName
		, CASE PaymentMethodID WHEN 1 THEN 'Credit' WHEN 0 THEN 'Debit' ELSE 'Unknown' END AS PaymentMethod
		, RTRIM(LTRIM(LEFT(pub.Name, CHARINDEX(' ', pub.Name)))) AS PublisherName
		, p.Name
		, Earnings AS Earnings
		, es.PartnerID
		, r.EarningSourceID
		, es.DDCategory
		, es.AdditionalCashbackAdjustmentTypeID
		, es.AdditionalCashbackAwardTypeID
		, es.FundingType
	INTO #Reductions
	from Reporting.ERF_Reductions r
	JOIN Publisher_OLD pub
		ON r.PublisherID = pub.PublisherID
	JOIN EarningSource_OLD es
		ON r.EarningSourceID = es.EarningSourceID
	JOIN dbo.Partner_OLD p
		ON es.PartnerID = p.PartnerID
	WHERE ReductionTypeID = 1

	SELECT
		*
	FROM (	
		SELECT 
			SourceName
			, DisplayName
			, PaymentMethod
			, PublisherName
			, MonthDate
			, SUM(Earnings) AS Earnings
			, CASE 
				WHEN DisplayName LIKE '%Direct Debit%' OR DisplayName LIKE '%Mobile Login (Reward 3.0)%' 
					THEN 'Bank Funded' 
				WHEN DDCategory <> '' 
					THEN 'Debit'
				ELSE PaymentMethod 
			END AS PaymentMethodType
			, AdditionalCashbackAdjustmentTypeID
			, AdditionalCashbackAwardTypeID
			, PartnerID
			, FundingType
		FROM #Reductions
		--WHERE DisplayName NOT LIKE '%Breakage%'
		GROUP BY SourceName
			, DisplayName
			, PaymentMethod
			, PublisherName
			, MonthDate
			, CASE 
				WHEN DisplayName LIKE '%Direct Debit%' OR DisplayName LIKE '%Mobile Login (Reward 3.0)%' 
					THEN 'Bank Funded' 
				WHEN DDCategory <> '' 
					THEN 'Debit'
				ELSE PaymentMethod 
			END
			, AdditionalCashbackAwardTypeID
			, AdditionalCashbackAdjustmentTypeID
			, PartnerID
			, FundingType
	) x
	WHERE (PaymentMethodType = @PaymentMethodType OR @PaymentMethodType = 'All')
		AND MonthDate < @ReportDate
END