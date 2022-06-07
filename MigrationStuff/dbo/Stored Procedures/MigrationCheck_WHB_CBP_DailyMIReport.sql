CREATE PROCEDURE [dbo].[MigrationCheck_WHB_CBP_DailyMIReport] AS 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @RowCount BIGINT

IF 1 = 1 BEGIN
	IF OBJECT_ID('tempdb..#CustomerDIMAIN2') IS NOT NULL DROP TABLE #CustomerDIMAIN2;
	SELECT [Customer ID], [Bank ID], [hash] = CHECKSUM(
		[E-mail Address],
		[Mobile Number],
		[Bank ID],
		[Is Marketing Suppressed SMS],
		[Is Marketing Suppressed Email],
		[Is Marketing Suppressed DM],
		[Opted Out],
		[Opted Out Date],
		[Currently Active],
		[Activation Channel],
		[Activated By Credit Card],
		[Activated Date],
		[Is Registered],
		[Total Transaction Amount Debit],
		[Total Transaction Amount Credit],
		[Total Transaction Amount DD],
		[Total Transaction Count Debit],
		[Total Transaction Count Credit],
		[Total Transaction Count DD],
		--[Cashback Balance - Pending],
		--[CASHBACK BALANCE – CLEARED],
		[Total Redeemed Value],
		[REDEEMED VALUE CASH TO BANK ACCOUNT],
		[REDEEMED VALUE CASH TO CREDIT CARD],
		[REDEEMED VALUE IN TRADEUP],
		[REDEEMED VALUE IN CHARITY],
		[CONTACT HISTORY],
		[EMAIL HARDBOUNCED]	) 
	INTO #CustomerDIMAIN2
	FROM Warehouse.MI.CBP_DailyMIReport
	SET @RowCount = @@ROWCOUNT
	CREATE UNIQUE CLUSTERED INDEX ucx_FanID ON #CustomerDIMAIN2 ([Customer ID], [Bank ID])
	-- (4760081 rows affected) / 00:00:15

	IF OBJECT_ID('tempdb..#CustomerDIDEVTEST') IS NOT NULL DROP TABLE #CustomerDIDEVTEST;
	SELECT [Customer ID], [Bank ID], [hash] 
	INTO #CustomerDIDEVTEST 
	FROM OPENQUERY (DIDEVTEST, 'SELECT [Customer ID], [Bank ID], [hash] = CHECKSUM(
		[E-mail Address],
		[Mobile Number],
		[Bank ID],
		[Is Marketing Suppressed SMS],
		[Is Marketing Suppressed Email],
		[Is Marketing Suppressed DM],
		[Opted Out],
		[Opted Out Date],
		[Currently Active],
		[Activation Channel],
		[Activated By Credit Card],
		[Activated Date],
		[Is Registered],
		[Total Transaction Amount Debit],
		[Total Transaction Amount Credit],
		[Total Transaction Amount DD],
		[Total Transaction Count Debit],
		[Total Transaction Count Credit],
		[Total Transaction Count DD],
		--[Cashback Balance - Pending],
		--[CASHBACK BALANCE – CLEARED],
		[Total Redeemed Value],
		[REDEEMED VALUE CASH TO BANK ACCOUNT],
		[REDEEMED VALUE CASH TO CREDIT CARD],
		[REDEEMED VALUE IN TRADEUP],
		[REDEEMED VALUE IN CHARITY],
		[CONTACT HISTORY],
		[EMAIL HARDBOUNCED]	) FROM Warehouse.MI.CBP_DailyMIReport')
	CREATE UNIQUE CLUSTERED INDEX ucx_FanID ON #CustomerDIDEVTEST ([Customer ID], [Bank ID])
	-- (4760081 rows affected) / 00:00:15

	IF OBJECT_ID('tempdb..#CustomerDIMAIN') IS NOT NULL DROP TABLE #CustomerDIMAIN;
	SELECT [Customer ID], [Bank ID], [hash] 
	INTO #CustomerDIMAIN 
	FROM OPENQUERY (DIMAIN, 'SELECT [Customer ID], [Bank ID], [hash] = CHECKSUM(
		[E-mail Address],
		[Mobile Number],
		[Bank ID],
		[Is Marketing Suppressed SMS],
		[Is Marketing Suppressed Email],
		[Is Marketing Suppressed DM],
		[Opted Out],
		[Opted Out Date],
		[Currently Active],
		[Activation Channel],
		[Activated By Credit Card],
		[Activated Date],
		[Is Registered],
		[Total Transaction Amount Debit],
		[Total Transaction Amount Credit],
		[Total Transaction Amount DD],
		[Total Transaction Count Debit],
		[Total Transaction Count Credit],
		[Total Transaction Count DD],
		--[Cashback Balance - Pending],
		--[CASHBACK BALANCE – CLEARED],
		[Total Redeemed Value],
		[REDEEMED VALUE CASH TO BANK ACCOUNT],
		[REDEEMED VALUE CASH TO CREDIT CARD],
		[REDEEMED VALUE IN TRADEUP],
		[REDEEMED VALUE IN CHARITY],
		[CONTACT HISTORY],
		[EMAIL HARDBOUNCED]	) FROM Warehouse.MI.CBP_DailyMIReport')
	CREATE UNIQUE CLUSTERED INDEX ucx_FanID ON #CustomerDIMAIN ([Customer ID], [Bank ID])
	-- (4760081 rows affected) / 00:00:15
