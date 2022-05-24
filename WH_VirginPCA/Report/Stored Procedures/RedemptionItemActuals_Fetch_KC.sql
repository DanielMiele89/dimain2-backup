CREATE PROC [Report].[RedemptionItemActuals_Fetch_KC] (@MonthStartDate DATE, @MonthEndDate DATE)
AS
SET NOCOUNT ON;
BEGIN

--DECLARE @MonthStartDate AS DATE = '2019-08-01', @MonthEndDate AS DATE = '2021-08-31'

--Drop Temp Tables to be used to populate monthly dataset
IF OBJECT_ID('tempdb.dbo.#Redemptions') IS NOT NULL
 DROP TABLE dbo.#Redemptions;

IF OBJECT_ID('tempdb.dbo.#MyRewardsEAYB') IS NOT NULL
 DROP TABLE dbo.#MyRewardsEAYB;

IF OBJECT_ID('tempdb.dbo.#MyRewardsRedemptionsVandOPartnerName') IS NOT NULL
 DROP TABLE dbo.#MyRewardsRedemptionsVandOPartnerName;


--Populate Redemptions
SELECT
PartnerID
,RedeemDate
,Cancelled
,CashbackUsed
,RedemptionDescription
,RedeemType
INTO #Redemptions
  FROM [Warehouse].[Relational].[Redemptions] r
  WHERE r.RedeemDate >= @MonthStartDate AND r.RedeemDate < @MonthEndDate
  --CAST( DATEADD(YEAR, -2, GETDATE()) AS DATE)


  
--Add Indexes to #Redemptions
CREATE NONCLUSTERED INDEX ix_tempRedemptionsPartnerID ON #Redemptions ([PartnerID])
CREATE NONCLUSTERED INDEX ix_tempRedemptionsRedeemDate ON #Redemptions ([RedeemDate])


--Populate #MyRewardsEAYB
SELECT	'MyRewards' AS BankID
	,	adj.AddedDate as ConfirmedDate
--,	DATEFROMPARTS(YEAR(adj.AddedDate), MONTH(adj.AddedDate),1) AS MONthDate
	,	subcat.[Description] as OfferName
	,	adj.CashbackEarned
	,	LEFT(subcat.[Description], CHARINDEX('£',subcat.[Description]) - 1) partnerName
INTO #MyRewardsEAYB
FROM Warehouse.Relational.AdditionalCashbackAdjustment adj
INNER JOIN Warehouse.Relational.AdditionalCashbackAdjustmentType subcat -- See the Warehouse.WHB.AdditionalCashbackAward_Adjustment_AmazONRedemptions stored procedure for setting up this dependency
	ON adj.AdditionalCashbackAdjustmentTypeID = subcat.AdditionalCashbackAdjustmentTypeID
WHERE 
	--adj.AddedDate >= '2012-01-01'
	adj.AddedDate >= @MonthStartDate AND adj.AddedDate < @MonthEndDate
	AND subcat.AdditionalCashbackAdjustmentCategoryID = 4 -- EAYB redemptions

--Add Indexes to #MyRewardsEAYB
CREATE NONCLUSTERED INDEX ix_tempRedemptionsEAYBPartnerName ON #MyRewardsEAYB ([PartnerName])
CREATE NONCLUSTERED INDEX ix_tempRedemptionsEAYBConfirmedDate ON #MyRewardsEAYB ([ConfirmedDate])



--Populate #MyRewardsRedemptionsVandOPartnerName
SELECT 'MyRewards' AS BankID
	,	CASE
			WHEN p.PartnerName = 'Currys & PC World' THEN 'Currys PC World'
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
INTO #MyRewardsRedemptionsVandOPartnerName
FROM #Redemptions r 
LEFT OUTER JOIN Warehouse.Relational.[Partner] p 
ON r.PartnerID = p.PartnerID
--WHERE r.RedeemDate >= '2012-01-01'
WHERE r.RedeemDate >= @MonthStartDate AND r.RedeemDate < @MonthEndDate

--Add Indexes to #MyRewardsRedemptionsVandOPartnerName
CREATE NONCLUSTERED INDEX ix_tempMyRewardsRedemptionsVandOPartnerName ON #MyRewardsRedemptionsVandOPartnerName ([PartnerName])


--Populate Report DataSet for Month
	--;WITH VisaRedemptions AS (
								SELECT	r.BankID
									,	PartnerName
									,	ConfirmedDate
									,	Amount
									,	CashbackEarned AS EAYB
									,	'£' +cASt(ri.amount AS varchar(max)) +' '+ rp.PartnerName + ' Gift Card + ' + cASt(ro.TradeUp_MarketingPercentage AS varchar(max)) + '% back in Rewards'  AS 'OfferName'
									,	RedemptionType
								INTO #VisaRedemptions
								FROM derived.Redemptions r
								JOIN derived.RedemptionItems ri 
								ON ri.RedemptionItemID = r.TradeUp_RedemptionItemID
								JOIN derived.RedemptionPartners rp
								ON r.RedemptionPartnerGUID = rp.RedemptionPartnerGUID
								JOIN Derived.RedemptionOffers ro
								ON r.RedemptionOfferGUID = ro.RedemptionOfferGUID
								--where ConfirmedDate >= CAST( DATEADD(YEAR, -2, GETDATE()) AS DATE)
								where ConfirmedDate >= @MonthStartDate AND ConfirmedDate < @MonthEndDate
	--),MyRewardsRedemptionsVandO AS (
										--SELECT * FROM #MyRewardsRedemptionsVandOPartnerName

	--),MyRewardsEAYB AS (
						--SELECT * FROM #MyRewardsEAYB
	--)
	SELECT *
	FROM #VisaRedemptions
	UNION ALL 
	SELECT	rr.BankID
		,	rr.PartnerName
		,	rr.ConfirmedDate
		,	rr.Amount
		,	re.CashbackEarned AS EAYB
		,	rr.OfferName
		,	rr.RedeemType
	FROM #MyRewardsRedemptionsVandOPartnerName rr
	JOIN #MyRewardsEAYB re
	ON rr.ConfirmedDate = re.ConfirmedDate
	AND rr.PartnerName = re.partnerName

END





--SELECT * FROM dbo.#Redemptions;
--SELECT DISTINCT ConfirmedDate FROM dbo.#MyRewardsEAYB WHERE PartnerName = 'John Lewis Partnership' ORDER BY ConfirmedDate;
--SELECT  DISTINCT ConfirmedDate FROM dbo.#MyRewardsRedemptionsVandOPartnerName WHERE PartnerName = 'John Lewis Partnership' ORDER BY ConfirmedDate;
