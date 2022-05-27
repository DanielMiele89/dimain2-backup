CREATE PROCEDURE [Report].[GenerateTransactionList]	@RetailerID INT
												,	@StartDate DATE
												,	@EndDate DATE
AS
BEGIN

	;WITH
	CRT_File AS (		SELECT FileID = crt.ID
							,	FileName = crt.Filename
							,	MatcherShortName = crt.MatcherShortName
							,	VectorID = crt.VectorID
							,	PublisherID = vtp.PublisherID
							,	PublisherName = vtp.PublisherName
						FROM [SLC_REPL].[dbo].[CRT_File] crt
						LEFT JOIN [WH_AllPublishers].[Report].[VectorIDToPublisherID] vtp
							ON crt.VectorID = vtp.VectorID),

	RetailOutlet AS (	SELECT	MerchantID = REPLACE(ro.MerchantID, '#', '')
							,	ro.PartnerID
							,	PartnerOutletReference = MAX(ro.PartnerOutletReference)
						FROM [SLC_REPL].[dbo].[RetailOutlet] ro
						WHERE EXISTS (	SELECT 1
										FROM [SLC_REPL].[RAS].[PANless_Transaction] pt
										WHERE ro.PartnerID = pt.PartnerID)
						GROUP BY	REPLACE(ro.MerchantID, '#', '')
								,	ro.PartnerID)

	---- If pointing to AllPublisherWarehouse SchemeTrans

	SELECT	MatchID = pt.ID
		,	PublisherName = CONVERT(VARCHAR(50), COALESCE(crt.PublisherName, ''))
		,	MerchantID = CONVERT(VARCHAR(50), ISNULL(pt.MerchantNumber, ''))
		,	Store = CONVERT(VARCHAR(50), ISNULL(ro.PartnerOutletReference, ''))
		,	[Date] = CONVERT(DATE, pt.TransactionDate)
		,	[Time] = CASE WHEN CONVERT(TIME, pt.TransactionDate) = '00:00:00.0000000' THEN '' ELSE CONVERT(VARCHAR(20), CONVERT(TIME, pt.TransactionDate)) END
		,	CardNumber = COALESCE(REPLACE(pt.MaskedCardNumber, 'X', '*'), '')
		,	AmountSpent = pt.Price
		,	OfferCode = CONVERT(VARCHAR(50), ISNULL(pt.OfferCode, '') )
		,	IronOfferID = o.IronOfferID
		,	IronOfferName = CONVERT(VARCHAR(150), o.OfferName)
		,	OfferPercentage =	CASE
									WHEN pt.OfferRate = 0 THEN '£' + CONVERT(VARCHAR(10), pt.CashbackEarned)
									ELSE CONVERT(VARCHAR(10), pt.OfferRate) + '%'
								END
		,	CashbackEarned = pt.CashbackEarned
		,	CommissionRate =	CASE
									WHEN pt.CommissionRate = 0 THEN '£' + CONVERT(VARCHAR(10), pt.GrossAmount - pt.VATAmount)
									ELSE CONVERT(VARCHAR(10), pt.CommissionRate) + '%'
								END
		,	NetAmount = pt.GrossAmount - pt.VATAmount
		,	VatAmount = pt.VATAmount
		,	GrossAmount = pt.GrossAmount
	FROM [SLC_REPL].[RAS].[PANless_Transaction] pt
	INNER JOIN [WH_AllPublishers].[Derived].[Offer] o
		ON pt.OfferCode = o.OfferCode
		OR pt.PublisherOfferCode = o.OfferCode
		OR pt.OfferCode = CONVERT(VARCHAR(5), o.IronOfferID)
		OR pt.PublisherOfferCode = CONVERT(VARCHAR(5), o.IronOfferID)
		OR pt.OfferCode = REPLACE(OfferGUID, '-', '')
		OR pt.PublisherOfferCode = REPLACE(OfferGUID, '-', '')
	LEFT JOIN CRT_File crt
		ON pt.FileID = crt.FileID
	LEFT JOIN RetailOutlet ro
		ON pt.PartnerID = ro.PartnerID
		AND pt.MerchantNumber = ro.MerchantID
	WHERE CONVERT(DATE, pt.TransactionDate) BETWEEN @StartDate AND @EndDate
	AND o.RetailerID = @RetailerID;

END