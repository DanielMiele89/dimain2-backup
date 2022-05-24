-- =============================================
-- Author:		JEA
-- Create date: 08/05/2017
-- Description:	Redemptions by item description

------------------------------------------------
-- Alteration History

-- Jason Shipp 09/10/2018
	-- Added logic to handle change of PartnerID for Currys in Redemptions table from 04/10/2018 
-- =============================================
CREATE PROCEDURE [MI].[RedemptionItemsByMonth_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT DATEFROMPARTS(YEAR(r.RedeemDate), MONTH(r.RedeemDate),1) AS MonthDate
		, r.RedeemType
		, CASE r.RedemptionDescription WHEN 'Pay towards your eligible Reward credit card' THEN 'Cash to Credit Card'
			WHEN 'Pay into your RBS Current Account' THEN 'Cash to Account' 
			WHEN 'Pay into your NatWest Current Account' THEN 'Cash to Account'
			ELSE r.RedemptionDescription END AS ItemDesc
		, ISNULL(
			CASE WHEN p.PartnerName = 'Currys & PC World' THEN 'Currys PC World' ELSE p.PartnerName END
			, ''
		) AS [Partner]
		, SUM(CASE WHEN r.Cancelled = 0 THEN CashbackUsed ELSE CAST(0 AS MONEY) END) AS RedemptionValue
		, COUNT(*) AS RedemptionCount
	FROM Relational.Redemptions r WITH (NOLOCK)
	LEFT OUTER JOIN Relational.[Partner] p ON r.PartnerID = p.PartnerID
	WHERE r.RedeemDate >= '2012-01-01'
	GROUP BY DATEFROMPARTS(YEAR(r.RedeemDate), MONTH(r.RedeemDate),1)
		, r.RedeemType
		, CASE r.RedemptionDescription WHEN 'Pay towards your eligible Reward credit card' THEN 'Cash to Credit Card'
			WHEN 'Pay into your RBS Current Account' THEN 'Cash to Account' 
			WHEN 'Pay into your NatWest Current Account' THEN 'Cash to Account'
			ELSE r.RedemptionDescription END
		, ISNULL(CASE WHEN p.PartnerName = 'Currys & PC World' THEN 'Currys PC World' ELSE p.PartnerName END, '');

END