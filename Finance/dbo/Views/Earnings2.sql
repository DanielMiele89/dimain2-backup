
CREATE VIEW [dbo].[Earnings2]
AS

SELECT
	EarningID
	, EarningTypeID
	, cs.EarningSourceID
	, CustomerID
	, Earnings
	, TranDate
	, cs.partnerID
	, t.CreatedDateTime
FROM (
	-- Positive Earnings
	SELECT
		TransactionID AS EarningID
		, CAST(1 AS TINYINT) AS EarningTypeID
		--, cs.EarningSourceID
		, FanId AS CustomerID
		, Earnings
		, TranDate
		, t.PartnerID
		, t.AdditionalCashbackAwardTypeID
		, t.AdditionalCashbackAdjustmentTypeID
		, t.AdditionalCashbackAdjustmentCategoryID
		, t.DirectDebitOriginatorID
		, t.CreatedDateTime
	FROM dbo.Transactions t
	WHERE Earnings > 0

	UNION ALL

	-- Positive Breakage
	SELECT
		TransactionID AS EarningID
		, CAST(2 AS TINYINT) AS EarningTypeID
		--, cs.EarningSourceID
		, FanID
		, Earnings * -1 AS Earnings
		, TranDate
		, t.PartnerID
		, t.AdditionalCashbackAwardTypeID
		, t.AdditionalCashbackAdjustmentTypeID
		, t.AdditionalCashbackAdjustmentCategoryID
		, t.DirectDebitOriginatorID
		, t.CreatedDateTime
	FROM dbo.Transactions t
	WHERE t.Earnings > 0
		AND EXISTS (
			SELECT 1
			FROM dbo.AdditionalCashbackAdjustmentType aca
			WHERE TypeDescription like '%Breakage%'
				AND t.AdditionalCashbackAdjustmentTypeID = aca.AdditionalCashbackAdjustmentTypeID
		)
		
	UNION ALL

	-- Cancelled Redemptions
	SELECT
		RedemptionID AS EarningID
		, CAST(3 AS TINYINT) AS EarningTypeID
		--, 336 AS EarningSourceID -- Cancelled Redemption
		, CustomerID
		, RedemptionValue AS Earnings
		, CancelledDate AS TranDate
		, ro.PartnerID
		, -1 AS AdditionalCashbackAwardTypeID
		, -1 AS AdditionalCashbackAdjustmentTypeID
		, -1 AS AdditionalCashbackAdjustmentCategoryID
		, NULL AS DirectDebitOriginatorID
		, r.UpdatedDateTime
	FROM dbo.Redemptions r
	JOIN dbo.RedeemOffer ro
		ON r.RedeemOfferID = ro.RedeemOfferID
	WHERE isCancelled = 1
) t
LEFT JOIN dbo.PartnerAlternate pa
	ON t.PartnerID = pa.AlternatePartnerID
LEFT JOIN dbo.DirectDebitOriginator do
	ON t.DirectDebitOriginatorID = do.DirectDebitOriginatorID
JOIN dbo.EarningSource cs 
	ON COALESCE(pa.PartnerID, t.PartnerID) = cs.PartnerID
	AND t.AdditionalCashbackAdjustmentTypeID = cs.AdditionalCashbackAdjustmentTypeID
	AND t.AdditionalCashbackAwardTypeID = cs.AdditionalCashbackAwardTypeID
	AND t.AdditionalCashbackAdjustmentCategoryID = cs.AdditionalCashbackAdjustmentCategoryID
	AND COALESCE(do.Category2, '') = cs.DDCategory
	AND cs.EarningSourceID > 0



