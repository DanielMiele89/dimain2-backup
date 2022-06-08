/*
SchemeMI.Staging_SchemeTransaction is the reference copy. 
This stored procedure identifies the difference between yesterday's version and today's version
and saves the difference as a table. The table is used to update the reference copy and could either
be sent to REWARDBI to do the same there, or the copy of the table on REWARDBI could be kept current by replication
from the reference copy. 
*/
create PROCEDURE [dbo].[TableBuild_SchemeMI_Staging_SchemeTransaction_Bulkloader]

	(@FromDate DATE)

AS

-- The existing process in LegacyPortal takes about 6 hours

DECLARE 
	@msg VARCHAR(1000), 
	@time DATETIME = GETDATE(), 
	@SSMS BIT = 1, 
	@RowsAffected BIGINT


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

SET @msg = 'Running collection for date [' + CONVERT(VARCHAR(10), @FromDate,103) + ']'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


-----------------------------------------------------------------------------------------------------------------
-- Get customer details
-- Note the differences between the old method and the new method. 
-- GenderID, 1 row in 437,722
-- AgeBandID 798 rows in 437,722 (they've got older)
-- ActivationMethodID 99 rows in 437,722
-----------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#CustomerStuff') IS NOT NULL DROP TABLE #CustomerStuff;
SELECT FanID, GenderID, AgeBandID, BankID, RainbowID, ChannelPreferenceID, ActivationMethodID 
INTO #CustomerStuff
FROM OPENQUERY(lsREWARDBI,'SELECT FanID, GenderID, AgeBandID, BankID, RainbowID, ChannelPreferenceID, ActivationMethodID FROM LoyaltyPortal.SchemeMI.Staging_Customer WITH (NOLOCK)')

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished Processing Customer: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #CustomerStuff (FanID)



IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;
SELECT p.PartnerMatchID, p.BrandID, b.RBSFunded 
INTO #PartnerAlternate
FROM Warehouse.MI.vwPartnerAlternate p 
LEFT JOIN OPENQUERY(lsREWARDBI,'SELECT * FROM LoyaltyPortal.SchemeMI.BrandList') b 
	ON p.BrandID = b.BrandID

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished Processing PartnerAlternate: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #PartnerAlternate (PartnerMatchID)


IF OBJECT_ID('tempdb..#SchemeTransaction') IS NOT NULL DROP TABLE #SchemeTransaction;
SELECT 
	s.MatchID, s.FanID, Spend, Earnings, s.AddedDate, BrandID, OfferAboveBase,
	TranWeekID, TranMonthID, IsEarn, SpendAtBaseCust, SpendAboveBaseCust,
	EarnAtBaseCust, EarnAboveBaseCust, EarnCust, AddedDateTime, IronOfferID,
	RBSFunded, 
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	GenderID, AgeBandID, BankID, RainbowID, ChannelPreferenceID,
	ActivationMethodID, s.AdditionalCashbackAwardTypeID, PaymentMethodID--, 
	--RowHash
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
		pt.PaymentMethodID,
		cu.GenderID, cu.AgeBandID, cu.BankID, cu.RainbowID, cu.ChannelPreferenceID, cu.ActivationMethodID,
		[IsEarn] = CAST(CASE WHEN pt.CashbackEarned = 0 THEN 0 ELSE 1 END AS BIT),
		[OfferAboveBase] = ISNULL(pt.AboveBase,0),
		[AddedDateTime] = CAST(pt.AddedDate AS SMALLDATETIME)
	FROM Warehouse.Relational.PartnerTrans pt
	INNER JOIN #PartnerAlternate p 
		ON pt.PartnerID = p.PartnerMatchID
	INNER JOIN Warehouse.MI.SchemeTransUniqueID s 
		ON pt.MatchID = s.MatchID
	--INNER JOIN Warehouse.RBSMIPortal.Customer_ST cu 
	INNER JOIN #CustomerStuff cu
		ON pt.FanID = cu.FanID
	WHERE pt.EligibleForCashback = 1
		AND pt.AddedDate BETWEEN @FromDate AND EOMONTH(@FromDate)
)

