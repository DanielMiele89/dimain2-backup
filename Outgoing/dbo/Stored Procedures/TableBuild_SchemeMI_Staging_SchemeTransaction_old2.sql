/*
SchemeMI.Staging_SchemeTransaction is the reference copy. 
This stored procedure identifies the difference between yesterday's version and today's version
and saves the difference as a table. The table is used to update the reference copy and could either
be sent to REWARDBI to do the same there, or the copy of the table on REWARDBI could be kept current by replication
from the reference copy. 
*/
create PROCEDURE [dbo].[TableBuild_SchemeMI_Staging_SchemeTransaction_old2]

AS

-- The existing process in LegacyPortal takes about 6 hours

DECLARE 
	@msg VARCHAR(1000), 
	@time DATETIME = GETDATE(), 
	@SSMS BIT = 1, 
	@RowsAffected BIGINT, 
	@FromDate DATE = DATEADD(DAY,-28,GETDATE())

SELECT @FromDate = '20190730'


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

SET @msg = 'Running collection for date [' + CONVERT(VARCHAR(10), @FromDate,103) + ']'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


EXEC [SchemeMI].[Process_Staging_Customer]
SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished Process_Staging_Customer: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;
SELECT p.PartnerMatchID, p.BrandID, b.RBSFunded 
INTO #PartnerAlternate
FROM Warehouse.MI.vwPartnerAlternate p 
LEFT JOIN OPENQUERY(lsREWARDBI,'SELECT * FROM LoyaltyPortal.SchemeMI.BrandList') b 
	ON p.BrandID = b.BrandID

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
		[RBSFunded] = 0, --CASE WHEN p.RBSFunded = 0 AND 0 = 0 THEN 2 ELSE 1 END, -- 
		pt.PaymentMethodID,
		cu.GenderID, cu.AgeBandID, cu.BankID, cu.RainbowID, cu.ChannelPreferenceID, cu.ActivationMethodID,
		[IsEarn] = CAST(CASE WHEN pt.CashbackEarned = 0 THEN 0 ELSE 1 END AS BIT),
		[OfferAboveBase] = ISNULL(pt.AboveBase,0),
		[AddedDateTime] = CAST(pt.AddedDate AS SMALLDATETIME)
	FROM Warehouse.Relational.PartnerTrans pt
	INNER JOIN Warehouse.Relational.[Partner] p ON pt.PartnerID = p.PartnerID
	INNER JOIN Warehouse.MI.SchemeTransUniqueID s ON pt.MatchID = s.MatchID
	INNER JOIN Warehouse.RBSMIPortal.Customer_ST cu ON pt.FanID = cu.FanID
	WHERE pt.EligibleForCashback = 1
		AND pt.AddedDate = @FromDate
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
	SpendAtBaseCust = CASE WHEN OfferAboveBase = 0 THEN FanID ELSE NULL END,
	[SpendAboveBaseCust] = CAST(NULL AS INT), -- ############################################################
	EarnAtBaseCust = CASE WHEN OfferAboveBase = 0 AND IsEarn = 1 THEN FanID ELSE NULL END,
	EarnAboveBaseCust = CASE WHEN OfferAboveBase = 1 AND IsEarn = 1 THEN FanID ELSE NULL END,
	EarnCust = CASE WHEN IsEarn = 1 THEN FanID ELSE NULL END,
	[AddedDateTime], [IronOfferID], RBSFunded,
	SpendAtBase = CASE WHEN OfferAboveBase = 0 THEN Spend WHEN OfferAboveBase = 1 THEN 0 ELSE NULL END, 
	SpendAboveBase = CASE WHEN OfferAboveBase = 0 THEN 0 WHEN OfferAboveBase = 1 THEN Spend ELSE NULL END,		
	EarningsAtBase = CASE WHEN OfferAboveBase = 0 THEN Earnings WHEN OfferAboveBase = 1 THEN 0 ELSE NULL END,
	EarningsAboveBase = CASE WHEN OfferAboveBase = 0 THEN 0 WHEN OfferAboveBase = 1 THEN Earnings ELSE NULL END,
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
	[RBSFunded] = 0, --CASE WHEN p.RBSFunded = 0 AND a.AdditionalCashbackAwardTypeID = 0 THEN 2 ELSE 1 END,
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
LEFT JOIN Warehouse.Relational.[Partner] p 
	ON pt.PartnerID = p.PartnerID
