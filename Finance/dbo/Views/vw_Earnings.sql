


CREATE VIEW [dbo].[vw_Earnings]
AS

--SELECT
--	TransactionID = t.ID
--	, CustomerID = t.FanID
--	, OfferID = -1
--	, EarningSourceID = t.TypeID
--	, PublisherID = 132
--	, PaymentCardID = -1
--	, Spend = t.Price
--	, Earning = t.ClubCash * tt.Multiplier
--	, CurrencyCode = 'GBP'
--	, TranDate = CAST(t.Date AS DATE)
--	, TranDateTime = CAST(t.Date AS DATETIME2)
--	, PaymentMethodID = 1
--	, ActivationDays = t.ActivationDays
--	, EligibleDate = DATEADD(DAY, t.ActivationDays, t.Date)
--	, SourceTypeID = 1
--	, SourceID = t.ID
--	, CreatedDateTime = CAST('2022-01-01' AS DATETIME2)
--	, SourceAddedDateTime = CAST(t.ProcessDate AS DATETIME2)
--FROM SLC_REPL.dbo.Trans t
--JOIN SLC_REPL.dbo.TransactionType tt
--	ON t.TypeID = tt.ID
--	AND tt.Multiplier <> 0
--WHERE FanID = 12449432


	SELECT
		TransactionID
		, CustomerID
		, OfferID
		, EarningSourceID
		, PublisherID
		, PaymentCardID
		, Spend
		, Earning
		, CurrencyCode
		, TranDate
		, TranDateTime
		, PaymentMethodID
		, ActivationDays
		, EligibleDate
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, SourceAddedDateTime
	FROM dbo.Transactions t
	WHERE NOT EXISTS (
		-- Do not include negative breakage
		SELECT 1 FROM dbo.EarningSource es 
		JOIN dbo.SourceType st
			ON es.SourceTypeID = st.SourceTypeID
		JOIN dbo.SourceSystem ss
			ON st.SourceSystemID = ss.SourceSystemID
			AND ss.SourceSystemName = 'SLC'
		WHERE es.SourceName like '%breakage%'
			AND t.EarningSourceID = es.EarningSourceID
			AND t.Earning < 0
	)





