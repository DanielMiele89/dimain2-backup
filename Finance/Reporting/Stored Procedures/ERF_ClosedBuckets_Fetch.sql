


CREATE PROCEDURE Reporting.ERF_ClosedBuckets_Fetch
(
	@CreditCardOnly BIT = NULL
	, @PublisherID INT = NULL
)
AS
BEGIN

	SET @PublisherID = CASE WHEN @PublisherID IN (132, 138) THEN 132 ELSE @PublisherID END

	SELECT
		Customers
		, t.PublisherID
		, DeactivatedBandID
		, DeactivatedBand
		, BucketName
		, BucketID
		, isCreditCardOnly
		, TotalBalance
		, CASE 
				WHEN t.PublisherID IN (132, 138) 
					THEN RTRIM(LTRIM(LEFT(p.PublisherName, CHARINDEX(' ', p.PublisherName)))) 
				ELSE PublisherName
			END AS PublisherName
	FROM Reporting.ERF_ClosedBuckets t
	JOIN dbo.Publisher p
			ON t.PublisherID = p.PublisherID
	WHERE (
			CASE 
				WHEN t.PublisherID IN (132, 138) 
					THEN 132 
				ELSE  t.PublisherID
			END = @PublisherID
			OR @PublisherID IS NULL
		)
		AND 
		(
			(
				IsCreditCardOnly = @CreditCardOnly 
				OR @CreditCardOnly IS NULL
			)
		)
		AND DeactivatedBandID > 0


END