	CREATE PROC [Report].[RedemptionItemActuals_Fetch_EAYB_WA] (@MonthStartDate DATE, @MonthEndDate DATE)
	AS
	SET NOCOUNT ON;
	BEGIN

	--DECLARE @MonthStartDate AS DATE = '2019-08-01', @MonthEndDate AS DATE = '2021-08-31'


	IF OBJECT_ID('tempdb.dbo.#MyRewardsEAYB') IS NOT NULL
	 DROP TABLE dbo.#MyRewardsEAYB;
	SELECT	--TranID
			'MyRewards' AS BankID
		--,	adj.AddedDate as ConfirmedDate
	,	DATEFROMPARTS(YEAR(adj.AddedDate), MONTH(adj.AddedDate),1) AS ConfirmedDate
		,	subcat.[Description] as OfferName
		,	adj.CashbackEarned as EAYB
		,	LEFT(subcat.[Description], CHARINDEX('£',subcat.[Description]) - 1) partnerName
	INTO #MyRewardsEAYB
	FROM Warehouse.Relational.AdditionalCashbackAdjustment_incTranID adj
	INNER JOIN Warehouse.Relational.AdditionalCashbackAdjustmentType subcat -- See the Warehouse.WHB.AdditionalCashbackAward_Adjustment_AmazONRedemptions stored procedure for setting up this dependency
		ON adj.AdditionalCashbackAdjustmentTypeID = subcat.AdditionalCashbackAdjustmentTypeID
	WHERE 
		--adj.AddedDate >= '2012-01-01'
		--adj.AddedDate >= @MonthStartDate AND adj.AddedDate < @MonthEndDate
		adj.AddedDate >= '2019-08-01' AND adj.AddedDate <'2020-08-01'	
		AND subcat.AdditionalCashbackAdjustmentCategoryID = 4 -- EAYB redemptions

		
		

	--Add Indexes to #MyRewardsEAYB
	CREATE NONCLUSTERED INDEX ix_tempRedemptionsEAYB ON #MyRewardsEAYB ([PartnerName],[ConfirmedDate])
	

	--Populate #MyRewardsRedemptionsVandOPartnerName
	

	IF OBJECT_ID('tempdb..#VisaRedemptions') IS NOT NULL DROP TABLE #VisaRedemptions
	SELECT	r.BankID
		,	DATEFROMPARTS(YEAR(ConfirmedDate), MONTH(ConfirmedDate),1) AS ConfirmedDate
		,	'£' +cASt(ri.amount AS varchar(max)) +' '+ rp.PartnerName + ' Gift Card + ' + cASt(ro.TradeUp_MarketingPercentage AS varchar(max)) + '% back in Rewards'  AS 'OfferName'
		,	CashbackEarned AS EAYB
		,	PartnerName
	INTO #VisaRedemptions
	FROM derived.Redemptions r
	left JOIN derived.RedemptionItems ri 
	ON ri.RedemptionItemID = r.TradeUp_RedemptionItemID
	left JOIN derived.RedemptionPartners rp
	ON r.RedemptionPartnerGUID = rp.RedemptionPartnerGUID
	JOIN Derived.RedemptionOffers ro
	ON r.RedemptionOfferGUID = ro.RedemptionOfferGUID
	--where ConfirmedDate >= CAST( DATEADD(YEAR, -2, GETDATE()) AS DATE)
	--where ConfirmedDate >= @MonthStartDate AND ConfirmedDate < @MonthEndDate
	where ConfirmedDate >= '2020-08-01' AND ConfirmedDate < '2021-08-01'

	
	--IF OBJECT_ID('tempdb..#MyRewardsRedemptionsGrouped') IS NOT NULL 
	--	DROP TABLE #MyRewardsRedemptionsGrouped
	--select BankID,PartnerName,ConfirmedDate, sum(amount) amount,sum(CashbackEarned)CashbackEarned,offername,RedeemType
	--into #MyRewardsRedemptionsGrouped
	--from #MyRewardsRedemptionsVandOPartnerName
	--group by BankID,offername,PartnerName,ConfirmedDate,RedeemType



		SELECT BankID as 'Bankid'
			,	ConfirmedDate as 'Confirmeddate'
			,	OfferName as 'Offername'
			,	EAYB as 'eayb'
			,	PartnerName as 'Partnername'
		FROM #VisaRedemptions
		UNION ALL 
		SELECT	*
		--into #temp
		--FROM #MyRewardsRedemptionsGrouped rr
		FROM #MyRewardsEAYB rr
		


	END