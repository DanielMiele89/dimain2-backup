﻿-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-06-11>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[PM005_PreSelection_sProc]ASBEGINSET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	/*******************************************************************************************************************************************
		1. Prepare parameters for sProc to run
	*******************************************************************************************************************************************/

		/*
		SELECT *
		FROM SLC_Report..Partner
		WHERE Name LIKE '%pooch%'
		*/

		DECLARE @PartnerID INT = 4884
			 , @BrandID INT
			 , @Today DATETIME = GETDATE()
			 , @Acquire INT
			 , @Lapsed INT
			 , @Lapsing INT

		SELECT	@BrandID = [Warehouse].[Relational].[Partner].[BrandID]
		FROM [Warehouse].[Relational].[Partner]
		WHERE [Warehouse].[Relational].[Partner].[PartnerID] = @PartnerID


		SELECT @Acquire = [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings ].[Acquire] 
			 , @Lapsed = [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings ].[Lapsed]
			 , @Lapsing = [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings ].[Lapsed] - 4
		FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings ]
		WHERE [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings ].[PartnerID] = @PartnerID
		AND [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings ].[EndDate] IS NULL
	
	/*******************************************************************************************************************************************
		2. Run segmentation for spenders
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Fetch customer details
		***********************************************************************************************************************/

			-- #1 slowest statement	
			IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
			SELECT cu.FanID
				 , cl.CINID
				 , ROW_NUMBER() OVER (ORDER BY cu.FanID Desc) AS RowNo
			INTO #Customers
			FROM Derived.Customer cu WITH (NOLOCK)
			INNER JOIN Derived.CINList cl WITH (NOLOCK)
				ON cu.SourceUID = cl.CIN
			WHERE cu.CurrentlyActive = 1
	
			CREATE CLUSTERED INDEX CIX_CINFan ON #Customers (CINID, FanID)
			--CREATE NONCLUSTERED INDEX IX_Customer_FanID ON #Customers (FanID)
			--CREATE NONCLUSTERED INDEX IX_Customer_RowNo ON #Customers (RowNo)


		/***********************************************************************************************************************
			2.2. Fetch ConsumerCombinations
		***********************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
			CREATE TABLE #CCIDs (	ConsumerCombinationID BIGINT
								,	MyRewards BIT
								,	Virgin BIT)

			INSERT INTO #CCIDs
			SELECT	[Warehouse].[Relational].[ConsumerCombination].[ConsumerCombinationID]
				,	1 AS MyRewards
				,	0 AS Virgin
			FROM Warehouse.Relational.ConsumerCombination cc WITH (NOLOCK)
			WHERE [Warehouse].[Relational].[ConsumerCombination].[BrandID] = @BrandID
	
			INSERT INTO #CCIDs
			SELECT	[WH_Virgin].[Trans].[ConsumerCombination].[ConsumerCombinationID]
				,	0 AS MyRewards
				,	1 AS Virgin
			FROM WH_Virgin.Trans.ConsumerCombination cc WITH (NOLOCK)
			WHERE [WH_Virgin].[Trans].[ConsumerCombination].[BrandID] = @BrandID
		
			CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs (ConsumerCombinationID)


		/***********************************************************************************************************************
			2.3. Set up for retrieving customer Relationalactions at partner
		***********************************************************************************************************************/

			DECLARE @AcquireDate DATE = DATEADD(month, -(@Acquire), DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 2, 0))
				 , @LapsedDate DATE = DATEADD(month, -(@Lapsed), DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 2, 0))
				 , @LapsingDate DATE = DATEADD(month, -(@Lapsing), DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 2, 0))
				 , @ShopperDate DATE = GETDATE()

			IF OBJECT_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
			CREATE TABLE #Spenders (FanID INT NOT NULL
								 , TranDate DATE
								 , Segment VARCHAR(25) NOT NULL
								 , PRIMARY KEY (FanID))

		/***********************************************************************************************************************
			2.4. Fetch all Relationalactions
		***********************************************************************************************************************/

			INSERT INTO #Spenders
			SELECT cu.FanID
				 , MAX(TranDate) AS TranDate
				 , CASE
						WHEN MAX(TranDate) < @LapsedDate THEN 'Lapsed'
						WHEN MAX(TranDate) < @LapsingDate THEN 'Lapsing'
						ELSE 'Shopper'
				 END AS Segment
			FROM #CCIDs CCs
			INNER JOIN Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
				ON CCs.ConsumerCombinationID = #CCIDs.[ct].ConsumerCombinationID
				AND CCs.MyRewards = 1
			INNER JOIN #Customers cu
				ON	ct.CINID = cu.CINID
			WHERE TranDate BETWEEN @AcquireDate AND @ShopperDate
			GROUP BY cu.CINID
				 , cu.FanID
			HAVING SUM(Amount) > 0 
			OPTION (RECOMPILE)

			INSERT INTO #Spenders
			SELECT cu.FanID
				 , MAX(TranDate) AS TranDate
				 , CASE
						WHEN MAX(TranDate) < @LapsedDate THEN 'Lapsed'
						WHEN MAX(TranDate) < @LapsingDate THEN 'Lapsing'
						ELSE 'Shopper'
				 END AS Segment
			FROM #CCIDs CCs
			INNER JOIN WH_Virgin.Trans.ConsumerTransaction ct
				ON CCs.ConsumerCombinationID = #CCIDs.[ct].ConsumerCombinationID
				AND CCs.Virgin = 1
			INNER JOIN #Customers cu
				ON	ct.CINID = cu.CINID
			WHERE TranDate BETWEEN @AcquireDate AND @ShopperDate
			GROUP BY cu.CINID
				 , cu.FanID
			HAVING SUM(Amount) > 0 
			OPTION (RECOMPILE)


	/*******************************************************************************************************************************************
		3. Run segmentation for acquire customers
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Fetch customer details including heatmap scores
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#AllCustomers') IS NOT NULL DROP TABLE #AllCustomers
			SELECT	cu.FanID
				,	CONVERT(DATE, NULL) AS TranDate
				,	'Acquire' AS Segment
			INTO #AllCustomers
			FROM Warehouse.Relational.Customer cu WITH (NOLOCK)
			WHERE cu.CurrentlyActive = 1
			UNION ALL
			SELECT	cu.FanID
				,	CONVERT(DATE, NULL) AS TranDate
				,	'Acquire' AS Segment
			FROM WH_Virgin.Derived.Customer cu WITH (NOLOCK)
			WHERE cu.CurrentlyActive = 1
			
			CREATE CLUSTERED INDEX CIX_AllCustomers_FanID ON #AllCustomers (FanID)


		/***********************************************************************************************************************
			3.2. Update Shopper & Lapsed segments
		***********************************************************************************************************************/

			UPDATE ac
			SET ac.Segment = sp.Segment
			,	ac.TranDate = sp.TranDate
			FROM #AllCustomers ac
			INNER JOIN #Spenders sp
				ON ac.FanID = sp.FanID


	/*******************************************************************************************************************************************
		4. Fetch Nursery customers
	*******************************************************************************************************************************************/
				

	/*******************************************************************************************************************************************
		5. Final Output
	*******************************************************************************************************************************************/
				
		IF OBJECT_ID('Sandbox.Rory.PoochMuttLapsing_20210617') IS NOT NULL DROP TABLE Sandbox.Rory.PoochMuttLapsing_20210617
		SELECT *
		INTO Sandbox.Rory.PoochMuttLapsing_20210617
		FROM #AllCustomers
		WHERE #AllCustomers.[Segment] = 'Lapsing'If Object_ID('WH_Virgin.Selections.PM005_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.PM005_PreSelectionSelect [SANDBOX].[RORY].[POOCHMUTTLAPSING_20210617].[FanID]Into WH_Virgin.Selections.PM005_PreSelectionFROM  SANDBOX.RORY.POOCHMUTTLAPSING_20210617END