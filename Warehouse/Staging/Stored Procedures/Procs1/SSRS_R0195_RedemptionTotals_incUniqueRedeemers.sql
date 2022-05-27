

CREATE PROCEDURE [Staging].[SSRS_R0195_RedemptionTotals_incUniqueRedeemers] @StartDate date, @EndDate date
as 
begin 

	--declare @StartDate Date, @EndDate date

	--set @StartDate = '2017-11-01'
	--set @EndDate = '2018-12-01' --NB: set as the first of the month not to be included because redemptions have time component

	DECLARE @EndDateCalc DATETIME = DATEADD( ss, -1, DATEADD(d, 1, CONVERT(DATETIME, @Enddate)));

	SELECT	DATEFROMPARTS(year(redeemdate), month(redeemdate),1) as RedeemMonth
		,	CASE WHEN RedemptionDescription like '%credit card%' then 'Credit Card' else RedeemType end as RedeemType
		,	COUNT(*) as RedemptionCount
		,	COUNT(DISTINCT FanID) as UniqueRedeemers 
		,	SUM(re.CashbackUsed) AS ValueRedeemed
	FROM Relational.Redemptions re
	WHERE RedeemDate >= @StartDate
	AND RedeemDate <= @EndDateCalc
	AND Cancelled = 0
	GROUP BY DATEFROMPARTS(year(redeemdate), month(redeemdate),1), CASE WHEN RedemptionDescription like '%credit card%' then 'Credit Card' else RedeemType end
	ORDER BY RedeemMonth, RedeemType

end
