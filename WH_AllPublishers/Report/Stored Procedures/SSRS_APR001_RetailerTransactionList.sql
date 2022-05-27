


CREATE PROCEDURE Report.[SSRS_APR001_RetailerTransactionList] 
@PartnerID nvarchar(30),
@StartDate DATE,
@EndDate DATE
AS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF OBJECT_ID('tempdb..#Partner') IS NOT NULL DROP TABLE #Partner
		SELECT	ID AS PartnerID
			,	Name AS PartnerName
		INTO #Partner
		FROM [SLC_REPL].[dbo].[Partner]
		where ID = @PartnerID
		--WHERE Name LIKE '%xxxxxxxxxx%'

		--DECLARE @StartDate DATE = '2021-02-01'
		--	,	@EndDate DATE = '2021-04-30'

		SELECT	CONVERT(BIGINT, pt.ID) * -1 AS MatchID
			,	fi.MatcherShortName AS PublisherName
			,	CONVERT(VARCHAR, ISNULL(pt.MerchantNumber, '')) AS  MerchantID
			,	CONVERT(VARCHAR, ro.PartnerOutletReference) AS Store
			,	CONVERT(DATE, pt.TransactionDate) AS TranDate
			,	CONVERT(TIME, pt.TransactionDate) AS Time
			,	MaskedCardNumber AS CardNumber
			,	pt.Price AS AmountSpent
			,	pt.OfferCode
			,	pt.OfferRate AS OfferPercentage
			,	pt.CashbackEarned
			,	pt.CommissionRate
			,	pt.NetAmount
			,	pt.VATAmount
			,	pt.GrossAmount
			,	pt.AddedDate
		FROM SLC_REPL.RAS.PANless_Transaction pt
		INNER JOIN SLC_REPL..CRT_File fi
			ON pt.FileID = fi.ID
		LEFT JOIN SLC_REPL..RetailOutlet ro
			ON pt.MerchantNumber = ro.MerchantID
		WHERE EXISTS (	SELECT 1
						FROM #Partner pa
						WHERE pt.PartnerID = pa.PartnerID)
		AND (pt.TransactionDate BETWEEN @StartDate AND @EndDate OR pt.AddedDate BETWEEN @StartDate AND @EndDate)
		AND fi.MatcherShortName NOT IN ('VGN', 'AMX', 'VSI', 'VSA')	--	Excluded as these are included in SchemeTrans
		ORDER BY TransactionDate

--RETURN 0


