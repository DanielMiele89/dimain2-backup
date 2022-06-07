CREATE PROCEDURE [Reporting].[ERF_Redemptions_Fetch]
(
	@ReportDate DATE = NULL
	, @CreditCardOnly BIT = NULL
	, @PublisherID INT = NULL
)
AS
BEGIN

	DECLARE @StartDate DATE

	IF @ReportDate IS NULL
		SET @ReportDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	ELSE
		SET @ReportDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ReportDate), 0)

	SET @StartDate = DATEADD(YEAR, -1, @ReportDate)
	SET @ReportDate = ISNULL(@ReportDate, GETDATE())

	SELECT
		r.*
		, CASE 
			WHEN r.PublisherID IN (132, 138) 
				THEN RTRIM(LTRIM(LEFT(p.PublisherName, CHARINDEX(' ', p.PublisherName)))) 
			ELSE PublisherName
		END  AS PublisherName
	FROM Reporting.ERF_Redemptions r
	JOIN dbo.Publisher p
		ON r.PublisherID = p.PublisherID
	--JOIN dbo.RedemptionPartner pt
	--	ON r.RedemptionPartnerID = pt.RedemptionPartnerID
	WHERE (
			CASE 
				WHEN r.PublisherID IN (132, 138) 
					THEN 132 
				ELSE r.PublisherID 
			END = @PublisherID
			OR @PublisherID IS NULL
		)
		AND (isCreditCardOnly = @CreditCardOnly OR @CreditCardOnly IS NULL)
		AND MonthDate < @ReportDate

END


