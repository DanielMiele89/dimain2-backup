
-- =============================================
-- Author:		Shaun Hide
-- Create date: 01/02/2019
-- Description:	Full Refresh Process to be Run Weekly
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_LIVE_FullRefresh]
AS
BEGIN

	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	CREATE TABLE #Dates
		(
			ID INT NOT NULL PRIMARY KEY
			,CycleStart DATE
			,CycleEnd DATE
			,Seasonality_CycleID INT
		)

	;WITH CTE
	 AS (	
			SELECT	1 AS ID
					,CAST('2015-04-02' AS DATE) AS CycleStart
					,CAST('2015-04-29' AS DATE) AS CycleEnd
					,4 AS Seasonality_CycleID
		
			UNION ALL
		
			SELECT	ID + 1
					,CAST(DATEADD(DAY,28,CycleStart) AS DATE)
					,CAST(DATEADD(DAY,28,CycleEnd) AS DATE)
					,CASE
						WHEN Seasonality_CycleID < 13 THEN Seasonality_CycleID + 1
						ELSE Seasonality_CycleID - 12
					 END
			FROM	CTE
			WHERE	ID < 100
		)
	INSERT INTO #Dates
		SELECT	* 
		FROM	CTE
	OPTION (MAXRECURSION 100)

	IF OBJECT_ID('tempdb..#LastRunDate') IS NOT NULL DROP TABLE #LastRunDate
	SELECT	b.*
			,ROW_NUMBER() OVER (ORDER BY b.ID ASC) AS DateRow
	INTO	#LastRunDate
	FROM	(SELECT	*
			 FROM	#Dates 
			 WHERE	CycleStart <= CAST(DATEADD(DAY,-7,GETDATE()) AS DATE)
				AND CAST(DATEADD(DAY,-7,GETDATE()) AS DATE) <= CycleEnd) a
	JOIN	#Dates b
		ON  a.ID - 2 < b.ID
		AND b.ID < a.ID

	-- SELECT * FROM #LastRunDate

	CREATE CLUSTERED INDEX cix_DateRow ON #LastRunDate (DateRow)
	CREATE NONCLUSTERED INDEX nix_CycleStart ON #LastRunDate (CycleStart)
	CREATE NONCLUSTERED INDEX nix_CycleEnd ON #LastRunDate (CycleEnd)

	DECLARE @ThisRun INT = (SELECT ID FROM	#LastRunDate)
	DECLARE @LastRun INT = (SELECT ID FROM Warehouse.ExcelQuery.ROCEFT_LastRunDate)

	IF (@ThisRun != @LastRun) OR (@LastRun IS NULL)
		BEGIN
			-- General Setup
			EXEC [ExcelQuery].[ROCEFT_LIVE_Cardholder_Calculate] -- Near Instant -> Output = ROCEFT_Cardholders
			EXEC [ExcelQuery].[ROCEFT_LIVE_Publisher_Calculate] -- Near Instant -> Output = ROCEFT_Publishers
			EXEC [ExcelQuery].[ROCEFT_LIVE_CardMix_Calculate] -- 6 minutes -> Output = ROCEFT_CardsMix

			---- RBS Data Related Stored Procedures
			EXEC [ExcelQuery].[ROCEFT_LIVE_NaturalSalesByCycle_Calculate] NULL -- 1 hour -> Output = ROCEFT_NaturalSpendCycles_MyReward
			EXEC [ExcelQuery].[ROCEFT_LIVE_Trend_Calculate] NULL -- 1 minute 30 seconds -> Output = ROCEFT_Trend
			EXEC [ExcelQuery].[ROCEFT_LIVE_SpendStretch_Calculate] NULL -- 2 minutes -> ROCEFT_SpendStretch
			EXEC [ExcelQuery].[ROCEFT_LIVE_RBS_CumulativeGains_Calculate] NULL -- 1 hour -> Output = ROCEFT_RBSCumulativeGains

			-- NFI Data Related Stored Procedures
			EXEC [ExcelQuery].[ROCEFT_LIVE_nFIShopperSegmentSplit_Calculate] NULL -- 5 minutes -> Output = ROCEFT_nFI_ShopperSegmentSplits -- Refactor Needed
			EXEC [ExcelQuery].[ROCEFT_LIVE_nFISpendHistory_Calculate] -- 7 min -> Output = ROCEFT_PubScaling, ROCEFT_PubScaling_Segment -- Refactor Needed
			EXEC [ExcelQuery].[ROCEFT_LIVE_ROC_CumulativeGains_Calculate] -- 4 minutes -> Output = ROCEFT_ROCCumulativeGains -- Refactor Needed

			EXEC ExcelQuery.ROCForecastingTool_ETL_StartJob 

			-- Retain Run Records
			TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_LastRunDate
			INSERT INTO Warehouse.ExcelQuery.ROCEFT_LastRunDate
				SELECT *
				FROM	#LastRunDate
		END
END