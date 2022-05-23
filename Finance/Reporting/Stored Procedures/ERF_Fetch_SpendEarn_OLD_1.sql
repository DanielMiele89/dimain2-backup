CREATE PROCEDURE [Reporting].[ERF_Fetch_SpendEarn_OLD] 
(
	@ReportDate DATE
	, @PaymentMethodType VARCHAR(30)

)
AS
BEGIN

	DECLARE @StartDate DATE = DATEADD(YEAR, -1, @ReportDate)
	
	IF OBJECT_ID('Reporting.ERF_SpendEarn') IS NOT NULL
		DROP TABLE Reporting.ERF_SpendEarn

	select 
		CASE WHEN MonthDate < @StartDate THEN '1900-01-01' ELSE MonthDate END AS MonthDate 
		, cs.SourceName + COALESCE(NULLIF(' - ' + cs.DisplayCategory, ' - '), NULLIF(' - ' + cs.DDCategory, ' - '), '') AS DisplayName
		, DDCategory
		, CASE PaymentMethodID WHEN 1 THEN 'Credit' WHEN 0 THEN 'Debit' WHEN 2 THEN 'Bank Funded' ELSE 'Unknown' END AS PaymentMethod
		, PaymentMethodID
		, cs.PartnerID
		, p.Name AS PartnerName
		, LEFT(pub.Name, CHARINDEX(' ', pub.Name)-1) AS PublisherName
		, SUM(Earnings) AS Earnings
		, SUM(TranCount) AS TranCount
		, SUM(Spend) AS Spend
		, cs.EarningSourceID
		, cs.AdditionalCashbackAwardTypeID
		, cs.AdditionalCashbackAdjustmentTypeID
		, cs.FundingType
	INTO Reporting.ERF_SpendEarn
	from Reporting.ERF_Earnings te
	JOIN dbo.EarningSource_OLD cs
		ON te.EarningSourceID = cs.EarningSourceID
		AND cs.SourceName not like '%Breakage%'
	JOIN dbo.Partner_OLD p
		ON cs.PartnerID = p.PartnerID
	JOIN dbo.Publisher_OLD pub
		ON te.PublisherID = pub.PublisherID
	GROUP BY CASE WHEN MonthDate < @StartDate THEN '1900-01-01' ELSE MonthDate END
		, cs.SourceName
		, CASE PaymentMethodID WHEN 1 THEN 'Credit' WHEN 0 THEN 'Debit' ELSE 'Unknown' END 
		, cs.PartnerID
		, p.Name
		, pub.Name 
		, cs.DisplayCategory 
		, PaymentMethodID
		, cs.DDCategory
		, cs.EarningSourceID
		, cs.AdditionalCashbackAwardTypeID
		, cs.AdditionalCashbackAdjustmentTypeID
		, cs.FundingType

	SELECT 
		*
	FROM (
		SELECT 
			DisplayName
			, PaymentMethod
			, PublisherName
			, MonthDate
			, DDCategory
			, CASE 
				WHEN DisplayName LIKE '%Direct Debit%' OR DisplayName LIKE '%Mobile Login (Reward 3.0)%' 
					THEN 'Bank Funded' 
				WHEN DDCategory <> '' 
					THEN 'Debit'
				ELSE PaymentMethod 
			END AS PaymentMethodType
			, Earnings
			, Spend
			, EarningSourceID
			, AdditionalCashbackAwardTypeID
			, AdditionalCashbackAdjustmentTypeID
			, PartnerID
			, FundingType
		FROM Reporting.ERF_SpendEarn
	) x
	WHERE PaymentMethodType = @PaymentMethodType OR (@PaymentMethodType = 'All')
		AND MonthDate < @ReportDate

END

