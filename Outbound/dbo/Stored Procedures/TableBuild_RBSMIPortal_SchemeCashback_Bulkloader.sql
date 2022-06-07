/* ----------------------------------------------------------------------------------------------------------
Grab data for the day, 4 days ago.
Add this one-day grab to the DIMAIN Inbound tables. Don't accumulate more than 7 days' data in these two grab tables.
For each affected target table in DIMAIN / LoyaltyPortal, set up a view in the Inbound db which matches the columns required by the table
*/ ----------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[TableBuild_RBSMIPortal_SchemeCashback_Bulkloader]

	(@FromDate DATE)

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	@msg VARCHAR(1000), 
	@time DATETIME = GETDATE(), 
	@SSMS BIT = 1, 
	@RowsAffected BIGINT


----- Was [MI].[RBSMIPortal_SchemeCashback_PartnerTrans_Fetch]
TRUNCATE TABLE Staging.SchemeCashback;
INSERT INTO Staging.SchemeCashback (
	[SchemeTransID],
	[FanID],
	[Spend],
	[Cashback],
	[AddedDate],
	[TranDate],
	[PartnerID],
	[PartnerName],
	[AdditionalCashbackAwardTypeID],
	[AdditionalCashbackAdjustmentTypeID],
	[AdditionalCashbackAdjustmentCategoryID],
	[DDCategory],
	[OfferAboveBase],
	[PaymentMethodID],
	[PaymentMethod],
	[OfferName],
	[ActivationDays],
	[PartnerMatchID]
)
SELECT s.SchemeTransID
	, pt.FanID
	, pt.TransactionAmount AS Spend
	, pt.CashbackEarned AS Cashback
	, pt.AddedDate
	, pt.TransactionDate AS TranDate
	, p.PartnerID
	, p.PartnerName
	, CAST(0 AS TINYINT) AS AdditionalCashbackAwardTypeID
	, CAST(0 AS TINYINT) AS AdditionalCashbackAdjustmentTypeID
	, CAST(0 AS TINYINT) AS AdditionalCashbackAdjustmentCategoryID
	, CAST('' AS VARCHAR(50)) AS DDCategory
	, CAST(pt.AboveBase AS BIT) AS OfferAboveBase
	, pt.PaymentMethodID
	, pm.[Description] AS PaymentMethod
	, CAST(COALESCE(e.ClientServicesRef, h.OfferName, cast(i.IronOfferName as varchar(200)), '') AS VARCHAR(200)) AS OfferName
	, pt.ActivationDays
	, p.PartnerID AS PartnerMatchID
FROM Warehouse.Relational.PartnerTrans pt 
INNER JOIN Warehouse.MI.vwPartnerAlternate p 
	ON pt.PartnerID = p.PartnerMatchID
INNER JOIN Warehouse.MI.SchemeTransUniqueID s 
	ON pt.MatchID = s.MatchID
INNER JOIN Warehouse.Relational.PaymentMethod pm 
	ON pt.PaymentMethodID = pm.PaymentMethodID
LEFT OUTER JOIN Warehouse.Relational.IronOffer i 
	ON pt.IronOfferID = i.IronOfferID
LEFT OUTER JOIN Warehouse.Staging.IronOffer_Campaign_EPOCU e 
	ON pt.IronOfferID = e.OfferID
LEFT OUTER JOIN (
		SELECT o.IronOfferID, o.ClientServicesRef AS OfferName, c.CampaignName AS OfferDesc
		FROM Warehouse.Relational.IronOffer_Campaign_HTM o
		LEFT OUTER JOIN Warehouse.Relational.CBP_CampaignNames c 
			ON O.ClientServicesRef = c.ClientServicesRef
	) h ON pt.IronOfferID = h.IronOfferID
WHERE pt.AddedDate BETWEEN @FromDate AND EOMONTH(@FromDate)
SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished grab 1 of 3: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- 145,699 / 00:02:20



----- Was [MI].[RBSMIPortal_SchemeCashback_AdditCashbackAward_Fetch]
INSERT INTO Staging.SchemeCashback (
	[SchemeTransID],
	[FanID],
	[Spend],
	[Cashback],
	[AddedDate],
	[TranDate],
	[PartnerID],
	[PartnerName],
	[AdditionalCashbackAwardTypeID],
	[AdditionalCashbackAdjustmentTypeID],
	[AdditionalCashbackAdjustmentCategoryID],
	[DDCategory],
	[OfferAboveBase],
	[PaymentMethodID],
	[PaymentMethod],
	[OfferName],
	[ActivationDays],
	[PartnerMatchID]
)
SELECT s.SchemeTransID
	, ac.FanID
	, ac.Amount AS Spend
	, ac.CashbackEarned AS Cashback
	, ac.AddedDate
	, ac.TranDate
	, ISNULL(p.PartnerID,0) AS PartnerID
	, ISNULL(p.PartnerName, 'Unbranded') AS PartnerName
	, ac.AdditionalCashbackAwardTypeID AS AdditionalCashbackAwardTypeID
	, CAST(0 AS TINYINT) AS AdditionalCashbackAdjustmentTypeID
	, CAST(0 AS TINYINT) AS AdditionalCashbackAdjustmentCategoryID
	, CAST(ISNULL(m.PortalCategory, '') AS VARCHAR(50)) AS DDCategory
	, CAST(0 AS BIT) AS OfferAboveBase
	, ac.PaymentMethodID
	, pm.[Description] AS PaymentMethod
	, at.[Description] AS OfferName
	, ac.ActivationDays
	, CAST(0 AS INT) AS PartnerMatchID
