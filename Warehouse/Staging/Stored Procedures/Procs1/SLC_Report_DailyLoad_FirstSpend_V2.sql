/*
	Date:		07-10-2015

	Author:		Stuart Barnley

	Purpose:	To UPDATE the table that holds the first spend info

*/
CREATE PROCEDURE [Staging].[SLC_Report_DailyLoad_FirstSpend_V2]
AS
BEGIN

	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------

	INSERT INTO staging.JobLog_Temp
	SELECT	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'Customers_Passed0GBP',
			StartDate = GETDATE(),
			EndDate = NULL,
			TableRowCount  = NULL,
			AppendReload = 'A'

	DECLARE @RowNo INT = (SELECT COUNT(*) FROM Staging.Customers_Passed0GBP)

	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------

	DECLARE @OneDayAgo DATE = CONVERT(DATE, DATEADD(day, -1, GETDATE()))
		  , @TwoDayAgo DATE = CONVERT(DATE, DATEADD(day, -2, GETDATE()))

	INSERT INTO Staging.Customers_Passed0GBP (FanID
											, Date
											, FirstEarnValue
											, FirstEarnType
											, MyRewardAccount)
	SELECT f.ID AS FanID
		 , @OneDayAgo AS [Date]
		 , CONVERT(REAL, 0.00) AS FirstEarnValue
		 , '' AS FirstEarnType
		 , '' AS MyRewardAccount
	FROM [SLC_Report].[dbo].[Fan] f WITH (NOLOCK)
	WHERE f.ClubCashPending > 0
	AND f.ClubID IN (132, 138)
	AND f.AgreedTCs = 1
	AND f.Status = 1
	AND f.AgreedTCsDate IS NOT NULL
	AND NOT EXISTS (SELECT 1
					FROM Staging.Customers_Passed0GBP p
					WHERE f.ID = p.FanID)

	----------------------------------------------------------------------------
	--------------------Find Customers who passed £0.00 today-------------------
	----------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
	SELECT DISTINCT
		   p.FanID
	INTO #Customer
	FROM Staging.Customers_Passed0GBP p
	WHERE [Date] = @OneDayAgo

	CREATE CLUSTERED INDEX IX_Customer_FanID ON #Customer (FanID)

	-------------------------------------------------------------------------------------------------
	-------------------------Pull in list of ACA transaction types for assessment--------------------
	-------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#ACATranTypes') IS NOT NULL DROP TABLE #ACATranTypes
	SELECT TransactionTypeID AS [TypeID]
		 , [ItemID]
		 , ts.FirstSpendText
	INTO #ACATranTypes
	FROM Relational.AdditionalCashbackAwardType acat WITH (NOLOCK)
	INNER JOIN Staging.Text1stSpend ts
		ON acat.AdditionalCashbackAwardTypeID = ts.AdditionalCashbackAwardTypeID
	WHERE ItemID IS NOT NULL

	CREATE CLUSTERED INDEX ix_AXATranTypes_Combined ON #ACATranTypes ([TypeID], [ItemID])

	-------------------------------------------------------------------------------------------------
	-------------------------------------Find the ACA Trans for earning trans------------------------
	-------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT FanID
		 , ClubCash AS FirstEarnValue
		 , FirstSpendText AS FirstEarntype
		 , @OneDayAgo AS FirstEarnDate
	INTO #Trans
	FROM (SELECT c.FanID
	  		   , a.FirstSpendText
	  		   , t.ClubCash * tt.Multiplier AS ClubCash
	  		   , a.ItemID
	  		   , ROW_NUMBER() OVER (PARTITION BY c.FanID ORDER BY a.ItemID Desc, t.ClubCash DESC) AS RowNo
		  FROM #Customer AS c  WITH (NOLOCK)
		  INNER LOOP JOIN [SLC_Report].[dbo].[Trans] t WITH (NOLOCK)
	  		  ON c.FanID = t.FanID
		  INNER JOIN [SLC_Report].[dbo].[TransactionType] tt WITH (NOLOCK)
	  		  ON t.TypeID = tt.ID
		  INNER JOIN #ACATranTypes AS a WITH (NOLOCK)
	  		  ON t.TypeID = a.TypeID
	  		  AND t.ItemID = a.ItemID
		  WHERE t.ProcessDate >= @TwoDayAgo
		  AND t.ClubCash * tt.Multiplier > 0) t
	WHERE RowNo = 1 


	-------------------------------------------------------------------------------------------------
	--------------------------------Find the Match and Tran IDs for earning trans--------------------
	-------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#PTrans') IS NOT NULL DROP TABLE #PTrans
	SELECT c.FanID
		 , m.ID AS MatchID
		 , t.ID AS TranID
		 , dcl.PartnerID
		 , dcl.PartnerName
		 , CASE
				WHEN pc.CardTypeID = 1 THEN 'credit card payment at '
				WHEN pc.CardTypeID = 2 THEN 'debit card payment at '
		   END AS PaymentMethod
		 , t.ClubCash * tt.Multiplier AS ClubCash
	INTO #PTrans
	FROM #Customer c
	INNER LOOP JOIN [SLC_Report].[dbo].[Trans] t WITH (NOLOCK)
		ON c.FanID = t.FanID
	INNER JOIN [SLC_Report].[dbo].[TransactionType] tt WITH (NOLOCK)
		ON t.TypeID = tt.ID
	INNER JOIN [SLC_Report].[dbo].[Match] M WITH (NOLOCK)
		ON t.MatchID = m.ID
	INNER JOIN [SLC_Report].[dbo].[RetailOutlet] AS ro WITH (NOLOCK)
		ON m.RetailOutletID = ro.ID
	INNER JOIN Staging.Partner_DynamicContentLabel dcl
		ON ro.PartnerID = dcl.PartnerID
	INNER JOIN [SLC_Report].[dbo].[Pan] AS p WITH (NOLOCK)
		ON t.PanID = p.ID
	INNER JOIN [SLC_Report].[dbo].[PaymentCard] AS pc WITH (NOLOCK)
		ON p.PaymentCardID = pc.ID
	WHERE m.[Status] = 1
	AND RewardStatus IN (0, 1) 
	AND	t.ProcessDate >= @TwoDayAgo 
	AND	pc.CardTypeID IN (1, 2)
	AND t.ClubCash * tt.Multiplier > 0

	-------------------------------------------------------------------------------------------------
	----------------------------Pick Most Important Partner Trans Entry------------------------------
	-------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#PTransNamed') IS NOT NULL DROP TABLE #PTransNamed
	SELECT FanID
		 , ClubCash AS FirstEarnValue
		 , TextString AS FirstEarnType
		 , @OneDayAgo AS FirstEarnDate
	INTO #PTransNamed
	FROM (SELECT pt.FanID
			   , pt.ClubCash
			   , PaymentMethod + pt.PartnerName AS TextString
			   , ROW_NUMBER() OVER (PARTITION BY FanID ORDER BY COALESCE(mrt.Tier, 99) ASC, ClubCash DESC) AS RowNo
		  FROM #PTrans pt
		  LEFT JOIN Relational.Master_Retailer_Table mrt
			  ON pt.PartnerID = mrt.PartnerID) pt
	WHERE RowNo = 1

	-------------------------------------------------------------------------------------------------
	-----------------------------------------First Spend - Non DD------------------------------------
	-------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#FirstSpend') IS NOT NULL DROP TABLE #FirstSpend
	SELECT pt.FanID
		 , pt.FirstEarnType
		 , pt.FirstEarnValue
	INTO #FirstSpend
	FROM #PTransNamed pt
	UNION
	SELECT t.FanID
		 , t.FirstEarnType
		 , t.FirstEarnValue
	FROM #Trans t

	-------------------------------------------------------------------------------------------------
	-----------------------------------------UPDATE First Earn Table---------------------------------
	-------------------------------------------------------------------------------------------------

	UPDATE Staging.Customers_Passed0GBP
	SET FirstEarnValue = fs.FirstEarnValue
	  , FirstEarnType = fs.FirstEarnType
	FROM Staging.Customers_Passed0GBP cp
	INNER JOIN #FirstSpend fs
		on cp.FanID = fs.FanID


	/*--------------------------------------------------------------------------------------------------
	---------------------------UPDATE entry in JobLog Table WITH End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	UPDATE  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	WHERE	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'Customers_Passed0GBP' and
			EndDate IS NULL
	/*--------------------------------------------------------------------------------------------------
	---------------------------UPDATE entry in JobLog Table WITH Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately AS WHEN table grows this AS a task on its own may take several minutes and we do
	--not want it INCLUDEd in table creation times
	UPDATE  staging.JobLog_Temp
	Set		TableRowCount = ((SELECT COUNT(1) FROM Warehouse.Staging.Customers_Passed0GBP)-@RowNo)
	WHERE	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'Customers_Passed0GBP' and
			TableRowCount IS NULL


	INSERT INTO staging.JobLog
	SELECT [StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
	FROM staging.JobLog_Temp

	TRUNCATE TABLE staging.JobLog_Temp

END