INSERT INTO #SchemeTransaction WITH (TABLOCK) (
	MatchID, FanID, Spend, Earnings, AddedDate, BrandID, OfferAboveBase, 
	TranWeekID, TranMonthID, IsEarn, SpendAtBaseCust, SpendAboveBaseCust,
	EarnAtBaseCust, EarnAboveBaseCust, EarnCust, AddedDateTime, IronOfferID, RBSFunded, 
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	GenderID, AgeBandID, BankID, RainbowID, ChannelPreferenceID,
	ActivationMethodID, s.AdditionalCashbackAwardTypeID, PaymentMethodID--, 
	--RowHash
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
	[AddedDateTime], [IronOfferID], RBSFunded,
	SpendAtBase = CASE WHEN OfferAboveBase = 0 THEN Spend ELSE 0 END, 
	SpendAboveBase = CASE WHEN OfferAboveBase = 1 THEN Spend ELSE 0 END,		
	EarningsAtBase = CASE WHEN OfferAboveBase = 0 THEN Earnings ELSE 0 END,
	EarningsAboveBase = CASE WHEN OfferAboveBase = 1 THEN Earnings ELSE 0 END,
	[GenderID], [AgeBandID], [BankID], [RainbowID], [ChannelPreferenceID],
	[ActivationMethodID], [AdditionalCashbackAwardTypeID], [PaymentMethodID]--,
	--RowHash = BINARY_CHECKSUM(*) 	
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
	a.PaymentMethodID,
	cu.GenderID, cu.AgeBandID, cu.BankID, cu.RainbowID, cu.ChannelPreferenceID, cu.ActivationMethodID,
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
--INNER JOIN Warehouse.RBSMIPortal.Customer_ST cu 
INNER JOIN #CustomerStuff cu
	ON a.FanID = cu.FanID
WHERE a.AddedDate BETWEEN @FromDate AND EOMONTH(@FromDate)
)

INSERT INTO #SchemeTransaction WITH (TABLOCK) (
	MatchID, FanID, Spend, Earnings, AddedDate, BrandID, OfferAboveBase,
	TranWeekID, TranMonthID, IsEarn, SpendAtBaseCust, SpendAboveBaseCust,
	EarnAtBaseCust, EarnAboveBaseCust, EarnCust, AddedDateTime, IronOfferID, RBSFunded, 
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	GenderID, AgeBandID, BankID, RainbowID, ChannelPreferenceID,
	ActivationMethodID, AdditionalCashbackAwardTypeID, PaymentMethodID--, 
	--RowHash
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
	RBSFunded,
	SpendAtBase = CASE WHEN OfferAboveBase = 0 THEN Spend ELSE 0 END, 
	SpendAboveBase = CASE WHEN OfferAboveBase = 1 THEN Spend ELSE 0 END,		
	EarningsAtBase = CASE WHEN OfferAboveBase = 0 THEN Earnings ELSE 0 END,
	EarningsAboveBase = CASE WHEN OfferAboveBase = 1 THEN Earnings ELSE 0 END,
	[GenderID], [AgeBandID], [BankID], [RainbowID], [ChannelPreferenceID],
	[ActivationMethodID], [AdditionalCashbackAwardTypeID], [PaymentMethodID]--,
	--RowHash = BINARY_CHECKSUM(*)	
FROM FirstLayer2

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished FirstLayer2: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

--CREATE  CLUSTERED INDEX cx_Stuff ON #SchemeTransaction (AddedDate, FanID, MatchID, AdditionalCashbackAwardTypeID) WITH (DATA_COMPRESSION = PAGE) -- 00:15:07

--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished indexing #SchemeTransaction: '; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;



----------------------------------------------------------------------------------------------------
-- Output for REWARDBI
----------------------------------------------------------------------------------------------------
SELECT MatchID, FanID, Spend, Earnings, AddedDate, BrandID, OfferAboveBase,
	TranWeekID, TranMonthID, IsEarn, SpendAtBaseCust, SpendAboveBaseCust,
	EarnAtBaseCust, EarnAboveBaseCust, EarnCust, AddedDateTime, IronOfferID, RBSFunded, 
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	GenderID, AgeBandID, BankID, RainbowID, ChannelPreferenceID,
	ActivationMethodID, AdditionalCashbackAwardTypeID, PaymentMethodID 
FROM #SchemeTransaction


RETURN 0



