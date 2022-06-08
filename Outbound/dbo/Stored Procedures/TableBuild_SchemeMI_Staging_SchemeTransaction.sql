/*
Called by [dbo].[TableBuild_SchemeMI_Staging_SchemeTransaction] on REWARDBI
Run daily at 9am by Agent job PR23
*/
-- The existing process in LegacyPortal takes about 6 hours
CREATE PROCEDURE [dbo].[TableBuild_SchemeMI_Staging_SchemeTransaction]

	(@FromDate DATE)

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE 
	@msg VARCHAR(1000), 
	@time DATETIME = GETDATE(), 
	@SSMS BIT = 1, 
	@RowsAffected BIGINT

DECLARE @ToDate DATE = DATEADD(day,-5,GETDATE());
--DECLARE @ToDate DATE = DATEADD(day,-3,GETDATE()); -- just for testing today



IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;
SELECT p.PartnerMatchID, p.BrandID, b.RBSFunded 
INTO #PartnerAlternate
FROM Warehouse.MI.vwPartnerAlternate p 
LEFT JOIN OPENQUERY(lsREWARDBI,'SELECT * FROM LoyaltyPortal.SchemeMI.BrandList') b 
	ON p.BrandID = b.BrandID

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished Processing PartnerAlternate: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #PartnerAlternate (PartnerMatchID)


-- Create an empty table with the right structure
IF OBJECT_ID('tempdb..#SchemeTransaction') IS NOT NULL DROP TABLE #SchemeTransaction;
SELECT 
	s.MatchID, s.FanID, Spend, Earnings, s.AddedDate, BrandID, OfferAboveBase,
	TranWeekID, TranMonthID, IsEarn, SpendAtBaseCust, SpendAboveBaseCust,
	EarnAtBaseCust, EarnAboveBaseCust, EarnCust, AddedDateTime, IronOfferID,
	RBSFunded, IsRBS,
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	s.AdditionalCashbackAwardTypeID, PaymentMethodID
INTO #SchemeTransaction
FROM SchemeMI.Staging_SchemeTransaction s
WHERE 0 = 1

;WITH FirstLayer1 AS (
	SELECT 
		pt.AddedDate,
		pt.FanID,
		s.SchemeTransID, 
		CAST(0 AS TINYINT) AS AdditionalCashbackAwardTypeID,
		pt.TransactionAmount AS Spend,
		pt.CashbackEarned AS Earnings,
		p.BrandID,
		[TranWeekID] = DATEDIFF(WEEK,'2011-11-23',pt.AddedDate), 
		[TranMonthID] = DATEDIFF(MONTH,'2011-11-01',pt.AddedDate),
		pt.IronOfferID,
		[RBSFunded] = CASE WHEN p.RBSFunded = 0 AND 0 = 0 THEN 2 ELSE 1 END, -- 

		CAST(CASE WHEN a.MatchID IS NOT NULL THEN 1 WHEN b.ChargeOnRedeem = 1 THEN 1 ELSE 0 END AS BIT) AS IsRBS,

		pt.PaymentMethodID,
		[IsEarn] = CAST(CASE WHEN pt.CashbackEarned = 0 THEN 0 ELSE 1 END AS BIT),
		[OfferAboveBase] = ISNULL(pt.AboveBase,0),
		[AddedDateTime] = CAST(pt.AddedDate AS SMALLDATETIME)
	FROM Warehouse.Relational.PartnerTrans pt
	INNER JOIN #PartnerAlternate p 
		ON pt.PartnerID = p.PartnerMatchID
	INNER JOIN Warehouse.MI.SchemeTransUniqueID s 
		ON pt.MatchID = s.MatchID
	LEFT OUTER JOIN Warehouse.Relational.Brand b 
		ON b.BrandID = p.BrandID

	LEFT OUTER JOIN (
		SELECT MatchID, SUM(CashbackEarned) AS CashbackEarned
		FROM Warehouse.Relational.AdditionalCashbackAward
		WHERE matchid IS NOT NULL
		GROUP BY MatchID
	) a ON pt.MatchID = a.MatchID

	WHERE pt.EligibleForCashback = 1
		AND pt.AddedDate >= @FromDate AND pt.AddedDate <= @ToDate
)

INSERT INTO #SchemeTransaction WITH (TABLOCK) (
	MatchID, FanID, Spend, Earnings, AddedDate, BrandID, OfferAboveBase, 
	TranWeekID, TranMonthID, IsEarn, SpendAtBaseCust, SpendAboveBaseCust,
	EarnAtBaseCust, EarnAboveBaseCust, EarnCust, AddedDateTime, IronOfferID, RBSFunded, IsRBS,
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	s.AdditionalCashbackAwardTypeID, PaymentMethodID
	)
