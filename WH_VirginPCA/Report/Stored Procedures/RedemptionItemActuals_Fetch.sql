
/****** Script for SelectTopNRows command FROM SSMS  ******/

CREATE PROCEDURE [Report].[RedemptionItemActuals_Fetch] 

AS 
BEGIN


	;WITH VisaRedemptions AS (
								SELECT	r.BankID
									,	PartnerName
									,	ConfirmedDate
									,	Amount
									,	CashbackEarned AS EAYB
									,	'£' +cASt(ri.amount AS varchar(max)) +' '+ rp.PartnerName + ' Gift Card + ' + cASt(ro.TradeUp_MarketingPercentage AS varchar(max)) + '% back in Rewards'  AS 'OfferName'
									,	RedemptionType
								FROM derived.Redemptions r
								JOIN derived.RedemptionItems ri 
								ON ri.RedemptionItemID = r.TradeUp_RedemptionItemID
								JOIN derived.RedemptionPartners rp
								ON r.RedemptionPartnerGUID = rp.RedemptionPartnerGUID
								JOIN Derived.RedemptionOffers ro
								ON r.RedemptionOfferGUID = ro.RedemptionOfferGUID
								where ConfirmedDate >= CAST( DATEADD(YEAR, -2, GETDATE()) AS DATE)
	),MyRewardsRedemptionsVandO AS (
									SELECT 'MyRewards' AS BankID
										,	CASE
												WHEN p.PartnerName = 'Currys & PC World' THEN 'Currys PC World'
												WHEN p.PartnerName IS NULL THEN ''
											ELSE p.PartnerName
											END AS PartnerName
										,	cast(left(RedeemDate,9) as date) AS 'ConfirmedDate'
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
									FROM Warehouse.Relational.Redemptions r 
									LEFT OUTER JOIN Warehouse.Relational.[Partner] p 
									ON r.PartnerID = p.PartnerID
									--WHERE r.RedeemDate >= '2012-01-01'
									WHERE r.RedeemDate >= CAST( DATEADD(YEAR, -2, GETDATE()) AS DATE)

	),MyRewardsEAYB AS (
						SELECT	'MyRewards' AS BankID
							,	adj.AddedDate as ConfirmedDate
						--,	DATEFROMPARTS(YEAR(adj.AddedDate), MONTH(adj.AddedDate),1) AS MONthDate
							,	subcat.[Description] as OfferName
							,	adj.CashbackEarned
							,	LEFT(subcat.[Description], CHARINDEX('£',subcat.[Description]) - 1) partnerName
						FROM Warehouse.Relational.AdditionalCashbackAdjustment adj
						INNER JOIN Warehouse.Relational.AdditionalCashbackAdjustmentType subcat -- See the Warehouse.WHB.AdditionalCashbackAward_Adjustment_AmazONRedemptions stored procedure for setting up this dependency
							ON adj.AdditionalCashbackAdjustmentTypeID = subcat.AdditionalCashbackAdjustmentTypeID
						WHERE 
							--adj.AddedDate >= '2012-01-01'
							adj.AddedDate >= CAST( DATEADD(YEAR, -2, GETDATE()) AS DATE)
							AND subcat.AdditionalCashbackAdjustmentCategoryID = 4 -- EAYB redemptions
	), MyRewardsTotal AS (
							SELECT	rr.BankID
								,	rr.PartnerName
								,	rr.ConfirmedDate
								,	rr.Amount
								,	re.CashbackEarned AS EAYB
								,	rr.OfferName
								,	rr.RedeemType
							FROM MyRewardsRedemptionsVandO rr
							JOIN MyRewardsEAYB re
							ON rr.ConfirmedDate = re.ConfirmedDate
							AND rr.PartnerName = re.partnerName
	)
	SELECT *
	FROM VisaRedemptions
	UNION ALL 
	SELECT *
	FROM MyRewardsTotal


END





