CREATE PROC [Report].[RedemptionItemActuals_Fetch_KC] (@MonthStartDate DATE, @MonthEndDate DATE)
AS
SET NOCOUNT ON;
BEGIN


--DECLARE @MonthStartDate AS DATE = '2019-08-01', @MonthEndDate AS DATE = '2021-08-31'

	--Populate Redemptions
	IF OBJECT_ID('tempdb.dbo.#Redemptions') IS NOT NULL
	DROP TABLE dbo.#Redemptions;
	SELECT	TranID
	,PartnerID
	,RedeemDate
	,Cancelled
	,CashbackUsed
	,RedemptionDescription
	,RedeemType
	INTO #Redemptions
	FROM [Warehouse].[Relational].[Redemptions] r
	WHERE r.RedeemDate >= @MonthStartDate AND r.RedeemDate < @MonthEndDate
	

	CREATE CLUSTERED INDEX ix_tempRedemptions ON #Redemptions ([TranID])

	IF OBJECT_ID('tempdb.dbo.#RedemtionOffers') IS NOT NULL
	DROP TABLE dbo.#RedemtionOffers;
	select t.itemID,r.*
	into #RedemtionOffers
	from #Redemptions r
	INNER JOIN [SLC_Report].[dbo].[Trans] t
	on r.TranID = t.ID

  
