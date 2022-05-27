/******************************************************************************
Author	  Jason Shipp
Created	  13/02/2018
Purpose	 
	- Collate control transaction results from Relational.ConsumerTransaction for new activity per retailer and insert rows into Staging.ALS_Control_Trans_Results table
	- Data for the Campaign Cycle ALS Members report
	
Modification History
	Jason Shipp 26/02/2018
		- Changed table from which to map FanIDs to CINIDs from Warehouse.Relational.Customer to SLC_Report.dbo.Fan

******************************************************************************/

CREATE PROCEDURE [Staging].[ALS_Campaign_Cycle_Members_Load_Control_Trans_Results]

AS
BEGIN

	SET NOCOUNT ON;

	/**************************************************************************
	Declare iteration variables
	***************************************************************************/

	DECLARE @maxrow INT
	DECLARE @rowNum INT
		
	DECLARE @RetailerID INT
	DECLARE @AnalysisStartDate DATE
	DECLARE @CycleStartDate DATE
	DECLARE @CycleEndDate DATE

	/**************************************************************************
	Load PartnerID - RetailerID - ConsumerCombinationID mapping
	***************************************************************************/

	-- Create table of Alternate PartnerIDs

	IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;

	SELECT
	DISTINCT * 
	INTO #PartnerAlternate
	FROM 
		(SELECT 
		PartnerID
		, AlternatePartnerID
		FROM Warehouse.APW.PartnerAlternate

		UNION ALL 

		SELECT 
		PartnerID
		, AlternatePartnerID
		FROM nFI.APW.PartnerAlternate
		) x;

	-- Create table of retailer - ConsumerCombinationID mapping

	IF OBJECT_ID('tempdb..#ConsumerCombos') IS NOT NULL DROP TABLE #ConsumerCombos;

	SELECT
		cc.ConsumerCombinationID
		, b.RetailerID
	INTO #ConsumerCombos
	FROM Relational.ConsumerCombination cc
	INNER JOIN APW.RetailerPotentialValue_Brand b -- Only these retailers will be analysed
		ON cc.BrandID = b.BrandID;

	/**************************************************************************
	/**************************************************************************
	Set up prerequisite to loop over retailers and cycle dates
	***************************************************************************/
	***************************************************************************/

	-- Create table of retailer - cycle dates to iterate over

	IF OBJECT_ID('tempdb..#IterRetailers') IS NOT NULL DROP TABLE #IterRetailers;

	WITH Iter1 AS 
		(SELECT DISTINCT
			COALESCE(pa.AlternatePartnerID, cm.PartnerID) AS RetailerID
			, cyc.AnalysisStartDate
			, cyc.CycleStartDate
			, cyc.CycleEndDate
		FROM Staging.ALS_Anchor_Cycle_Control_Member cm
		LEFT JOIN #PartnerAlternate pa 
			ON cm.PartnerID = pa.PartnerID
		INNER JOIN Staging.ALS_Retailer_Cycle cyc
			ON cm.PartnerID = cyc.PartnerID
		)
	SELECT
		i.RetailerID
		, i.AnalysisStartDate
		, i.CycleStartDate
		, i.CycleEndDate
		, ROW_NUMBER() OVER (ORDER BY i.RetailerID, i.CycleStartDate, i.CycleEndDate) AS RowNumber
	INTO #IterRetailers
	FROM Iter1 i

	-- Create table of partner-retailer mapping

	IF OBJECT_ID('tempdb..#RetailerPartner') IS NOT NULL DROP TABLE #RetailerPartner;

	WITH Partners AS
		(SELECT DISTINCT PartnerID FROM Staging.ALS_Anchor_Cycle_Control_Member)
	SELECT DISTINCT
		COALESCE(pa.AlternatePartnerID, p.PartnerID) AS RetailerID
		, p.PartnerID
	INTO #RetailerPartner
	FROM Partners p
	LEFT JOIN #PartnerAlternate pa 
		ON p.PartnerID = pa.PartnerID;

	-- Initialise iteration variables

	SET @maxrow = (SELECT COUNT(1) FROM #IterRetailers)
	SET @rowNum = 0

	WHILE @rowNum < @maxRow

	/**************************************************************************
	Begin loop: Iterate over retailer - cycle combinations
	***************************************************************************/

	BEGIN

		SET @rowNum = @rowNum + 1;

		SET @RetailerID = (SELECT RetailerID FROM #IterRetailers WHERE RowNumber = @rowNum);
		SET @AnalysisStartDate = (SELECT AnalysisStartDate FROM #IterRetailers WHERE RowNumber = @rowNum);
		SET @CycleStartDate = (SELECT CycleStartDate FROM #IterRetailers WHERE RowNumber = @rowNum);
		SET @CycleEndDate = (SELECT CycleEndDate FROM #IterRetailers WHERE RowNumber = @rowNum);

		IF OBJECT_ID('tempdb..#CCID') IS NOT NULL DROP TABLE #CCID;

		SELECT DISTINCT 
		cc.ConsumerCombinationID
		INTO #CCID
		FROM #ConsumerCombos cc
		WHERE cc.RetailerID = @RetailerID -- Fetch Consumer Combinations associated with iteration row retailer

		IF OBJECT_ID('tempdb..#PartnerID') IS NOT NULL DROP TABLE #PartnerID;

		SELECT DISTINCT i.PartnerID
		INTO #PartnerID
		FROM #RetailerPartner i
		WHERE i.RetailerID = @RetailerID -- Fetch partners associated with iteration row retailer

		/**************************************************************************
		Fetch control members per cycle per retailer for members in Staging.ALS_Anchor_Cycle_Control_Member	
		***************************************************************************/
	
		IF OBJECT_ID('tempdb..#ALSControlMember') IS NOT NULL DROP TABLE #ALSControlMember;

		SELECT 
			@RetailerID AS RetailerID
			, @AnalysisStartDate AS AnalysisStartDate
			, @CycleStartDate AS CycleStartDate
			, @CycleEndDate AS CycleEndDate
			, anc.SuperSegmentTypeID
			, COUNT(DISTINCT(anc.FanID)) AS CycleMembers
		INTO #ALSControlMember
		FROM Staging.ALS_Anchor_Cycle_Control_Member anc
		WHERE 
			anc.PartnerID IN (SELECT PartnerID FROM #PartnerID)
		GROUP BY anc.SuperSegmentTypeID;

		/**************************************************************************
		Fetch control transaction data per cycle per retailer for members in Staging.ALS_Anchor_Cycle_Control_Member		
		***************************************************************************/

		IF OBJECT_ID('tempdb..#ALSControlTrans') IS NOT NULL DROP TABLE #ALSControlTrans;

		SELECT 
			@RetailerID AS RetailerID
			, @AnalysisStartDate AS AnalysisStartDate
			, @CycleStartDate AS CycleStartDate
			, @CycleEndDate AS CycleEndDate
			, anc.SuperSegmentTypeID
			, COUNT(cl.CINID) AS Transactions
			, COUNT(DISTINCT(cl.CINID)) AS Spenders
			, SUM(ct.Amount) AS Spend
		INTO #ALSControlTrans
		FROM Staging.ALS_Anchor_Cycle_Control_Member anc
		INNER JOIN SLC_Report.dbo.Fan f
			ON anc.FanID = f.ID
		INNER JOIN Warehouse.Relational.CINList cl
			ON cl.CIN = f.SourceUID
		INNER JOIN Warehouse.Relational.ConsumerTransaction ct
			ON cl.CINID = ct.CINID
			AND ct.ConsumerCombinationID IN (SELECT ConsumerCombinationID FROM #CCID)
			AND ct.TranDate BETWEEN @CycleStartDate AND @CycleEndDate
		WHERE 
			anc.PartnerID IN (SELECT PartnerID FROM #PartnerID)
			AND ct.Amount >0
		GROUP BY anc.SuperSegmentTypeID;
			
		/**************************************************************************
		Insert control report data into Staging.ALS_Control_Trans_Results table

		-- Create table:

		CREATE TABLE Staging.ALS_Control_Trans_Results
			(ID INT IDENTITY NOT NULL
			, IsRecentActivity BIT
			, RetailerID INT
			, AnalysisStartDate DATE
			, CycleStartDate DATE
			, CycleEndDate DATE
			, AnchorSegmentType VARCHAR(50)
			, CycleMembers INT
			, Transactions INT
			, Spenders INT
			, Spend INT
			) 

		ALTER TABLE Staging.ALS_Control_Trans_Results
		ADD CONSTRAINT PK_ALS_Control_Trans_Results PRIMARY KEY CLUSTERED (ID);
		***************************************************************************/	

		INSERT INTO Staging.ALS_Control_Trans_Results
			(IsRecentActivity
			, RetailerID
			, AnalysisStartDate
			, CycleStartDate
			, CycleEndDate
			, AnchorSegmentType
			, CycleMembers
			, Transactions
			, Spenders
			, Spend
			)
		SELECT
			0 AS IsRecentActivity
			, m.RetailerID
			, m.AnalysisStartDate
			, m.CycleStartDate
			, m.CycleEndDate
			, sst.SuperSegmentName AS AnchorSegmentType
			, m.CycleMembers
			, t.Transactions
			, t.Spenders
			, t.Spend
		FROM #ALSControlMember m
		LEFT JOIN #ALSControlTrans t
			ON m.RetailerID = t.RetailerID
			AND m.AnalysisStartDate = t.AnalysisStartDate
			AND m.CycleStartDate = t.CycleStartDate
			AND m.CycleEndDate = t.CycleEndDate
			AND m.SuperSegmentTypeID = t.SuperSegmentTypeID
		LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Super_Types sst
			ON m.SuperSegmentTypeID = sst.ID
		WHERE NOT EXISTS
			(SELECT NULL 
			FROM Staging.ALS_Control_Trans_Results d
			WHERE 	
				m.RetailerID = d.RetailerID
				AND m.CycleStartDate = d.CycleStartDate
				AND m.CycleEndDate = d.CycleEndDate
				AND m.AnalysisStartDate = d.AnalysisStartDate
				AND sst.SuperSegmentName = d.AnchorSegmentType						
			);

	END

	/**************************************************************************
	Update flag in results table for retailers' most recent activity per publisher type
	***************************************************************************/

	UPDATE rd
		SET rd.IsRecentActivity = x.IsRecentActivity
	FROM Staging.ALS_Control_Trans_Results rd
	INNER JOIN 
		(SELECT DISTINCT
		RetailerID
		, CASE WHEN 
			MAX(AnalysisStartDate) OVER (PARTITION BY RetailerID ORDER BY AnalysisStartDate DESC) = AnalysisStartDate 
		THEN 1 ELSE 0 END AS IsRecentActivity
		FROM Staging.ALS_Control_Trans_Results
		) x
	ON rd.RetailerID = x.RetailerID;

END