FROM Warehouse.Relational.AdditionalCashbackAward ac 
INNER JOIN Warehouse.MI.SchemeTransUniqueID s 
	ON ac.FileID = s.FileID AND ac.RowNum = s.RowNum
LEFT OUTER JOIN Warehouse.Relational.PartnerTrans pt 
	ON ac.MatchID = pt.MatchID
LEFT OUTER JOIN Warehouse.MI.vwPartnerAlternate p 
	ON pt.PartnerID = p.PartnerMatchID
INNER JOIN Warehouse.Relational.AdditionalCashbackAwardType at 
	ON ac.AdditionalCashbackAwardTypeID = at.AdditionalCashbackAwardTypeID
LEFT OUTER JOIN Warehouse.Relational.DirectDebitOriginator dd 
	ON ac.DirectDebitOriginatorID = dd.ID
LEFT OUTER JOIN Warehouse.RBSMIPortal.DDCategoryMap m 
	ON dd.[Category2] = m.DDCategory
INNER JOIN Warehouse.Relational.PaymentMethod pm 
	ON ac.PaymentMethodID = pm.PaymentMethodID
INNER JOIN Warehouse.Relational.Customer cu 
	ON ac.FanID = cu.FanID
WHERE ac.AddedDate BETWEEN @FromDate AND EOMONTH(@FromDate)
SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished grab 2 of 3: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- 1,300,162 / 00:00:57


----- Was [MI].[RBSMIPortal_SchemeCashback_AdditCashbackAdjust_Fetch]
INSERT INTO Staging.SchemeCashback (
	--[SchemeTransID],
	[FanID],
	[Spend],
	[Cashback],
	[AddedDate],
	[TranDate],
	[PartnerID],
	[PartnerName],
	[AdditionalCashbackAwardTypeID],
	[AdditionalCashbackAdjustmentTypeID],
	[AdditionalCashbackAdjustmentCategoryID],
	[DDCategory],
	[OfferAboveBase],
	[PaymentMethodID],
	[PaymentMethod],
	[OfferName],
	[ActivationDays],
	[PartnerMatchID]
)
SELECT ac.FanID
	, CAST(0 AS MONEY) AS Spend
	, ac.CashbackEarned AS Cashback
	, ac.AddedDate
	, ac.AddedDate AS TranDate
	, CAST(0 AS INT) AS PartnerID
	, CAST('Unbranded' AS VARCHAR(50)) AS PartnerName
	, CAST(0 AS TINYINT) AS AdditionalCashbackAwardTypeID
	, ac.AdditionalCashbackAdjustmentTypeID
	, at.AdditionalCashbackAdjustmentCategoryID
	, CAST('' AS VARCHAR(50)) AS DDCategory
	, CAST(0 AS BIT) AS OfferAboveBase
	, CAST(-1 AS SMALLINT) AS PaymentMethodID
	, CAST('Award' AS VARCHAR(50)) AS PaymentMethod
	, c.Category AS OfferName
	, ac.ActivationDays
	, CAST(0 AS INT) AS PartnerMatchID
FROM Warehouse.Relational.AdditionalCashbackAdjustment ac 
INNER JOIN Warehouse.Relational.AdditionalCashbackAdjustmentType at 
	ON ac.AdditionalCashbackAdjustmentTypeID = at.AdditionalCashbackAdjustmentTypeID
INNER JOIN Warehouse.Relational.AdditionalCashbackAdjustmentCategory c 
	ON at.AdditionalCashbackAdjustmentCategoryID = c.AdditionalCashbackAdjustmentCategoryID
INNER JOIN Warehouse.Relational.Customer cu 
	ON ac.FanID = cu.FanID
WHERE c.AdditionalCashbackAdjustmentCategoryID > 1
	AND ac.AddedDate BETWEEN @FromDate AND EOMONTH(@FromDate);
SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished grab 3 of 3: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
-- 149 / 00:00:01


--------------------------------------------------------------------------------------------------------------------
-- Output the resultset
-- This will be grabbed and staged in REWARDBI
--------------------------------------------------------------------------------------------------------------------
SELECT 	
	[SchemeTransID],
	[FanID],
	[Spend],
	[Cashback],
	[AddedDate],
	[TranDate],
	[PartnerID],
	[PartnerName],
	[AdditionalCashbackAwardTypeID],
	[AdditionalCashbackAdjustmentTypeID],
	[AdditionalCashbackAdjustmentCategoryID],
	[DDCategory],
	[OfferAboveBase],
	[PaymentMethodID],
	[PaymentMethod],
	[OfferName],
	[ActivationDays],
	[PartnerMatchID]
FROM [Outbound].[Staging].[SchemeCashback] WITH (TABLOCK);


RETURN 0





