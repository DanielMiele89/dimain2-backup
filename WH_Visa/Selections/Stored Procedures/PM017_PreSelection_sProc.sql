
CREATE PROCEDURE [Selections].[PM017_PreSelection_sProc]
AS
BEGIN


SET NOCOUNT ON
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

		SELECT	@BrandID = BrandID
		FROM [Warehouse].[Relational].[Partner]
		WHERE PartnerID = @PartnerID


		SELECT @Acquire = Acquire 
			 , @Lapsed = Lapsed
			 , @Lapsing = Lapsed - 4
		FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings ]
		WHERE PartnerID = @PartnerID
		AND EndDate IS NULL
	
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
			FROM derived.Customer cu WITH (NOLOCK)
			INNER JOIN derived.CINList cl WITH (NOLOCK)
				ON cu.SourceUID = cl.CIN
			WHERE cu.CurrentlyActive = 1
	
			CREATE CLUSTERED INDEX CIX_CINFan ON #Customers (CINID, FanID)
			--CREATE NONCLUSTERED INDEX IX_Customer_FanID ON #Customers (FanID)
			--CREATE NONCLUSTERED INDEX IX_Customer_RowNo ON #Customers (RowNo)


		/***********************************************************************************************************************
			2.2. Fetch ConsumerCombinations
		***********************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
			CREATE TABLE #CCIDs (	ConsumerCombinationID BIGINT)

			INSERT INTO #CCIDs
			SELECT	ConsumerCombinationID
			FROM Trans.ConsumerCombination cc WITH (NOLOCK)
			WHERE BrandID = @BrandID
		
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
			INNER JOIN Trans.ConsumerTransaction ct
				ON CCs.ConsumerCombinationID = ct.ConsumerCombinationID
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
			FROM Derived.Customer cu WITH (NOLOCK)
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
				
			IF OBJECT_ID('tempdb..#CustomersEarntOnOffer') IS NOT NULL DROP TABLE #CustomersEarntOnOffer
			SELECT	FanID
			INTO #CustomersEarntOnOffer
			FROM [Derived].[PartnerTrans]
			WHERE PartnerID = @PartnerID


	/*******************************************************************************************************************************************
		5. Final Output
	*******************************************************************************************************************************************/
				
		IF OBJECT_ID('Sandbox.Rory.PoochMuttLapsing_20210617_Visa') IS NOT NULL DROP TABLE Sandbox.Rory.PoochMuttLapsing_20210617_Visa
		SELECT *
		INTO Sandbox.Rory.PoochMuttLapsing_20210617_Visa
		FROM #AllCustomers
		WHERE Segment = 'Lapsing'
		
		IF OBJECT_ID('[WH_Visa].[Selections].[PM017_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[PM017_PreSelection]
		SELECT	FanID
		INTO [WH_Visa].[Selections].[PM017_PreSelection]
		FROM Sandbox.Rory.PoochMuttLapsing_20210617_Visa

END
