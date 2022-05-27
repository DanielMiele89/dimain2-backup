/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Add exposed members to nfi.Relational.campaignhistory for new OfferReportingPeriodsIDs in nFI.Relational.ironoffercycles
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 16/05/2018
	- Added distinct constraint to fetch
	- Added intermediate table to loop for optimisation purposes

Jason Shipp 11/07/2018
	- Added logic to only insert new exposed members if the OfferReportingPeriodsID does not already exists in the campaignhistory table
******************************************************************************/

CREATE PROCEDURE [Report].[ControlSetup_Load_SegmentationTransDates]
AS
BEGIN
	
	SET NOCOUNT ON;

	/*******************************************************************************************************************************************
		1.	Load Campaign Cycle dates
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;
		SELECT	MAX(cd.StartDate) AS StartDate
			,	MAX(DATEADD(SECOND, -1, (DATEADD(day, 1, (CONVERT(DATETIME, CONVERT(DATE, cd.EndDate))))))) AS EndDate
		INTO #Dates
		FROM [Report].[ControlSetup_CycleDates] cd;

		DECLARE @StartDate DATETIME
			,	@EndDate DATETIME
		
		SELECT	@StartDate = StartDate
			,	@EndDate = EndDate
		FROM #Dates


	/*******************************************************************************************************************************************
		2.	Load partner ALS settings
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#PartnerSettings') IS NOT NULL DROP TABLE #PartnerSettings

		SELECT 
			s.PartnerID
			, MAX(DATEADD(month, -s.Acquire, @StartDate)) AS MaxAcquireDate
			, MAX(DATEADD(month, -s.Lapsed, @StartDate)) AS MaxLapsedDate
			, MAX(DATEADD(month, -s.Shopper, @StartDate)) AS MaxShopperDate
		INTO #PartnerSettings
		FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings] s
		GROUP BY
			s.PartnerID;


	/*******************************************************************************************************************************************
		3.	Load ControlGroupIDs
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ControlGroups') IS NOT NULL DROP TABLE #ControlGroups;

		CREATE TABLE #ControlGroups (
			ControlGroupID int NOT NULL
			, ControlGroupTypeID int NOT NULL
			, PartnerID int NOT NULL
			, SuperSegmentName varchar(40) NOT NULL
			, PublisherType varchar(40) NOT NULL
			);

		INSERT INTO #ControlGroups (ControlGroupID, ControlGroupTypeID, PartnerID, SuperSegmentName, PublisherType)
		SELECT DISTINCT
			ioc.ControlGroupID_OutOfProgramme
			, ControlGroupTypeID = 0
			, PartnerID = ioc.RetailerID
			, seg.SuperSegmentName
			, 'All' AS PublisherType
		FROM [Report].[OfferReport_OfferReportingPeriods] ioc
		LEFT JOIN Warehouse.Relational.IronOfferSegment seg
			ON ioc.IronOfferID = seg.IronOfferID
		WHERE 
			ioc.EndDate >= @StartDate
			AND ioc.StartDate <= @EndDate
			AND seg.OfferTypeDescription <> 'Universal'
			AND ioc.ControlGroupID_OutOfProgramme IS NOT NULL
			AND seg.SuperSegmentID IS NOT NULL;

		INSERT INTO #ControlGroups (ControlGroupID, ControlGroupTypeID, PartnerID, SuperSegmentName, PublisherType)
		SELECT DISTINCT
			ioc.ControlGroupID_InProgramme
			, ControlGroupTypeID = 0
			, PartnerID = ioc.RetailerID
			, seg.SuperSegmentName
			, 'All' AS PublisherType
		FROM [Report].[OfferReport_OfferReportingPeriods] ioc
		LEFT JOIN Warehouse.Relational.IronOfferSegment seg
			ON ioc.IronOfferID = seg.IronOfferID
		WHERE 
			ioc.EndDate >= @StartDate
			AND ioc.StartDate <= @EndDate
			AND seg.OfferTypeDescription <> 'Universal'
			AND ioc.ControlGroupID_InProgramme IS NOT NULL
			AND seg.SuperSegmentID IS NOT NULL;

		CREATE CLUSTERED INDEX CIX_ControlGroups_Warehouse ON #ControlGroups (controlgroupid, PartnerID);


	/*******************************************************************************************************************************************
		5.	Load CINIDs
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID ('tempdb..#CINs') IS NOT NULL DROP TABLE #CINs;
		SELECT	FanID = fa.ID
			,	CINID = cl.CINID
		INTO #CINs
		FROM [SLC_Report].[dbo].[Fan] fa
		INNER JOIN [Warehouse].[Relational].[CINList] cl
			ON cl.CIN = fa.SourceUID
		WHERE EXISTS (	SELECT 1
						FROM [Report].[OfferReport_ControlGroupMembers] cgm
						INNER JOIN #ControlGroups cg
							ON cgm.ControlGroupID = cg.ControlGroupID
						WHERE fa.ID = cgm.FanID)

		CREATE CLUSTERED INDEX CIX_FanIDCINID ON #CINs (FanID, CINID)


	/******************************************************************************
	Load iteration variables
	******************************************************************************/
	
	-- Declare outer loop variables

	DECLARE @RowNum int;
	DECLARE @MaxRowNum int;
	DECLARE @PartnerID int;

	-- Declare inner loop variables

	DECLARE @RowNum2 int;
	DECLARE @MaxRowNum2 int;
	DECLARE @ControlGroupID varchar(10);
	DECLARE @ControlGroupTypeID int;
	DECLARE @ControlGroupSuperSegment varchar(50)
	DECLARE @PublisherType varchar(40);
	DECLARE @MaxSpendDateForSegment date;
	DECLARE @CustomersRemoved int;
	DECLARE @NewCount int;

	/******************************************************************************
	Clear results table
	******************************************************************************/

	TRUNCATE TABLE [Report].[ControlSetup_SegmentationTransDates];

	/******************************************************************************
	Load PartnerIDs to iterate over
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs;

	SELECT
		PartnerID
		, ROW_NUMBER() OVER (ORDER BY PartnerID) AS RowNum
	INTO #PartnerIDs
	FROM (
		SELECT DISTINCT	PartnerID
		FROM #ControlGroups
	) x;

	/******************************************************************************
	Outer loop: Iterate over retailers
	******************************************************************************/

	SET @RowNum = 1;
	SET @MaxRowNum = (SELECT COUNT(*) FROM #PartnerIDs);

	WHILE @RowNum <= @MaxRowNum

	BEGIN
		
		SET @PartnerID = (SELECT PartnerID FROM #PartnerIDs WHERE RowNum = @RowNum);

		-- Load ConsumerCombinationIDs

		IF OBJECT_ID ('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs;

		SELECT DISTINCT
			p.PartnerID
			, cc.ConsumerCombinationID 
		INTO #CCIDs
		FROM Warehouse.Relational.[Partner] p		
		LEFT JOIN Warehouse.Relational.ConsumerCombination cc
			ON p.BrandID = cc.BrandID
		WHERE 
			p.PartnerID = @PartnerID;

		CREATE CLUSTERED INDEX CIX_CCIDs ON #CCIDs (ConsumerCombinationID);

		-- Load ControlGroupIDs associated with @PartnerID to iterate over in inner loop

		IF OBJECT_ID ('tempdb..#ControlGroupIDs') IS NOT NULL DROP TABLE #ControlGroupIDs;

		SELECT
			@PartnerID AS PartnerID
			, cg.ControlGroupID
			, cg.ControlGroupTypeID
			, cg.PublisherType
			, cg.SuperSegmentName
			, s.MaxAcquireDate
			, s.MaxLapsedDate
			, s.MaxShopperDate
			, ROW_NUMBER() OVER (ORDER BY cg.PartnerID) AS RowNum
		INTO #ControlGroupIDs
		FROM #ControlGroups cg
		CROSS JOIN #PartnerSettings s
		WHERE
			cg.PartnerID = @PartnerID
			AND s.PartnerID = @PartnerID;

		/******************************************************************************
		Inner loop: Iterate over control group IDs

		Create table for storing results:

		CREATE TABLE [Report].[ControlSetup_SegmentationTransDates] (
			ID int IDENTITY (1,1) NOT NULL
			, StartDate date 
			, PublisherType varchar(40)
			, PartnerID int
			, ControlGroupID int
			, ControlGroupTypeID int
			, ControlGroupSuperSegment varchar(40)
			, MaxSpendDateForSegment date
			, SpendersOverSegThresholdDate int
			, ReportDate date
			, CONSTRAINT PK_ControlsBI_ControlSetup_SegmentationTransDates PRIMARY KEY CLUSTERED (ID)
		);
		******************************************************************************/

		SET @RowNum2 = 1;
		SET @MaxRowNum2 = (SELECT COUNT(*) FROM #ControlGroupIDs);

		WHILE @RowNum2 <= @MaxRowNum2
		
		BEGIN
			
			SET @ControlGroupID = (SELECT ControlGroupID FROM #ControlGroupIDs WHERE RowNum = @RowNum2);
			SET @ControlGroupTypeID = (SELECT ControlGroupTypeID FROM #ControlGroupIDs WHERE RowNum = @RowNum2);
			SET @ControlGroupSuperSegment = (SELECT SuperSegmentName FROM #ControlGroupIDs WHERE RowNum = @RowNum2) 
			SET @PublisherType = (SELECT PublisherType FROM #ControlGroupIDs WHERE RowNum = @RowNum2);
			SET @MaxSpendDateForSegment = (
				SELECT 
					CASE SuperSegmentName
						WHEN 'Acquisition' THEN MaxAcquireDate
						WHEN 'Lapsed' THEN MaxLapsedDate
						WHEN 'Shopper' THEN MaxShopperDate
						ELSE NULL
					END
				FROM #ControlGroupIDs WHERE RowNum = @RowNum2
			);
			
			-- Load control group member CINIDs

			IF OBJECT_ID ('tempdb..#ControlCINs') IS NOT NULL DROP TABLE #ControlCINs;
			CREATE TABLE #ControlCINs (
				CINID int NOT NULL
				, FanID int NOT NULL
			);
				
			INSERT INTO #ControlCINs(CINID, FanID)
			SELECT	ci.CINID
				,	ci.FanID
			FROM #CINs ci
			WHERE EXISTS (	SELECT 1
							FROM [Report].[OfferReport_ControlGroupMembers] cgm
							WHERE cgm.FanID = ci.FanID
							AND cgm.controlgroupid = @ControlGroupID);

			CREATE CLUSTERED INDEX CIX_ControlCINs ON #ControlCINs (CINID);
			CREATE NONCLUSTERED INDEX NCIX_ControlCINs ON #ControlCINs (FanID);

			-- Load control group members in the incorrect segment

			IF OBJECT_ID ('tempdb..#ControlCINsToDelete') IS NOT NULL DROP TABLE #ControlCINsToDelete;

			SELECT	cm.CINID
			INTO #ControlCINsToDelete
			FROM #ControlCINs cm
			WHERE EXISTS (	SELECT 1
							FROM Warehouse.Relational.ConsumerTransaction ct
							WHERE EXISTS (	SELECT 1
											FROM #CCIDs cc
											WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID)
							AND ct.TranDate < @StartDate
							AND ct.Amount >0
							AND ct.TranDate >= @MaxSpendDateForSegment
							AND ct.CINID = cm.CINID)
			OPTION (RECOMPILE);

			-- delete control group members in the incorrect segment, and update the counts table

			DELETE cgm
			FROM [Report].[OfferReport_ControlGroupMembers] cgm
			WHERE controlgroupid = @ControlGroupID
			AND EXISTS (SELECT 1
						FROM #ControlCINs cm
						INNER JOIN #ControlCINsToDelete d
							ON cm.CINID = d.CINID
						WHERE cgm.FanID = cm.FanID);

			SET @CustomersRemoved = @@ROWCOUNT

			IF @CustomersRemoved > 0
				BEGIN

					SELECT @NewCount = COUNT(*)
					FROM [Report].[OfferReport_ControlGroupMembers]
					WHERE ControlGroupID = @ControlGroupID

					UPDATE [Report].[OfferReport_ControlGroupMembers_Counts]
					SET Customers = @NewCount
					,	ModifiedDate = GETDATE()
					WHERE ControlGroupID = @ControlGroupID

				END


			-- Load control group members spending beyond the cut-off date for the control group's ALS segment into ControlsBI_ControlSetup_SegmentationTransDates table

			INSERT INTO [Report].[ControlSetup_SegmentationTransDates] (
				StartDate
				, PublisherType
				, PartnerID
				, ControlGroupID
				, ControlGroupTypeID
				, ControlGroupSuperSegment
				, MaxSpendDateForSegment
				, SpendersOverSegThresholdDate
				, ReportDate
			)
			SELECT
				@StartDate
				, @PublisherType
				, @PartnerID
				, @ControlGroupID
				, @ControlGroupTypeID
				, @ControlGroupSuperSegment
				, @MaxSpendDateForSegment
				, 0 AS SpendersOverSegThresholdDate -- 0 after above delete
				, CAST(GETDATE() AS date) AS ReportDate;

			SET @RowNum2 = @RowNum2 + 1;
		
		END -- End inner loop (on control group IDs)

		SET @RowNum = @RowNum + 1;
	
	END -- End outer loop (on RetailerIDs)

END