INNER JOIN Warehouse.RBSMIPortal.Customer_ST cu 
	ON a.FanID = cu.FanID
WHERE a.AddedDate = @FromDate
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
	SpendAtBaseCust = CASE WHEN OfferAboveBase = 0 THEN FanID ELSE NULL END,
	[SpendAboveBaseCust] = CAST(NULL AS INT), -- ############################################################
	EarnAtBaseCust = CASE WHEN OfferAboveBase = 0 AND IsEarn = 1 THEN FanID ELSE NULL END,
	EarnAboveBaseCust = CASE WHEN OfferAboveBase = 1 AND IsEarn = 1 THEN FanID ELSE NULL END,
	EarnCust = CASE WHEN IsEarn = 1 THEN FanID ELSE NULL END,
	[AddedDateTime], [IronOfferID],
	RBSFunded,
	SpendAtBase = CASE WHEN OfferAboveBase = 0 THEN Spend WHEN OfferAboveBase = 1 THEN 0 ELSE NULL END, 
	SpendAboveBase = CASE WHEN OfferAboveBase = 0 THEN 0 WHEN OfferAboveBase = 1 THEN Spend ELSE NULL END,		
	EarningsAtBase = CASE WHEN OfferAboveBase = 0 THEN Earnings WHEN OfferAboveBase = 1 THEN 0 ELSE NULL END,
	EarningsAboveBase = CASE WHEN OfferAboveBase = 0 THEN 0 WHEN OfferAboveBase = 1 THEN Earnings ELSE NULL END,
	[GenderID], [AgeBandID], [BankID], [RainbowID], [ChannelPreferenceID],
	[ActivationMethodID], [AdditionalCashbackAwardTypeID], [PaymentMethodID]--,
	--RowHash = BINARY_CHECKSUM(*)	
FROM FirstLayer2

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished FirstLayer2: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

CREATE UNIQUE CLUSTERED INDEX cx_Stuff ON #SchemeTransaction (AddedDate, FanID, MatchID, AdditionalCashbackAwardTypeID) WITH (DATA_COMPRESSION = PAGE) -- 00:15:07
--CREATE UNIQUE           INDEX ux_Stuff ON #SchemeTransaction (AddedDate, FanID, MatchID, AdditionalCashbackAwardTypeID) INCLUDE (RowHash) WITH (DATA_COMPRESSION = PAGE) -- 00:02:42

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished indexing #SchemeTransaction: '; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;



----------------------------------------------------------------------------------------------------
-- Identify the workload
----------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#ActionTable') IS NOT NULL DROP TABLE #ActionTable;
SELECT 
	FanID = ISNULL(t.FanID, s.FanID), 
	AddedDate = ISNULL(t.AddedDate, s.AddedDate),  
	MatchID = ISNULL(t.MatchID, s.MatchID), 
	AdditionalCashbackAwardTypeID = ISNULL(t.AdditionalCashbackAwardTypeID, s.AdditionalCashbackAwardTypeID),
	RowHash = ISNULL(t.RowHash, s.RowHash), 
	x.[Action]
INTO #ActionTable
FROM (
	SELECT * 
	FROM SchemeMI.Staging_SchemeTransaction 
	WHERE AddedDate = @FromDate
) s 
FULL OUTER JOIN (
	SELECT *, RowHash = BINARY_CHECKSUM(MatchID, FanID, Spend, Earnings, AddedDate, BrandID, OfferAboveBase,
	TranWeekID, TranMonthID, IsEarn, SpendAtBaseCust, SpendAboveBaseCust,
	EarnAtBaseCust, EarnAboveBaseCust, EarnCust, AddedDateTime, IronOfferID,
	RBSFunded, 
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	GenderID, AgeBandID, BankID, RainbowID, ChannelPreferenceID,
	ActivationMethodID, AdditionalCashbackAwardTypeID, PaymentMethodID) 
	FROM #SchemeTransaction
) t 
	ON t.FanID = s.FanID 
	AND t.AddedDate = s.AddedDate 
	AND t.MatchID = s.MatchID 
	AND t.AdditionalCashbackAwardTypeID = s.AdditionalCashbackAwardTypeID
