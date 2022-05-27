
/******************************************************************************
Author:	Rory Francis
Created: 01/10/2021
Purpose: 
	- Segments control group universe based on members' most recent spend at the given retailer ConsumerCombinationIDs in the Warehouse.Relational.ConsumerTransaction table
	- Segmented members loaded into a new table

------------------------------------------------------------------------------
Modification History


******************************************************************************/

CREATE PROCEDURE [Segmentation].[ControlSetup_Segmentation_POS]	(	@RetailerID INT
																,	@StartDate DATETIME2(7)
																,	@TableName VARCHAR(250))

AS
BEGIN

	---- For testing	EXEC [Segmentation].[ControlSetup_Segmentation_POS] 4036,'2021-11-04','Sandbox.Rory.Control_4036_20211104

			--DECLARE @RetailerID INT = 4036
			--DECLARE @StartDate DATE = '2021-11-04'
			--DECLARE @TableName varchar(200) = 'Sandbox.ProcessOp.Control_4036_20211104'	

		DECLARE		@PartnerID INT = @RetailerID
				,	@BrandID INT = (SELECT MIN(BrandID) FROM [Derived].[Partner] WHERE PartnerID = @RetailerID)


	/***********************************************************************************************
	Identify Shopper and Lapsed control members 
	***********************************************************************************************/
		
	-- Load customer Table

		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers;
		CREATE TABLE #Customers (	FanID INT
								,	CINID INT
								,	SegmentID INT);

		INSERT INTO #Customers (FanID	--	Load source control group members for retailers requiring standard setup
							,	CINID
							,	SegmentID)
		SELECT	FanID = cg.FanID
			,	CINID = cg.CINID
			,	Segment = 7
		FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_CtrlGroup] cg
		WHERE NOT EXISTS (	SELECT 1	--	Out of programme
							FROM [Warehouse].[Relational].[Customer] cu
							WHERE cg.FanID = cu.FanID)
		AND (cg.EndDate IS NULL OR cg.EndDate > @StartDate);

		CREATE CLUSTERED INDEX CIX_CINID ON #Customers (CINID);
		CREATE NONCLUSTERED INDEX IX_FanID ON #Customers (FanID, SegmentID);


	-- Create ConsumerCombination Table
	
		IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs;
		SELECT	DISTINCT
				ConsumerCombinationID = cc.ConsumerCombinationID
		INTO #CCIDs
		FROM [Warehouse].[Relational].[ConsumerCombination] cc
		WHERE BrandID = @BrandID
		UNION
		SELECT	DISTINCT
				ConsumerCombinationID = cc.ConsumerCombinationID
		FROM [Warehouse].[Relational].[ConsumerCombination] cc
		INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] mtg
			ON mtg.MID_Join = cc.MID	--	Only include incentivised MIDs
			AND @StartDate BETWEEN mtg.StartDate AND COALESCE(mtg.EndDate, GETDATE())
		WHERE @PartnerID = 4938

		CREATE UNIQUE CLUSTERED INDEX CIX_CCID ON #CCIDs (ConsumerCombinationID);


	--Setup for retrieving customer transactions

		DECLARE	@Acquire INT
			,	@Lapsed INT
			,	@Shopper INT;

		SELECT	@Acquire = Acquire -- Member is Acquire if their last spend was more than this number of months before the cycle start date
			,	@Lapsed = Lapsed -- Member is Lapsed if their last spend was more than this number of months before the cycle start date
			,	@Shopper = Shopper -- Member is Lapsed if their last spend was more than this number of months before the cycle start date
		FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings]
		WHERE PartnerID = @PartnerID
		AND StartDate <= @StartDate
		AND (EndDate > @StartDate OR EndDate IS NULL);


	-- Load customer transactions summary and decide which customers are Lapsed
			
		DECLARE	@ADate DATE = DATEADD(MONTH, -@Acquire,	@StartDate) -- Aprox. today minus @Acquire months
			,	@LDate DATE = DATEADD(MONTH, -@Lapsed,	@StartDate) -- Aprox. today minus @Lapsed months
			,	@SDate DATE = DATEADD(MONTH, -@Shopper,	@StartDate)

		IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT;
		SELECT	CINID = ct.CINID
			,	LatestTran = MAX(ct.TranDate)
		INTO #CT
		FROM [Warehouse].[Relational].[ConsumerTransaction] ct
		WHERE ct.TranDate BETWEEN @ADate AND @StartDate
		AND EXISTS (	SELECT 1
						FROM #CCIDs CCs
						WHERE ct.ConsumerCombinationID = CCs.ConsumerCombinationID)
		AND EXISTS (	SELECT 1
						FROM #Customers cu
						WHERE ct.CINID = cu.CINID)
		GROUP BY	ct.CINID
		HAVING SUM(ct.Amount) > 0

		OPTION (RECOMPILE);

		IF OBJECT_ID('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders;
		CREATE TABLE #Spenders (CINID INT NOT NULL
							,	SegmentID SMALLINT NULL)

		INSERT INTO #Spenders (	CINID
							,	SegmentID)
		SELECT	ct.CINID
			,	Segment =	CASE
								WHEN ct.LatestTran <= @LDate THEN 8
								WHEN ct.LatestTran <= @SDate THEN 9
								ELSE null
							END
		FROM #CT ct
		
		CREATE CLUSTERED INDEX CIX_FanID ON #Spenders (CINID, SegmentID)


	/***********************************************************************************************
	Load control members, along with segment types
	***********************************************************************************************/

		TRUNCATE TABLE [Report].[OfferReport_ControlGroupMembers_Staging]
		INSERT INTO [Report].[OfferReport_ControlGroupMembers_Staging]
		SELECT	FanID = cu.FanID
			,	CINID = MAX(cu.CINID)
			,	PartnerID = CONVERT(VARCHAR(10), @PartnerID)
			,	SegmentID = MAX(COALESCE(sp.SegmentID, cu.SegmentID))
		FROM #Customers cu
		LEFT JOIN #Spenders sp
			ON cu.CINID = sp.CINID
		GROUP BY	cu.FanID

		DECLARE @Qry NVARCHAR(MAX);
		
		SET @Qry =
		'IF OBJECT_ID(''' + @TableName + ''') IS NOT NULL DROP TABLE ' + @TableName + ';' + CHAR(10) +
		'SELECT	FanID' + CHAR(10) +
		'	,	CINID' + CHAR(10) +
		'	,	PartnerID' + CHAR(10) +
		'	,	SegmentID' + CHAR(10) +
		'INTO ' + @TableName + CHAR(10) +
		'FROM [Report].[OfferReport_ControlGroupMembers_Staging]' + CHAR(10) + + CHAR(10) +
		
		'CREATE CLUSTERED INDEX CIX_SegmentIDFanID ON ' + @TableName + ' (SegmentID, FanID)';

		EXEC sp_executeSQL @Qry;

END



