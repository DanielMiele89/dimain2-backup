

CREATE VIEW [dbo].[Earnings]
AS

-- Positive Earnings == EarningTypeID 1
-- AND Positive Breakage == EarningTypeID 2
SELECT
	TransactionID AS EarningID
	, ISNULL(CAST(CAST(act.AdditionalCashbackAdjustmentTypeID  AS BIT) AS INT), 0) + 1 AS EarningTypeID -- If the LEFT JOIN fails, set earning typeid == 1 otherwise it is 2
	, FanID AS CustomerID
	, Earnings
	, TranDate
	, t.EarningSourceID
	, t.CreatedDateTime
FROM dbo.Transactions t
LEFT JOIN dbo.AdditionalCashbackAdjustmentType act
	ON t.AdditionalCashbackAdjustmentTypeID = act.AdditionalCashbackAdjustmentTypeID
	AND act.TypeDescription like '%Breakage%'
WHERE act.AdditionalCashbackAdjustmentTypeID IS NULL
	OR (act.AdditionalCashbackAdjustmentTypeID IS NOT NULL AND Earnings > 0) -- only consider positive breakage, negative breakage is considered a reduction
		
--UNION ALL

---- Cancelled Redemptions
--SELECT
--	RedemptionID AS EarningID
--	, CAST(3 AS TINYINT) AS EarningTypeID
--	, CustomerID
--	, RedemptionValue AS Earnings
--	, CancelledDate AS TranDate
--	, 336 AS EarningSourceID
--	, r.UpdatedDateTime
--FROM dbo.Redemptions r
--JOIN dbo.RedeemOffer ro
--	ON r.RedeemOfferID = ro.RedeemOfferID
--WHERE isCancelled = 1