CROSS APPLY (
	SELECT [Action] = CASE 
		WHEN t.FanID IS NULL THEN 'D'
		WHEN s.FanID IS NULL THEN 'I'
		WHEN s.RowHash <> t.RowHash THEN 'E'
		ELSE NULL END
) x
WHERE x.[Action] IS NOT NULL
-- (0 rows affected) / 00:30:00

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished identifying workload: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #ActionTable (AddedDate, FanID, MatchID, AdditionalCashbackAwardTypeID) -- 00:00:05



----------------------------------------------------------------------------------------------------
-- DELETEs 
-- UPDATEs (delete+insert)
----------------------------------------------------------------------------------------------------
DELETE s
FROM SchemeMI.Staging_SchemeTransaction s WITH (TABLOCK)
INNER JOIN #ActionTable t 
ON t.AddedDate = s.AddedDate 
	AND t.FanID = s.FanID 
	AND t.MatchID = s.MatchID 
	AND t.AdditionalCashbackAwardTypeID = s.AdditionalCashbackAwardTypeID
WHERE t.[Action] IN ('D', 'E')

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished deletes: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;



----------------------------------------------------------------------------------------------------
-- INSERTs 
----------------------------------------------------------------------------------------------------
INSERT INTO SchemeMI.Staging_SchemeTransaction WITH (TABLOCK) (
	s.AddedDate, s.FanID, s.MatchID, s.AdditionalCashbackAwardTypeID, 
	Spend, Earnings, BrandID, OfferAboveBase, TranWeekID, TranMonthID, 
	IsEarn, SpendAtBaseCust, SpendAboveBaseCust, EarnAtBaseCust, EarnAboveBaseCust, 
	EarnCust, AddedDateTime, IronOfferID, RBSFunded, 
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	GenderID, AgeBandID, BankID, RainbowID, ChannelPreferenceID,
	ActivationMethodID, PaymentMethodID, 
	RowHash
)
SELECT 
	s.AddedDate, s.FanID, s.MatchID, s.AdditionalCashbackAwardTypeID, 
	Spend, Earnings, BrandID, OfferAboveBase, TranWeekID, TranMonthID, 
	IsEarn, SpendAtBaseCust, SpendAboveBaseCust, EarnAtBaseCust, EarnAboveBaseCust, 
	EarnCust, AddedDateTime, IronOfferID, RBSFunded, 
	SpendAtBase, SpendAboveBase, EarningsAtBase, EarningsAboveBase,
	GenderID, AgeBandID, BankID, RainbowID, ChannelPreferenceID,
	ActivationMethodID, PaymentMethodID, 
	n.RowHash 
FROM #SchemeTransaction s WITH (TABLOCK)
INNER JOIN #ActionTable n
	ON n.AddedDate = s.AddedDate
	AND	n.FanID = s.FanID	
	AND	n.MatchID = s.MatchID	
	AND	n.AdditionalCashbackAwardTypeID = s.AdditionalCashbackAwardTypeID	
	AND n.[Action] IN ('I','E')
ORDER BY s.AddedDate, s.FanID, s.MatchID, s.AdditionalCashbackAwardTypeID
-- (27908957 rows affected) / 00:21:23

SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Finished inserts: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

-- UPDATE STATISTICS SchemeMI.Staging_SchemeTransaction WITH FULLSCAN -- 00:16:25

/*
2019-08-28T08:11:23.657 :  Run started  >>>>>  Time Taken: 00:00:00
2019-08-28T08:11:35.387 :  Finished FirstLayer1: 880319 rows  >>>>>  Time Taken: 00:00:12
2019-08-28T08:13:26.660 :  Finished FirstLayer2: 13403016 rows  >>>>>  Time Taken: 00:01:51
2019-08-28T08:13:50.757 :  Finished indexing #SchemeTransaction:   >>>>>  Time Taken: 00:00:24
2019-08-28T08:14:17.723 :  Finished identifying workload: 781831 rows  >>>>>  Time Taken: 00:00:27
2019-08-28T08:14:23.670 :  Finished deletes: 0 rows  >>>>>  Time Taken: 00:00:06
2019-08-28T08:14:56.860 :  Finished inserts: 781831 rows  >>>>>  Time Taken: 00:00:33
*/

RETURN 0