SELECT 
	[MatchID] = SchemeTransID, -- yes, really
	[FanID], [Spend], [Earnings], [AddedDate], [BrandID], [OfferAboveBase],
	[TranWeekID], [TranMonthID], [IsEarn], 
	SpendAtBaseCust = CASE WHEN OfferAboveBase = 0 THEN FanID ELSE 0 END,
	[SpendAboveBaseCust] = CASE WHEN OfferAboveBase = 1 THEN FanID ELSE 0 END, 
	EarnAtBaseCust = CASE WHEN OfferAboveBase = 0 AND IsEarn = 1 THEN FanID ELSE 0 END,
	EarnAboveBaseCust = CASE WHEN OfferAboveBase = 1 AND IsEarn = 1 THEN FanID ELSE 0 END,
	EarnCust = CASE WHEN IsEarn = 1 THEN FanID ELSE 0 END,
	[AddedDateTime], [IronOfferID], RBSFunded, IsRBS, 
	SpendAtBase = CASE WHEN OfferAboveBase = 0 THEN Spend ELSE 0 END, 
	SpendAboveBase = CASE WHEN OfferAboveBase = 1 THEN Spend ELSE 0 END,		
	EarningsAtBase = CASE WHEN OfferAboveBase = 0 THEN Earnings ELSE 0 END,
	EarningsAboveBase = CASE WHEN OfferAboveBase = 1 THEN Earnings ELSE 0 END,
	[AdditionalCashbackAwardTypeID], [PaymentMethodID]
FROM FirstLayer1

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished FirstLayer1: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;



;WITH FirstLayer2 AS ( -- AddedDate, FanID, MatchID, AdditionalCashbackAwardTypeID
	SELECT  
		a.AddedDate, -- ### 
		a.FanID, -- ###
		s.SchemeTransID, -- ### 
		a.AdditionalCashbackAwardTypeID, -- ###
		a.Amount AS Spend,
		a.CashbackEarned AS Earnings,
		ISNULL(p.BrandID,0) AS BrandID,
		[TranWeekID] = DATEDIFF(WEEK,'2011-11-23',a.AddedDate), 
		[TranMonthID] = DATEDIFF(MONTH,'2011-11-01',a.AddedDate), 
		CAST(NULL AS INT) AS IronOfferID,
		[RBSFunded] = CASE WHEN P.RBSFunded = 0 
			THEN 2 ELSE 1 END,

		CAST(1 AS BIT) AS IsRBS,

		a.PaymentMethodID,
		[IsEarn] = CAST(CASE WHEN a.CashbackEarned = 0 THEN 0 ELSE 1 END AS BIT),
		[OfferAboveBase] = CAST(0 AS BIT),
		[AddedDateTime] = CAST(a.AddedDate AS SMALLDATETIME)
	FROM Warehouse.Relational.AdditionalCashbackAward a
	INNER JOIN Warehouse.MI.SchemeTransUniqueID s	
		ON a.FileID = s.FileID and a.RowNum = s.RowNum
	LEFT JOIN Warehouse.Relational.PartnerTrans pt 
		ON a.MatchID = pt.MatchID
	LEFT JOIN #PartnerAlternate p 
		ON pt.PartnerID = p.PartnerMatchID
	WHERE a.AddedDate >= @FromDate AND a.AddedDate <= @ToDate
)

INSERT INTO #SchemeTransaction WITH (TABLOCK) (
	MatchID, FanID, Spend, Earnings, AddedDate, BrandID, OfferAboveBase,
	TranWeekID, TranMonthID, IsEarn, SpendAtBaseCust, SpendAboveBaseCust,
	EarnAtBaseCust, EarnAboveBaseCust, EarnCust, AddedDateTime, IronOfferID, RBSFunded, IsRBS,
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	AdditionalCashbackAwardTypeID, PaymentMethodID
	)
SELECT 
	[MatchID] = SchemeTransID, -- yes, really
	[FanID], [Spend], [Earnings], [AddedDate], [BrandID], [OfferAboveBase],
	[TranWeekID], [TranMonthID], [IsEarn], 
	SpendAtBaseCust = CASE WHEN OfferAboveBase = 0 THEN FanID ELSE 0 END,
	[SpendAboveBaseCust] = CAST(0 AS INT), 
	EarnAtBaseCust = CASE WHEN OfferAboveBase = 0 AND IsEarn = 1 THEN FanID ELSE 0 END,
	EarnAboveBaseCust = CASE WHEN OfferAboveBase = 1 AND IsEarn = 1 THEN FanID ELSE 0 END,
	EarnCust = CASE WHEN IsEarn = 1 THEN FanID ELSE 0 END,
	[AddedDateTime], [IronOfferID],
	RBSFunded, IsRBS,
	SpendAtBase = CASE WHEN OfferAboveBase = 0 THEN Spend ELSE 0 END, 
	SpendAboveBase = CASE WHEN OfferAboveBase = 1 THEN Spend ELSE 0 END,		
	EarningsAtBase = CASE WHEN OfferAboveBase = 0 THEN Earnings ELSE 0 END,
	EarningsAboveBase = CASE WHEN OfferAboveBase = 1 THEN Earnings ELSE 0 END,
	[AdditionalCashbackAwardTypeID], [PaymentMethodID]
FROM FirstLayer2

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished FirstLayer2: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;



----------------------------------------------------------------------------------------------------
-- Output for REWARDBI
----------------------------------------------------------------------------------------------------
SELECT MatchID, FanID, Spend, Earnings, AddedDate, BrandID, OfferAboveBase,
	TranWeekID, TranMonthID, IsEarn, SpendAtBaseCust, SpendAboveBaseCust,
	EarnAtBaseCust, EarnAboveBaseCust, EarnCust, AddedDateTime, IronOfferID, RBSFunded, IsRBS,
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	AdditionalCashbackAwardTypeID, PaymentMethodID 
FROM #SchemeTransaction


RETURN 0



