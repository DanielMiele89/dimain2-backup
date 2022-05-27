


-- =============================================
-- Author:		JEA
-- Create date: 09/09/2014
-- Description:	Retrieves CBP retailer transactions
-- for Reward BI population
-- =============================================
CREATE PROCEDURE [RewardBI].[PartnerTrans_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT pt.PartnerTransID AS SourceID
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned AS EarningsTotal
		, pt.TransactionDate AS TranDate
		, pt.AddedDate
		, pt.FanID AS CustomerID
		, p.PartnerID AS PartnerID
		, p.PartnerName AS RetailerName
		, CAST (2 AS TINYINT) AS PublisherID
		, CAST('Penny For London' AS VARCHAR(50)) AS PublisherName
		, CAST(0 AS TINYINT) AS PaymentChannelID
		, CAST(0 AS INT) AS OfferID
		, CAST(0 AS BIT) as AboveBase
		, CAST('Unknown' AS VARCHAR(50)) AS PaymentMethod
		, o.OutletID
		, CAST(0 AS MONEY) AS PublisherCommission
		, CAST(0 AS MONEY) AS RewardCommission
	FROM Relational.PartnerTrans pt
	INNER JOIN Relational.[Partner] p ON pt.PartnerID = p.PartnerID
	INNER JOIN Warehouse.RewardBI.Outlet_AllSchemes o ON PT.OutletID = O.SourceOutletID AND o.SchemeID = 2

END



