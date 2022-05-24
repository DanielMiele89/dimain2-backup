/******************************************************************************
Author: Jason Shipp
Created: 06/09/2018
Purpose:
	- Part of KPMG BI Controls
	- Load count of control group members spending after the ALS threshold date for the associated retailer settings

------------------------------------------------------------------------------
Modification History

Jason Shipp 14/09/2018
	- Fixed bug in iteration variables: reset row counter variable to 1 between inner and outer loops

Jason Shipp 30/03/2020
	- Added delete of control members in the incorrect segment, and added update of the report table to reflect this

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlsBI_ControlSetup_SegmentationTransDates_Load]
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @SDate date = (SELECT StartDate FROM Warehouse.Staging.ControlSetup_Cycle_Dates);
	DECLARE @EDate date = (SELECT EndDate FROM Warehouse.Staging.ControlSetup_Cycle_Dates);

	/******************************************************************************
	Load partner alternates
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;

	SELECT 
		PartnerID
		, AlternatePartnerID
	INTO #PartnerAlternate
	FROM Warehouse.APW.PartnerAlternate
	UNION  
	SELECT  
		PartnerID
		, AlternatePartnerID
	FROM nFI.APW.PartnerAlternate;

	/******************************************************************************
	Load partner ALS settings
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerSettings') IS NOT NULL DROP TABLE #PartnerSettings

	SELECT 
		s.PartnerID
		, MAX(DATEADD(month, -s.Acquire, @SDate)) AS MaxAcquireDate
		, MAX(DATEADD(month, -s.Lapsed, @SDate)) AS MaxLapsedDate
		, MAX(DATEADD(month, -s.Shopper, @SDate)) AS MaxShopperDate
	INTO #PartnerSettings
	FROM Warehouse.Segmentation.ROC_Shopper_Segment_Partner_Settings s
	GROUP BY
		s.PartnerID;		

	/******************************************************************************
	Load relevant Warehouse, nFI and AMEX ControlGroupIDs
	******************************************************************************/

	IF OBJECT_ID('tempdb..#ControlGroups') IS NOT NULL DROP TABLE #ControlGroups;

	CREATE TABLE #ControlGroups (
		ControlGroupID int NOT NULL
		, ControlGroupTypeID int NOT NULL
		, PartnerID int NOT NULL
		, SuperSegmentName varchar(40) NOT NULL
		, PublisherType varchar(40) NOT NULL
	);
	
	-- Warehouse ControlGroupIDs

	INSERT INTO #ControlGroups (ControlGroupID, ControlGroupTypeID, PartnerID, SuperSegmentName, PublisherType)
	SELECT DISTINCT
		ioc.controlgroupid
		, CASE WHEN sec.ControlGroupID IS NOT NULL OR sec2.RetailerID IS NOT NULL THEN 1 ELSE 0 END AS ControlGroupTypeID
		, COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
		, seg.SuperSegmentName
		, 'Warehouse' AS PublisherType
	FROM Warehouse.Relational.ironoffercycles ioc
	LEFT JOIN (SELECT DISTINCT ControlGroupID FROM Warehouse.Relational.SecondaryControlGroups) sec
		ON ioc.ControlGroupID = sec.ControlGroupID
	INNER JOIN Warehouse.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	INNER JOIN Warehouse.Relational.IronOffer o
		ON ioc.ironofferid = o.IronOfferID
	LEFT JOIN Warehouse.Relational.IronOfferSegment seg
		ON o.IronOfferID = seg.IronOfferID
	LEFT JOIN #PartnerAlternate pa
		ON o.PartnerID = pa.PartnerID
	LEFT JOIN Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers sec2
		ON pa.AlternatePartnerID = sec2.RetailerID OR o.PartnerID = sec2.RetailerID
	WHERE 
		cyc.EndDate >= @SDate
		AND cyc.StartDate <= @EDate
		AND seg.OfferTypeDescription <> 'Universal'
		AND seg.SuperSegmentID IS NOT NULL;

	-- nFI ControlGroupIDs

	INSERT INTO #ControlGroups (ControlGroupID, ControlGroupTypeID, PartnerID, SuperSegmentName, PublisherType)
	SELECT DISTINCT
		ioc.controlgroupid
		, CASE WHEN sec.ControlGroupID IS NOT NULL OR sec2.RetailerID IS NOT NULL THEN 1 ELSE 0 END AS ControlGroupTypeID
		, COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
		, seg.SuperSegmentName
		, 'nFI' AS PublisherType
	FROM nFI.Relational.ironoffercycles ioc
	LEFT JOIN (SELECT DISTINCT ControlGroupID FROM nFI.Relational.SecondaryControlGroups) sec
		ON ioc.ControlGroupID = sec.ControlGroupID
	INNER JOIN nFI.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	INNER JOIN nFI.Relational.IronOffer o
		ON ioc.ironofferid = o.ID
	LEFT JOIN Warehouse.Relational.IronOfferSegment seg
		ON o.ID = seg.IronOfferID
	LEFT JOIN #PartnerAlternate pa
		ON o.PartnerID = pa.PartnerID
	LEFT JOIN Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers sec2
		ON pa.AlternatePartnerID = sec2.RetailerID OR o.PartnerID = sec2.RetailerID
	WHERE 
		cyc.EndDate >= @SDate
		AND cyc.StartDate <= @EDate
		AND seg.OfferTypeDescription <> 'Universal'
		AND seg.SuperSegmentID IS NOT NULL;

	-- Virgin ControlGroupIDs

	INSERT INTO #ControlGroups (ControlGroupID, ControlGroupTypeID, PartnerID, SuperSegmentName, PublisherType)
	SELECT DISTINCT
		ioc.controlgroupid
		, CASE WHEN sec.ControlGroupID IS NOT NULL OR sec2.RetailerID IS NOT NULL THEN 1 ELSE 0 END AS ControlGroupTypeID
		, COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
		, seg.SuperSegmentName
		, 'Virgin' AS PublisherType
	FROM [WH_Virgin].[Report].[IronOfferCycles] ioc
	LEFT JOIN (SELECT DISTINCT ControlGroupID FROM nFI.Relational.SecondaryControlGroups WHERE 1 = 2) sec
		ON ioc.ControlGroupID = sec.ControlGroupID
	INNER JOIN [WH_Virgin].[Report].[OfferCycles] cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	INNER JOIN [WH_Virgin].[Derived].[IronOffer] o
		ON ioc.ironofferid = o.ironofferid
	LEFT JOIN Warehouse.Relational.IronOfferSegment seg
		ON o.ironofferid = seg.IronOfferID
	LEFT JOIN #PartnerAlternate pa
		ON o.PartnerID = pa.PartnerID
	LEFT JOIN Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers sec2
		ON pa.AlternatePartnerID = sec2.RetailerID OR o.PartnerID = sec2.RetailerID
	WHERE 
		cyc.EndDate >= @SDate
		AND cyc.StartDate <= @EDate
		AND seg.OfferTypeDescription <> 'Universal'
		AND seg.SuperSegmentID IS NOT NULL;

	-- AMEX ControlGroupIDs

	INSERT INTO #ControlGroups (ControlGroupID, ControlGroupTypeID, PartnerID, SuperSegmentName, PublisherType)
	SELECT DISTINCT
		ioc.AmexControlGroupID AS ControlGroupID
		, 0 AS ControlGroupTypeID
		, COALESCE(pa.AlternatePartnerID, o.RetailerID) AS PartnerID
		, seg.SuperSegmentName
		, 'AMEX' AS PublisherType
	FROM nFI.Relational.AmexIronOfferCycles ioc
	INNER JOIN nFI.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	INNER JOIN nFI.Relational.AmexOffer o
		ON ioc.AmexIronOfferID = o.IronOfferID
	LEFT JOIN Warehouse.Relational.IronOfferSegment seg
		ON o.IronOfferID = seg.IronOfferID
	LEFT JOIN #PartnerAlternate pa
		ON o.RetailerID = pa.PartnerID
	WHERE 
		cyc.EndDate >= @SDate
		AND cyc.StartDate <= @EDate
		AND seg.OfferTypeDescription <> 'Universal'
		AND seg.SuperSegmentID IS NOT NULL;

	CREATE CLUSTERED INDEX CIX_ControlGroups_Warehouse ON #ControlGroups (controlgroupid, PartnerID);

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
	DECLARE @NewCount int;

	/******************************************************************************
	Clear results table
	******************************************************************************/

	TRUNCATE TABLE Warehouse.Staging.ControlsBI_ControlSetup_SegmentationTransDates;

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

		CREATE TABLE Warehouse.Staging.ControlsBI_ControlSetup_SegmentationTransDates (
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

			IF @PublisherType = 'Warehouse' 
			BEGIN
				
				INSERT INTO #ControlCINs(CINID, FanID)
				SELECT
					cl.CINID
					, cm.FanID
				FROM Warehouse.Relational.controlgroupmembers cm
				INNER JOIN SLC_Report.dbo.Fan f
					ON cm.FanID = f.ID
				INNER JOIN Warehouse.Relational.CINList cl
					ON cl.CIN = f.SourceUID
				WHERE
					cm.controlgroupid = @ControlGroupID;

			END

			ELSE IF @PublisherType = 'nFI' 
			BEGIN

				INSERT INTO #ControlCINs(CINID, FanID)
				SELECT
					cl.CINID
					, cm.fanid
				FROM nFI.Relational.controlgroupmembers cm
				INNER JOIN SLC_Report.dbo.Fan f
					ON cm.FanID = f.ID
				INNER JOIN Warehouse.Relational.CINList cl
					ON cl.CIN = f.SourceUID
				WHERE
					cm.controlgroupid = @ControlGroupID;

			END

			ELSE IF @PublisherType = 'Virgin' 
			BEGIN

				INSERT INTO #ControlCINs(CINID, FanID)
				SELECT
					cl.CINID
					, cm.fanid
				FROM [WH_Virgin].[Report].[ControlGroupMembers] cm
				INNER JOIN [SLC_Report].[dbo].[Fan] fa
					ON cm.FanID = fa.ID
				INNER JOIN [Warehouse].[Relational].[CINList] cl
					ON cl.CIN = fa.SourceUID
				WHERE
					cm.controlgroupid = @ControlGroupID;

			END

			ELSE IF @PublisherType = 'AMEX' 
			BEGIN

				INSERT INTO #ControlCINs(CINID, FanID)
				SELECT
					cl.CINID
					, cm.FanID
				FROM nFI.Relational.AmexControlGroupMembers cm
				INNER JOIN SLC_Report.dbo.Fan f
					ON cm.FanID = f.ID
				INNER JOIN Warehouse.Relational.CINList cl
					ON cl.CIN = f.SourceUID
				WHERE
					cm.AmexControlgroupID = @ControlGroupID;

			END

			CREATE CLUSTERED INDEX CIX_ControlCINs ON #ControlCINs (CINID);
			CREATE NONCLUSTERED INDEX NCIX_ControlCINs ON #ControlCINs (FanID);

			-- Load control group members in the incorrect segment

			IF OBJECT_ID ('tempdb..#ControlCINsToDelete') IS NOT NULL DROP TABLE #ControlCINsToDelete;

			SELECT DISTINCT
				ct.CINID
			INTO #ControlCINsToDelete
			FROM Warehouse.Relational.ConsumerTransaction ct
			WHERE 
				ct.ConsumerCombinationID IN (SELECT ConsumerCombinationID FROM #CCIDs)
				AND ct.TranDate < @SDate
				AND ct.Amount >0
				AND ct.TranDate >= @MaxSpendDateForSegment
				AND EXISTS (
					SELECT NULL FROM #ControlCINs cm
					WHERE
						ct.CINID = cm.CINID
				)
			OPTION (RECOMPILE);

			-- delete control group members in the incorrect segment, and update the counts table

			IF @PublisherType = 'Warehouse' 
			BEGIN

				DELETE FROM Warehouse.Relational.controlgroupmembers 
				WHERE 
				controlgroupid = @ControlGroupID
				AND FanID IN (
					SELECT 
					cm.FanID FROM #ControlCINs cm
					INNER JOIN #ControlCINsToDelete d
					ON cm.CINID = d.CINID
					WHERE
					cm.FanID IS NOT NULL
				);

				SET @NewCount = (
					SELECT COUNT(*) FROM Warehouse.Relational.controlgroupmembers
					WHERE ControlGroupID = @ControlGroupID
				);

				UPDATE Warehouse.Relational.ControlGroupMember_Counts
				SET NumberofFanIDs = @NewCount
				WHERE ControlGroupID = @ControlGroupID;

			END

			IF @PublisherType = 'nFI' 
			BEGIN

				DELETE FROM nFI.Relational.controlgroupmembers 
				WHERE 
				controlgroupid = @ControlGroupID
				AND FanID IN (
					SELECT 
					cm.FanID FROM #ControlCINs cm
					INNER JOIN #ControlCINsToDelete d
					ON cm.CINID = d.CINID
					WHERE
					cm.FanID IS NOT NULL
				);

				SET @NewCount = (
					SELECT COUNT(*) FROM nFI.Relational.controlgroupmembers
					WHERE ControlGroupID = @ControlGroupID
				);

				UPDATE nFI.Relational.ControlGroupMember_Counts
				SET NumberofFanIDs = @NewCount
				WHERE ControlGroupID = @ControlGroupID;
			
			END

			IF @PublisherType = 'Virgin' 
			BEGIN

				DELETE FROM [WH_Virgin].[Report].[ControlGroupMembers] 
				WHERE 
				controlgroupid = @ControlGroupID
				AND FanID IN (
					SELECT 
					cm.FanID FROM #ControlCINs cm
					INNER JOIN #ControlCINsToDelete d
					ON cm.CINID = d.CINID
					WHERE
					cm.FanID IS NOT NULL
				);

				SET @NewCount = (
					SELECT COUNT(*) FROM [WH_Virgin].[Report].[ControlGroupMembers]
					WHERE ControlGroupID = @ControlGroupID
				);

				UPDATE [WH_Virgin].[Report].[ControlGroupMember_Counts]
				SET NumberofFanIDs = @NewCount
				WHERE ControlGroupID = @ControlGroupID;
			
			END

			IF @PublisherType = 'AMEX' 
			BEGIN

				DELETE FROM nFI.Relational.AmexControlGroupMembers 
				WHERE 
				AmexControlgroupID = @ControlGroupID
				AND FanID IN (
					SELECT 
					cm.FanID FROM #ControlCINs cm
					INNER JOIN #ControlCINsToDelete d
					ON cm.CINID = d.CINID
					WHERE
					cm.FanID IS NOT NULL
				);

				SET @NewCount = (
					SELECT COUNT(*) FROM nFI.Relational.AmexControlGroupMembers
					WHERE AmexControlgroupID = @ControlGroupID
				);

				UPDATE nFI.Relational.AmexControlGroupMember_Counts
				SET NumberofFanIDs = @NewCount
				WHERE AmexControlGroupID = @ControlGroupID;
			END

			-- Load control group members spending beyond the cut-off date for the control group's ALS segment into ControlsBI_ControlSetup_SegmentationTransDates table

			INSERT INTO Warehouse.Staging.ControlsBI_ControlSetup_SegmentationTransDates (
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
				@SDate
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