
CREATE PROCEDURE [MI].[RedemptionProfitabilityLoad]
AS
BEGIN

	IF OBJECT_ID('tempdb..#RedemptionItem') IS NOT NULL DROP TABLE #RedemptionItem
	SELECT ri.RedeemID
		 , ri.RedeemType
		 , ri.PrivateDescription
		 , ri.Status
		 , tuv.PartnerID
		 , pa.PartnerName
		 , tuv.TradeUp_ClubCashRequired
		 , tuv.TradeUp_Value
	INTO #RedemptionItem
	FROM Relational.RedemptionItem ri
	LEFT JOIN Relational.RedemptionItem_TradeUpValue tuv
		ON ri.RedeemID = tuv.RedeemID
	LEFT JOIN Relational.Partner pa
		ON tuv.PartnerID = pa.PartnerID
	
	CREATE CLUSTERED INDEX CIX_RedeemID ON #RedemptionItem (RedeemID)

	DECLARE @MaxTranID BIGINT = (SELECT COALESCE(MAX(TranID), 0) FROM [MI].[RedemptionProfitability])

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT *
	INTO #Trans
	FROM SLC_Report..Trans tr
	WHERE ID > @MaxTranID
	AND TypeID = 3
	AND EXISTS (SELECT 1
				FROM #RedemptionItem ri
				WHERE tr.ItemID = ri.RedeemID)

	INSERT INTO [MI].[RedemptionProfitability]
	SELECT ri.PartnerID
		 , ri.PartnerName
		 , ri.RedeemID
		 , ri.RedeemType
		 , ri.PrivateDescription
		 , ri.TradeUp_ClubCashRequired
		 , ri.TradeUp_Value
		 , tr.FanID
		 , tr.Price
		 , tr.Date
		 , tr.ID AS TranID
		 , IncomeBeforePostage
		 , CASE
				WHEN DATEDIFF(DAY, COALESCE(mrd.MaxRedeemDate, cas.ActivatedDate), Date) < 0 THEN 0
				ELSE DATEDIFF(DAY, COALESCE(mrd.MaxRedeemDate, cas.ActivatedDate), Date)
		   END AS DaysSinceLastRedemption
	FROM #RedemptionItem ri
	INNER JOIN #Trans tr
		ON ri.RedeemID = tr.ItemID
	INNER JOIN [MI].[CustomerActiveStatus] cas
		ON tr.FanID = cas.FanID
	LEFT JOIN (SELECT FanID
					, MAX(Date) AS MaxRedeemDate
			   FROM [MI].[RedemptionProfitability] rp
			   GROUP BY FanID) mrd
		ON tr.FanID = mrd.FanID
	LEFT JOIN [Staging].[RedemptionItem_CommercialTerms] ct
		ON ri.RedeemID = ct.RedeemID
		AND tr.Date BETWEEN ct.StartDate AND COALESCE(ct.EndDate, GETDATE())
	WHERE NOT EXISTS (SELECT 1
					  FROM [MI].[RedemptionProfitability] rp
					  WHERE tr.ID = rp.TranID)

END