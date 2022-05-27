-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.RedemptionProfitability_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate DATE

	SET @MonthDate = DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)

    SELECT 
		MonthDate
		, RedeemType
		, RedeemPartner
		, Age
		, CameoGroup
		, Gender
		, CAST(CASE WHEN RedemptionOrdinal = 1 THEN 1 ELSE 0 END AS BIT) AS IsFirstRedemption
		, Charity
		, CASE WHEN CustomerActiveMonths <=5 THEN 'Up to 6 Months' 
			ELSE CASE WHEN CustomerActiveMonths > 5 AND CustomerActiveMonths <= 11 THEN '6-12 Months'
			ELSE CASE WHEN CustomerActiveMonths > 11 AND CustomerActiveMonths <= 23 THEN '1-2 Years'
			ELSE 'Over 2 Years' END END END AS ActiveWhenRedeemed
		, SUM(Cashback) as Cashback
		, SUM(TradeUp_Value) AS TradeUpValue
		, SUM(RewardIncome) AS RewardIncome
	FROM
	(
		SELECT r.TranID
			, r.FanID
			, DATEFROMPARTS(YEAR(r.redeemdate),MONTH(r.redeemdate),1) as MonthDate
			, CASE r.RedeemType WHEN 'AccClose' THEN 'Account Closure'
				WHEN 'Charity' THEN 'Charity'
				WHEN 'Trade Up' THEN 'Trade Up'
				ELSE CASE WHEN RedemptionDescription LIKE '%credit card%' THEN 'Cash To Credit Card'
					ELSE 'Cash To Account' END END as RedeemType
			, ISNULL(p.PartnerName, 'No Partner') As RedeemPartner
			, FLOOR(DATEDIFF(DAY, c.DOB, r.RedeemDate)/365.25) as Age
			, ISNULL(cg.CAMEO_CODE_GROUP_category, 'Unknown') AS CameoGroup
			, c.Gender
			, ROW_NUMBER() OVER (PARTITION BY r.FanID ORDER BY r.TranID) AS RedemptionOrdinal
			, CASE WHEN r.RedeemType = 'Charity' THEN REPLACE(REPLACE(r.RedemptionDescription, 'Donate to ', ''), 'Donation to ', '') ELSE 'No Charity' END AS Charity
			, CASE WHEN DATEDIFF(MONTH, a.ActivatedDate, r.RedeemDate) < 0 THEN 0 ELSE ISNULL(DATEDIFF(MONTH, a.ActivatedDate, r.RedeemDate),0) END AS CustomerActiveMonths
			, r.CashbackUsed AS Cashback
			, isnull(r.TradeUp_Value,r.CashbackUsed) AS TradeUp_Value
			, ISNULL(i.RewardIncome,0) AS RewardIncome
		from Relational.Redemptions r with (nolock)
		inner join Relational.Customer c with (nolock) on r.FanID = c.FanID
		left outer join Relational.[Partner] p on r.PartnerID = p.PartnerID
		left outer join InsightArchive.RedemptionIncome i on r.PartnerID = i.PartnerID and r.TradeUp_Value = i.TradeUp_Value and r.CashbackUsed = i.CashbackUsed
		left outer join Relational.CAMEO ca on c.PostCode = ca.Postcode
		left outer join Relational.CAMEO_CODE_GROUP cg on ca.CAMEO_CODE_GROUP = cg.CAMEO_CODE_GROUP
		inner join MI.CustomerActiveStatus a on c.FanID = a.FanID
		where r.cancelled = 0
		and r.RedeemDate  >= '2015-07-01' AND r.RedeemDate < @MonthDate

	) r
	GROUP BY MonthDate
		, RedeemType
		, RedeemPartner
		, Age
		, CameoGroup
		, Gender
		, CAST(CASE WHEN RedemptionOrdinal = 1 THEN 1 ELSE 0 END AS BIT)
		, Charity
		, CASE WHEN CustomerActiveMonths <=5 THEN 'Up to 6 Months' 
			ELSE CASE WHEN CustomerActiveMonths > 5 AND CustomerActiveMonths <= 11 THEN '6-12 Months'
			ELSE CASE WHEN CustomerActiveMonths > 11 AND CustomerActiveMonths <= 23 THEN '1-2 Years'
			ELSE 'Over 2 Years' END END END

END