--Add Indexes to #RedemtionOffers
	CREATE NONCLUSTERED INDEX ix_tempRedemptionsPartnerID ON #RedemtionOffers ([PartnerID],[redeemDate])
	
	
	IF OBJECT_ID('tempdb.dbo.#MyRewardsEAYB') IS NOT NULL
	DROP TABLE dbo.#MyRewardsEAYB;
	SELECT 'MyRewards' AS BankID
	, ri.RedeemType
	, ri.RedeemID
	, subcat.[Description] as OfferName
	, aca.AdditionalCashbackAdjustmentTypeID
	, subcat.AdditionalCashbackAdjustmentCategoryID
	, LEFT(subcat.[Description], CHARINDEX('£',subcat.[Description]) - 1) partnerName
	--,	 CASE 
	--		WHEN ri.RedeemType = 'Charity' AND ri.PrivateDescription != 'Donate to the NET’s Coronavirus Appeal & we will match your donation until we reach £5million'
	--		THEN SUBSTRING(PrivateDescription, CHARINDEX('to', PrivateDescription)+3, LEN(PrivateDescription))
	--		WHEN ri.RedeemType = 'Charity' AND ri.PrivateDescription = 'Donate to the NET’s Coronavirus Appeal & we will match your donation until we reach £5million'
	--		THEN  'NET’s Coronavirus Appeal'
	--		ELSE LEFT(subcat.[Description], CHARINDEX('£',subcat.[Description]) - 1)
	--	END AS partnerName
	, aca.AddedDate as ConfirmedDate
	, aca.CashbackEarned
	, aca.TranID AS TranID_EAYB
	, t2.ID AS TranID_Redemption
	INTO #MyRewardsEAYB
	FROM [Warehouse].[Relational].[AdditionalCashbackAdjustment_incTranID] aca
	INNER JOIN [Warehouse].[Relational].[AdditionalCashbackAdjustmentType] subcat -- See the Warehouse.WHB.AdditionalCashbackAward_Adjustment_AmazONRedemptions stored procedure for setting up this dependency
	ON aca.AdditionalCashbackAdjustmentTypeID = subcat.AdditionalCashbackAdjustmentTypeID
	INNER JOIN [SLC_Report].[dbo].[Trans] t WITH (NOLOCK)
	ON aca.TranID = t.ID
	LEFT JOIN [SLC_Report].[dbo].[Trans] t2 WITH (NOLOCK)
	ON t.ItemID = t2.ID
	LEFT JOIN [Warehouse].[Relational].[RedemptionItem] ri
	ON t2.ItemID = ri.RedeemID
	WHERE subcat.AdditionalCashbackAdjustmentCategoryID = 4
	AND aca.AddedDate >= @MonthStartDate AND aca.AddedDate < @MonthEndDate
	
	
	--Populate #MyRewardsRedemptionsVandOPartnerName
	IF OBJECT_ID('tempdb.dbo.#MyRewardsRedemptionsVandOPartnerName') IS NOT NULL
	 DROP TABLE dbo.#MyRewardsRedemptionsVandOPartnerName;
	SELECT 'MyRewards' AS BankID
	,	CASE
			--WHEN p.PartnerName = 'Currys & PC World' THEN 'Currys PC World'
			--WHEN p.PartnerName IS NULL THEN ''
		WHEN RedeemType = 'Charity' AND RedemptionDescription != 'Donate to the NET’s Coronavirus Appeal & we will match your donation until we reach £5million'
			THEN SUBSTRING(RedemptionDescription, CHARINDEX('to', RedemptionDescription)+3, LEN(RedemptionDescription))
			WHEN RedeemType = 'Charity' AND RedemptionDescription = 'Donate to the NET’s Coronavirus Appeal & we will match your donation until we reach £5million'
			THEN  'NET’s Coronavirus Appeal'
			WHEN p.PartnerName = 'Currys & PC World' and RedeemType != 'Charity' THEN 'Currys PC World'
			WHEN p.PartnerName IS NULL THEN ''
		ELSE p.PartnerName
		END AS PartnerName
	,	cast(RedeemDate as date) AS 'ConfirmedDate'
	,	CASE 
			WHEN r.Cancelled = 0 THEN CashbackUsed 
			ELSE CAST(0 AS MONEY) 
		END AS Amount
	,	r.CashbackUsed AS 'CashbackEarned'
	,	CASE r.RedemptionDescription WHEN 'Pay towards your eligible Reward credit card' THEN 'Cash to Credit Card'
			WHEN 'Pay into your RBS Current Account' THEN 'Cash to Account' 
			WHEN 'Pay into your NatWest Current Account' THEN 'Cash to Account'
			ELSE r.RedemptionDescription 
		END AS OfferName
	,	RedeemType
	, TranID
	INTO #MyRewardsRedemptionsVandOPartnerName
	FROM #RedemtionOffers r 
	LEFT OUTER JOIN Warehouse.Relational.[Partner] p 
	ON r.PartnerID = p.PartnerID
	WHERE r.RedeemDate >= @MonthStartDate AND r.RedeemDate < @MonthEndDate
	
	--Add Indexes to #MyRewardsRedemptionsVandOPartnerName
	CREATE NONCLUSTERED INDEX ix_tempMyRewardsRedemptionsVandOPartnerName ON #MyRewardsRedemptionsVandOPartnerName ([PartnerName])


	IF OBJECT_ID('tempdb.dbo.#VisaRedemptions') IS NOT NULL
	 DROP TABLE dbo.#VisaRedemptions;
	SELECT	r.BankID
		,	PartnerName
		,	ConfirmedDate
		,	CashbackUsed Amount
		,	CashbackEarned AS EAYB
		,	'£' +cASt(ri.amount AS varchar(max)) +' '+ rp.PartnerName + ' Gift Card + ' + cASt(ro.TradeUp_MarketingPercentage AS varchar(max)) + '% back in Rewards'  AS 'OfferName'
		,	RedemptionType
	INTO #VisaRedemptions
	FROM derived.Redemptions r
	LEFT JOIN derived.RedemptionItems ri 
	ON ri.RedemptionItemID = r.TradeUp_RedemptionItemID
	JOIN derived.RedemptionPartners rp
	ON r.RedemptionPartnerGUID = rp.RedemptionPartnerGUID
	JOIN Derived.RedemptionOffers ro
	ON r.RedemptionOfferGUID = ro.RedemptionOfferGUID
	where ConfirmedDate >= @MonthStartDate AND ConfirmedDate < @MonthEndDate
	

	SELECT *
	FROM #VisaRedemptions
	UNION ALL 
	SELECT	rr.BankID
		,	REPLACE(REPLACE(rr.PartnerName,'''',''),'’','')
		,	rr.ConfirmedDate
		,	rr.Amount
		,	re.CashbackEarned AS EAYB
		,	REPLACE(rr.OfferName, ',', '') 
		,	rr.RedeemType
	FROM #MyRewardsRedemptionsVandOPartnerName rr
	left JOIN #MyRewardsEAYB re
	ON rr.TranID = re.TranID_Redemption
END



--SELECT * FROM dbo.#Redemptions;
--SELECT DISTINCT ConfirmedDate FROM dbo.#MyRewardsEAYB WHERE PartnerName = 'John Lewis Partnership' ORDER BY ConfirmedDate;
--SELECT  DISTINCT ConfirmedDate FROM dbo.#MyRewardsRedemptionsVandOPartnerName WHERE PartnerName = 'John Lewis Partnership' ORDER BY ConfirmedDate;