END
-- 00:02:55

SELECT TableName = 'MI.CBP_DailyMIReport', [Date] = GETDATE(), [RowCount] = @RowCount


;WITH NewRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT [Customer ID], [Bank ID] FROM #CustomerDIDEVTEST EXCEPT SELECT [Customer ID], [Bank ID] FROM #CustomerDIMAIN2) d -- 0
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT [Customer ID], [Bank ID] FROM #CustomerDIMAIN2 EXCEPT SELECT [Customer ID], [Bank ID] FROM #CustomerDIDEVTEST) d -- 0
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT [Customer ID], [Bank ID] FROM #CustomerDIMAIN EXCEPT SELECT [Customer ID], [Bank ID] FROM #CustomerDIDEVTEST) d -- 0
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT [Customer ID], [Bank ID] FROM #CustomerDIDEVTEST EXCEPT SELECT [Customer ID], [Bank ID] FROM #CustomerDIMAIN) d -- 0
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT [Customer ID], [Bank ID] FROM #CustomerDIMAIN2 EXCEPT SELECT [Customer ID], [Bank ID] FROM #CustomerDIMAIN) d -- 0
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT [Customer ID], [Bank ID] FROM #CustomerDIMAIN EXCEPT SELECT [Customer ID], [Bank ID] FROM #CustomerDIMAIN2) d -- 0
), ChangedRows AS (
	SELECT [Description] = 'DIDEVTEST-DIMAIN2', [RowCount] = COUNT(*) FROM (SELECT [hash] FROM #CustomerDIDEVTEST EXCEPT SELECT [hash] FROM #CustomerDIMAIN2) d -- 17
	UNION ALL SELECT 'DIMAIN2-DIDEVTEST', COUNT(*) FROM (SELECT [hash] FROM #CustomerDIMAIN2 EXCEPT SELECT [hash] FROM #CustomerDIDEVTEST) d -- 17
	UNION ALL
	SELECT 'DIMAIN-DIDEVTEST', COUNT(*) FROM (SELECT [hash] FROM #CustomerDIMAIN EXCEPT SELECT [hash] FROM #CustomerDIDEVTEST) d -- 311
	UNION ALL SELECT 'DIDEVTEST-DIMAIN', COUNT(*) FROM (SELECT [hash] FROM #CustomerDIDEVTEST EXCEPT SELECT [hash] FROM #CustomerDIMAIN) d -- 311
	UNION ALL
	SELECT 'DIMAIN2-DIMAIN', COUNT(*) FROM (SELECT [hash] FROM #CustomerDIMAIN2 EXCEPT SELECT [hash] FROM #CustomerDIMAIN) d -- 296
	UNION ALL SELECT 'DIMAIN-DIMAIN2', COUNT(*) FROM (SELECT [hash] FROM #CustomerDIMAIN EXCEPT SELECT [hash] FROM #CustomerDIMAIN2) d -- 296
)
SELECT n.[Description], n.[RowCount] AS [New rows], c.[RowCount]-n.[RowCount] AS [Changed Rows]
FROM NewRows n
INNER JOIN ChangedRows c 
	ON c.[Description] = n.[Description]
-- 6 / 00:00:59


RETURN 0







