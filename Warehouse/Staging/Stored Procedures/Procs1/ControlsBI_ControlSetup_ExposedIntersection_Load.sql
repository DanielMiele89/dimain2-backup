/******************************************************************************
Author: Jason Shipp
Created: 04/09/2018
Purpose:
	- Part of KPMG BI Controls
	- Load counts of Iron Offer control group members who are also in the exposed group in the same Campaign Cycle 

------------------------------------------------------------------------------
Modification History

Jason Shipp 14/09/2018
	- Optimised query by structuring query execution over two loops: 1) over ControlGroupIDs, and 2) over IronOfferCyclesIDs

Jason Shipp 30/03/2020
	- Added delete of exposed-control intersection, and added update of the report table to reflect this
	
******************************************************************************/
CREATE PROCEDURE [Staging].[ControlsBI_ControlSetup_ExposedIntersection_Load]
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @SDate date = (SELECT StartDate FROM Warehouse.Staging.ControlSetup_Cycle_Dates);
	DECLARE @EDate date = (SELECT EndDate FROM Warehouse.Staging.ControlSetup_Cycle_Dates);

	/******************************************************************************
	Clear results table

	Create table for storing results:

	CREATE TABLE Warehouse.Staging.ControlsBI_ControlSetup_ExposedIntersection (
		ID int IDENTITY (1,1) NOT NULL
		, StartDate date
		, PublisherType varchar(40)
		, IronOfferID int
		, OfferTypeForReports varchar(100)
		, PartnerID int
		, ControlGroupID int
		, ControlGroupTypeID int
		, IronOfferCyclesID int
		, ControlMembers int
		, ExposedMembers int
		, ControlExposedMembers int
		, ControlExposedMembersProportion float
		, ReportDate date
		, CONSTRAINT PK_ControlsBI_ControlSetup_ExposedIntersection PRIMARY KEY CLUSTERED (ID) 
	);
	******************************************************************************/

	TRUNCATE TABLE Warehouse.Staging.ControlsBI_ControlSetup_ExposedIntersection;

	/******************************************************************************
	/******************************************************************************
	Warehouse
	******************************************************************************/
	******************************************************************************/

	/******************************************************************************
	Load relevant Warehouse cycles
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Cycles_Warehouse') IS NOT NULL DROP TABLE #Cycles_Warehouse;

	SELECT 
		ioc.controlgroupid
		, ioc.ironoffercyclesid
		, CAST(cyc.StartDate AS date) AS StartDate
		, CAST(cyc.EndDate AS date) AS EndDate
		, ROW_NUMBER() OVER (ORDER BY ioc.controlgroupid, ioc.ironoffercyclesid, cyc.StartDate) AS RowNum
	INTO #Cycles_Warehouse	
	FROM Warehouse.Relational.ironoffercycles ioc
	INNER JOIN Warehouse.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	WHERE 
		cyc.EndDate >= @SDate
		AND cyc.StartDate <= @EDate;

	/******************************************************************************
	Load Warehouse ControlGroupIDs to iterate over
	******************************************************************************/

	IF OBJECT_ID('tempdb..#ControlGroupIDs_Warehouse') IS NOT NULL DROP TABLE #ControlGroupIDs_Warehouse;

	SELECT
		ControlGroupID
		, ROW_NUMBER() OVER (ORDER BY ControlGroupID) AS RowNum
	INTO #ControlGroupIDs_Warehouse
	FROM (
		SELECT DISTINCT	controlgroupid
		FROM #Cycles_Warehouse
	) x;

	/******************************************************************************
	Load iteration variables
	******************************************************************************/

	-- Declare outer loop variables

	DECLARE @RowNum_Warehouse int;
	DECLARE @MaxRowNum_Warehouse int;
	DECLARE @ControlGroupID_Warehouse int;
	
	-- Declare inner loop variables

	DECLARE @RowNum_Warehouse2 int;
	DECLARE @MaxRowNum_Warehouse2 int;
	DECLARE @IronOfferCyclesID_Warehouse int;
	DECLARE @NewCount_Warehouse int;

	/******************************************************************************
	Outer loop: Iterate over ControlGroupIDs
	******************************************************************************/

	SET @RowNum_Warehouse = 1;
	SET @MaxRowNum_Warehouse = (SELECT COUNT(*) FROM #ControlGroupIDs_Warehouse);

	WHILE @RowNum_Warehouse < @MaxRowNum_Warehouse

	BEGIN
		
		SET @ControlGroupID_Warehouse = (SELECT ControlGroupID FROM #ControlGroupIDs_Warehouse WHERE RowNum = @RowNum_Warehouse);

		-- Load control FanIDs

		IF OBJECT_ID('tempdb..#ControlFanIDs_Warehouse') IS NOT NULL DROP TABLE #ControlFanIDs_Warehouse;

		SELECT 
			FanID
		INTO #ControlFanIDs_Warehouse
		FROM Warehouse.Relational.controlgroupmembers
		WHERE
			controlgroupid = @ControlGroupID_Warehouse;

		CREATE CLUSTERED INDEX CIX_ControlFanIDs_Warehouse ON #ControlFanIDs_Warehouse (FanID);

		-- Load IronOfferCyclesIDs associated with the ControlGroupID variable to iterate over in inner loop

		IF OBJECT_ID ('tempdb..#IronOfferCyclesIDs_Warehouse') IS NOT NULL DROP TABLE #IronOfferCyclesIDs_Warehouse;

		SELECT 
			@ControlGroupID_Warehouse AS ControlGroupID
			, cyc.ironoffercyclesid AS IronOfferCyclesID
			, ROW_NUMBER () OVER (ORDER BY IronOfferCyclesID) AS RowNum
		INTO #IronOfferCyclesIDs_Warehouse
		FROM #Cycles_Warehouse cyc
		WHERE controlgroupid = @ControlGroupID_Warehouse;

		/******************************************************************************
		Inner loop: Iterate over IronOfferCyclesIDs
		******************************************************************************/

		SET @RowNum_Warehouse2 = 1;
		SET @MaxRowNum_Warehouse2 = (SELECT COUNT(*) FROM #IronOfferCyclesIDs_Warehouse);

		WHILE @RowNum_Warehouse2 <= @MaxRowNum_Warehouse2

		BEGIN

			SET @IronOfferCyclesID_Warehouse = (SELECT IronOfferCyclesID FROM #IronOfferCyclesIDs_Warehouse WHERE RowNum = @RowNum_Warehouse2);

			-- Load exposed FanIDs

			IF OBJECT_ID('tempdb..#ExposedFanIDs_Warehouse') IS NOT NULL DROP TABLE #ExposedFanIDs_Warehouse;

			SELECT
				FanID
			INTO #ExposedFanIDs_Warehouse
			FROM Warehouse.Relational.CampaignHistory
			WHERE 
				ironoffercyclesid = @IronOfferCyclesID_Warehouse;

			CREATE CLUSTERED INDEX CIX_ExposedFanIDs_Warehouse ON #ExposedFanIDs_Warehouse (FanID);

			-- Load Warehouse members in the exposed and control group for the same Iron Offer

			IF OBJECT_ID('tempdb..#ExposedControlIntersection_Warehouse_ToDelete') IS NOT NULL DROP TABLE #ExposedControlIntersection_Warehouse_ToDelete;

			SELECT
				@IronOfferCyclesID_Warehouse AS IronOfferCyclesID
				, @ControlGroupID_Warehouse AS ControlGroupID
				, c.fanid
			INTO #ExposedControlIntersection_Warehouse_ToDelete
			FROM #ControlFanIDs_Warehouse c
			INNER JOIN #ExposedFanIDs_Warehouse e
				ON c.fanid = e.fanid
			OPTION(RECOMPILE);

			CREATE CLUSTERED INDEX CIX_ExposedControlIntersection_Warehouse_ToDelete ON #ExposedControlIntersection_Warehouse_ToDelete (fanid);

			-- Delete intersection

			DELETE FROM Warehouse.Relational.controlgroupmembers 
			WHERE 
			controlgroupid = @ControlGroupID_Warehouse
			AND FanID IN (SELECT FanID FROM #ExposedControlIntersection_Warehouse_ToDelete);

			-- Update counts table

			SET @NewCount_Warehouse = (
				SELECT COUNT(*) FROM Warehouse.Relational.controlgroupmembers
				WHERE ControlGroupID = @ControlGroupID_Warehouse
			);

			UPDATE Warehouse.Relational.ControlGroupMember_Counts
			SET NumberofFanIDs = @NewCount_Warehouse
			WHERE ControlGroupID = @ControlGroupID_Warehouse;

			-- Load new intersection results

			IF OBJECT_ID('tempdb..#ExposedControlIntersection_Warehouse') IS NOT NULL DROP TABLE #ExposedControlIntersection_Warehouse;

			SELECT
				@IronOfferCyclesID_Warehouse AS IronOfferCyclesID
				, @ControlGroupID_Warehouse AS ControlGroupID
				, 0 AS ControlExposedMembers -- 0 after above delete
			INTO #ExposedControlIntersection_Warehouse;

			-- Load Warehouse results

			IF OBJECT_ID('tempdb..#Results_Warehouse') IS NOT NULL DROP TABLE #Results_Warehouse;

			WITH ControlMembers AS (
				SELECT DISTINCT
					i.ControlGroupID
					, COUNT(*) AS ControlMembers
				FROM #ExposedControlIntersection_Warehouse i
				INNER JOIN Warehouse.Relational.controlgroupmembers c
					ON i.controlgroupid = c.controlgroupid
				GROUP BY 
					i.ControlGroupID
			)
			, ExposedMembers AS (
				SELECT DISTINCT
					i.ironoffercyclesid
					, COUNT(*) AS ExposedMembers
				FROM #ExposedControlIntersection_Warehouse i
				INNER JOIN Warehouse.Relational.CampaignHistory h
					ON i.ironoffercyclesid = h.ironoffercyclesid
				GROUP BY 
					i.ironoffercyclesid
				)
			SELECT 
				o.IronOfferID
				, s.OfferTypeForReports
				, o.PartnerID
				, i.ControlGroupID
				, i.IronOfferCyclesID
				, c.ControlMembers
				, e.ExposedMembers
				, i.ControlExposedMembers
			INTO #Results_Warehouse
			FROM #ExposedControlIntersection_Warehouse i
			LEFT JOIN ControlMembers c
				ON i.controlgroupid = c.controlgroupid
			LEFT JOIN ExposedMembers e
				ON i.ironoffercyclesid = e.ironoffercyclesid
			LEFT JOIN Warehouse.Relational.ironoffercycles cyc
				ON i.ironoffercyclesid = cyc.ironoffercyclesid
			LEFT JOIN Warehouse.Relational.IronOffer o
				ON cyc.ironofferid = o.IronOfferID
			LEFT JOIN Warehouse.Relational.IronOfferSegment s
				ON o.IronOfferID = s.IronOfferID
			OPTION(RECOMPILE);

			-- Load results into Warehouse.Staging.ControlsBI_ControlSetup_ExposedIntersection table

			INSERT INTO Warehouse.Staging.ControlsBI_ControlSetup_ExposedIntersection (
				StartDate
				, PublisherType
				, IronOfferID
				, OfferTypeForReports
				, PartnerID
				, ControlGroupID
				, ControlGroupTypeID
				, IronOfferCyclesID
				, ControlMembers
				, ExposedMembers
				, ControlExposedMembers
				, ControlExposedMembersProportion
				, ReportDate
			)
			SELECT 
				@SDate AS StartDate
				, 'Warehouse' AS PublisherType
				, r.IronOfferID
				, r.OfferTypeForReports
				, r.PartnerID
				, r.ControlGroupID
				, CASE WHEN sec.ControlGroupID IS NOT NULL OR sec2.PartnerID IS NOT NULL THEN 1 ELSE 0 END AS ControlGroupTypeID
				, r.IronOfferCyclesID
				, r.ControlMembers
				, r.ExposedMembers
				, r.ControlExposedMembers
				, ISNULL(CAST(r.ControlExposedMembers AS float)/NULLIF(r.ExposedMembers, 0), 0) AS ControlExposedMembersProportion
				, CAST(GETDATE() AS date) AS ReportDate
			FROM #Results_Warehouse r
			LEFT JOIN (SELECT DISTINCT ControlGroupID FROM Warehouse.Relational.SecondaryControlGroups) sec
				ON r.ControlGroupID = sec.ControlGroupID
			LEFT JOIN (
					SELECT r.RetailerID AS PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
					UNION 
					SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
					INNER JOIN Warehouse.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
					UNION
					SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
					INNER JOIN nFI.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
			) sec2
				ON r.PartnerID = sec2.PartnerID;

			SET @RowNum_Warehouse2 = @RowNum_Warehouse2 + 1;

		END -- End inner loop (on IronOfferCyclesIDs)

		SET @RowNum_Warehouse = @RowNum_Warehouse + 1;

	END -- End outer loop (on ControlGroupIDs)

	/******************************************************************************
	/******************************************************************************
	nFI
	******************************************************************************/
	******************************************************************************/

	/******************************************************************************
	Load relevant nFI cycles
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Cycles_nFI') IS NOT NULL DROP TABLE #Cycles_nFI;

	SELECT 
		ioc.controlgroupid
		, ioc.ironoffercyclesid
		, CAST(cyc.StartDate AS date) AS StartDate
		, CAST(cyc.EndDate AS date) AS EndDate
		, ROW_NUMBER() OVER (ORDER BY ioc.controlgroupid, ioc.ironoffercyclesid, cyc.StartDate) AS RowNum
	INTO #Cycles_nFI	
	FROM nFI.Relational.ironoffercycles ioc
	INNER JOIN nFI.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	WHERE 
		cyc.EndDate >= @SDate
		AND cyc.StartDate <= @EDate;

	/******************************************************************************
	Load nFI ControlGroupIDs to iterate over
	******************************************************************************/

	IF OBJECT_ID('tempdb..#ControlGroupIDs_nFI') IS NOT NULL DROP TABLE #ControlGroupIDs_nFI;

	SELECT
		ControlGroupID
		, ROW_NUMBER() OVER (ORDER BY ControlGroupID) AS RowNum
	INTO #ControlGroupIDs_nFI
	FROM (
		SELECT DISTINCT	controlgroupid
		FROM #Cycles_nFI
	) x;

	/******************************************************************************
	Load iteration variables
	******************************************************************************/

	-- Declare outer loop variables

	DECLARE @RowNum_nFI int;
	DECLARE @MaxRowNum_nFI int;
	DECLARE @ControlGroupID_nFI int;
	
	-- Declare inner loop variables

	DECLARE @RowNum_nFI2 int;
	DECLARE @MaxRowNum_nFI2 int;
	DECLARE @IronOfferCyclesID_nFI int;
	DECLARE @NewCount_nFI int;

	/******************************************************************************
	Outer loop: Iterate over ControlGroupIDs
	******************************************************************************/

	SET @RowNum_nFI = 1;
	SET @MaxRowNum_nFI = (SELECT COUNT(*) FROM #ControlGroupIDs_nFI);

	WHILE @RowNum_nFI < @MaxRowNum_nFI

	BEGIN
		
		SET @ControlGroupID_nFI = (SELECT ControlGroupID FROM #ControlGroupIDs_nFI WHERE RowNum = @RowNum_nFI);

		-- Load control FanIDs

		IF OBJECT_ID('tempdb..#ControlFanIDs_nFI') IS NOT NULL DROP TABLE #ControlFanIDs_nFI;

		SELECT 
			FanID
		INTO #ControlFanIDs_nFI
		FROM nFI.Relational.controlgroupmembers
		WHERE
			controlgroupid = @ControlGroupID_nFI;

		CREATE CLUSTERED INDEX CIX_ControlFanIDs_nFI ON #ControlFanIDs_nFI (FanID);

		-- Load IronOfferCyclesIDs associated with the ControlGroupID variable to iterate over in inner loop

		IF OBJECT_ID ('tempdb..#IronOfferCyclesIDs_nFI') IS NOT NULL DROP TABLE #IronOfferCyclesIDs_nFI;

		SELECT 
			@ControlGroupID_nFI AS ControlGroupID
			, cyc.ironoffercyclesid AS IronOfferCyclesID
			, ROW_NUMBER () OVER (ORDER BY IronOfferCyclesID) AS RowNum
		INTO #IronOfferCyclesIDs_nFI
		FROM #Cycles_nFI cyc
		WHERE controlgroupid = @ControlGroupID_nFI;

		/******************************************************************************
		Inner loop: Iterate over IronOfferCyclesIDs
		******************************************************************************/

		SET @RowNum_nFI2 = 1;
		SET @MaxRowNum_nFI2 = (SELECT COUNT(*) FROM #IronOfferCyclesIDs_nFI);

		WHILE @RowNum_nFI2 <= @MaxRowNum_nFI2

		BEGIN

			SET @IronOfferCyclesID_nFI = (SELECT IronOfferCyclesID FROM #IronOfferCyclesIDs_nFI WHERE RowNum = @RowNum_nFI2);

			-- Load exposed FanIDs

			IF OBJECT_ID('tempdb..#ExposedFanIDs_nFI') IS NOT NULL DROP TABLE #ExposedFanIDs_nFI;

			SELECT
				FanID
			INTO #ExposedFanIDs_nFI
			FROM nFI.Relational.CampaignHistory
			WHERE 
				ironoffercyclesid = @IronOfferCyclesID_nFI;

			CREATE CLUSTERED INDEX CIX_ExposedFanIDs_nFI ON #ExposedFanIDs_nFI (FanID);

			-- Load nFI members in the exposed and control group for the same Iron Offer

			IF OBJECT_ID('tempdb..#ExposedControlIntersection_nFI_ToDelete') IS NOT NULL DROP TABLE #ExposedControlIntersection_nFI_ToDelete;

			SELECT
				@IronOfferCyclesID_nFI AS IronOfferCyclesID
				, @ControlGroupID_nFI AS ControlGroupID
				, c.FanID
			INTO #ExposedControlIntersection_nFI_ToDelete
			FROM #ControlFanIDs_nFI c
			INNER JOIN #ExposedFanIDs_nFI e
				ON c.fanid = e.fanid
			OPTION(RECOMPILE);

			CREATE CLUSTERED INDEX CIX_ExposedControlIntersection_nFI_ToDelete ON #ExposedControlIntersection_nFI_ToDelete (FanID);

			-- Delete intersection

			DELETE FROM nFI.Relational.controlgroupmembers 
			WHERE 
			controlgroupid = @ControlGroupID_nFi
			AND FanID IN (SELECT FanID FROM #ExposedControlIntersection_nFI_ToDelete);

			-- Update counts table

			SET @NewCount_nFI = (
				SELECT COUNT(*) FROM nFI.Relational.controlgroupmembers
				WHERE ControlGroupID = @ControlGroupID_nFI
			);

			UPDATE nFI.Relational.ControlGroupMember_Counts
			SET NumberofFanIDs = @NewCount_nFI
			WHERE ControlGroupID = @ControlGroupID_nFI;

			-- Load new intersection results

			IF OBJECT_ID('tempdb..#ExposedControlIntersection_nFI') IS NOT NULL DROP TABLE #ExposedControlIntersection_nFI;

			SELECT
				@IronOfferCyclesID_nFI AS IronOfferCyclesID
				, @ControlGroupID_nFI AS ControlGroupID
				, 0 AS ControlExposedMembers -- 0 after above delete
			INTO #ExposedControlIntersection_nFI;

			-- Load nFI results

			IF OBJECT_ID('tempdb..#Results_nFI') IS NOT NULL DROP TABLE #Results_nFI;

			WITH ControlMembers AS (
				SELECT DISTINCT
					i.ControlGroupID
					, COUNT(*) AS ControlMembers
				FROM #ExposedControlIntersection_nFI i
				INNER JOIN nFI.Relational.controlgroupmembers c
					ON i.controlgroupid = c.controlgroupid
				GROUP BY 
					i.ControlGroupID
			)
			, ExposedMembers AS (
				SELECT DISTINCT
					i.ironoffercyclesid
					, COUNT(*) AS ExposedMembers
				FROM #ExposedControlIntersection_nFI i
				INNER JOIN nFI.Relational.CampaignHistory h
					ON i.ironoffercyclesid = h.ironoffercyclesid
				GROUP BY 
					i.ironoffercyclesid
				)
			SELECT 
				o.ID AS IronOfferID
				, s.OfferTypeForReports
				, o.PartnerID
				, i.ControlGroupID
				, i.IronOfferCyclesID
				, c.ControlMembers
				, e.ExposedMembers
				, i.ControlExposedMembers
			INTO #Results_nFI
			FROM #ExposedControlIntersection_nFI i
			LEFT JOIN ControlMembers c
				ON i.controlgroupid = c.controlgroupid
			LEFT JOIN ExposedMembers e
				ON i.ironoffercyclesid = e.ironoffercyclesid
			LEFT JOIN nFI.Relational.ironoffercycles cyc
				ON i.ironoffercyclesid = cyc.ironoffercyclesid
			LEFT JOIN nFI.Relational.IronOffer o
				ON cyc.ironofferid = o.ID
			LEFT JOIN Warehouse.Relational.IronOfferSegment s
				ON o.ID = s.IronOfferID
			OPTION(RECOMPILE);

			-- Load results into Warehouse.Staging.ControlsBI_ControlSetup_ExposedIntersection table

			INSERT INTO Warehouse.Staging.ControlsBI_ControlSetup_ExposedIntersection (
				StartDate
				, PublisherType
				, IronOfferID
				, OfferTypeForReports
				, PartnerID
				, ControlGroupID
				, ControlGroupTypeID
				, IronOfferCyclesID
				, ControlMembers
				, ExposedMembers
				, ControlExposedMembers
				, ControlExposedMembersProportion
				, ReportDate
			)
			SELECT 
				@SDate AS StartDate
				, 'nFI' AS PublisherType
				, r.IronOfferID
				, r.OfferTypeForReports
				, r.PartnerID
				, r.ControlGroupID
				, CASE WHEN sec.ControlGroupID IS NOT NULL OR sec2.PartnerID IS NOT NULL THEN 1 ELSE 0 END AS ControlGroupTypeID
				, r.IronOfferCyclesID
				, r.ControlMembers
				, r.ExposedMembers
				, r.ControlExposedMembers
				, ISNULL(CAST(r.ControlExposedMembers AS float)/NULLIF(r.ExposedMembers, 0), 0) AS ControlExposedMembersProportion
				, CAST(GETDATE() AS date) AS ReportDate
			FROM #Results_nFI r
			LEFT JOIN (SELECT DISTINCT ControlGroupID FROM nFI.Relational.SecondaryControlGroups) sec
				ON r.ControlGroupID = sec.ControlGroupID
			LEFT JOIN (
					SELECT r.RetailerID AS PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
					UNION 
					SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
					INNER JOIN Warehouse.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
					UNION
					SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
					INNER JOIN nFI.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
			) sec2
				ON r.PartnerID = sec2.PartnerID;

			SET @RowNum_nFI2 = @RowNum_nFI2 + 1;

		END -- End inner loop (on IronOfferCyclesIDs)

		SET @RowNum_nFI = @RowNum_nFI + 1;

	END -- End outer loop (on ControlGroupIDs)





	/******************************************************************************
	/******************************************************************************
	Virgin
	******************************************************************************/
	******************************************************************************/

	/******************************************************************************
	Load relevant nFI cycles
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Cycles_Virgin') IS NOT NULL DROP TABLE #Cycles_Virgin;

	SELECT 
		ioc.controlgroupid
		, ioc.ironoffercyclesid
		, CAST(cyc.StartDate AS date) AS StartDate
		, CAST(cyc.EndDate AS date) AS EndDate
		, ROW_NUMBER() OVER (ORDER BY ioc.controlgroupid, ioc.ironoffercyclesid, cyc.StartDate) AS RowNum
	INTO #Cycles_Virgin	
	FROM [WH_Virgin].[Report].[IronOfferCycles] ioc
	INNER JOIN [WH_Virgin].[Report].[OfferCycles] cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	WHERE 
		cyc.EndDate >= @SDate
		AND cyc.StartDate <= @EDate;

	/******************************************************************************
	Load Virgin ControlGroupIDs to iterate over
	******************************************************************************/

	IF OBJECT_ID('tempdb..#ControlGroupIDs_Virgin') IS NOT NULL DROP TABLE #ControlGroupIDs_Virgin;

	SELECT
		ControlGroupID
		, ROW_NUMBER() OVER (ORDER BY ControlGroupID) AS RowNum
	INTO #ControlGroupIDs_Virgin
	FROM (
		SELECT DISTINCT	controlgroupid
		FROM #Cycles_Virgin
	) x;

	/******************************************************************************
	Load iteration variables
	******************************************************************************/

	-- Declare outer loop variables

	DECLARE @RowNum_Virgin int;
	DECLARE @MaxRowNum_Virgin int;
	DECLARE @ControlGroupID_Virgin int;
	
	-- Declare inner loop variables

	DECLARE @RowNum_Virgin2 int;
	DECLARE @MaxRowNum_Virgin2 int;
	DECLARE @IronOfferCyclesID_Virgin int;
	DECLARE @NewCount_Virgin int;

	/******************************************************************************
	Outer loop: Iterate over ControlGroupIDs
	******************************************************************************/

	SET @RowNum_Virgin = 1;
	SET @MaxRowNum_Virgin = (SELECT COUNT(*) FROM #ControlGroupIDs_Virgin);

	WHILE @RowNum_Virgin < @MaxRowNum_Virgin

	BEGIN
		
		SET @ControlGroupID_Virgin = (SELECT ControlGroupID FROM #ControlGroupIDs_Virgin WHERE RowNum = @RowNum_Virgin);

		-- Load control FanIDs

		IF OBJECT_ID('tempdb..#ControlFanIDs_Virgin') IS NOT NULL DROP TABLE #ControlFanIDs_Virgin;

		SELECT 
			FanID
		INTO #ControlFanIDs_Virgin
		FROM [WH_Virgin].[Report].[ControlGroupMembers]
		WHERE
			controlgroupid = @ControlGroupID_Virgin;

		CREATE CLUSTERED INDEX CIX_ControlFanIDs_Virgin ON #ControlFanIDs_Virgin (FanID);

		-- Load IronOfferCyclesIDs associated with the ControlGroupID variable to iterate over in inner loop

		IF OBJECT_ID ('tempdb..#IronOfferCyclesIDs_Virgin') IS NOT NULL DROP TABLE #IronOfferCyclesIDs_Virgin;

		SELECT 
			@ControlGroupID_Virgin AS ControlGroupID
			, cyc.ironoffercyclesid AS IronOfferCyclesID
			, ROW_NUMBER () OVER (ORDER BY IronOfferCyclesID) AS RowNum
		INTO #IronOfferCyclesIDs_Virgin
		FROM #Cycles_Virgin cyc
		WHERE controlgroupid = @ControlGroupID_Virgin;

		/******************************************************************************
		Inner loop: Iterate over IronOfferCyclesIDs
		******************************************************************************/

		SET @RowNum_Virgin2 = 1;
		SET @MaxRowNum_Virgin2 = (SELECT COUNT(*) FROM #IronOfferCyclesIDs_Virgin);

		WHILE @RowNum_Virgin2 <= @MaxRowNum_Virgin2

		BEGIN

			SET @IronOfferCyclesID_Virgin = (SELECT IronOfferCyclesID FROM #IronOfferCyclesIDs_Virgin WHERE RowNum = @RowNum_Virgin2);

			-- Load exposed FanIDs

			IF OBJECT_ID('tempdb..#ExposedFanIDs_Virgin') IS NOT NULL DROP TABLE #ExposedFanIDs_Virgin;

			SELECT
				FanID
			INTO #ExposedFanIDs_Virgin
			FROM [WH_Virgin].[Report].[CampaignHistory]
			WHERE 
				ironoffercyclesid = @IronOfferCyclesID_Virgin;

			CREATE CLUSTERED INDEX CIX_ExposedFanIDs_Virgin ON #ExposedFanIDs_Virgin (FanID);

			-- Load Virgin members in the exposed and control group for the same Iron Offer

			IF OBJECT_ID('tempdb..#ExposedControlIntersection_Virgin_ToDelete') IS NOT NULL DROP TABLE #ExposedControlIntersection_Virgin_ToDelete;

			SELECT
				@IronOfferCyclesID_Virgin AS IronOfferCyclesID
				, @ControlGroupID_Virgin AS ControlGroupID
				, c.FanID
			INTO #ExposedControlIntersection_Virgin_ToDelete
			FROM #ControlFanIDs_Virgin c
			INNER JOIN #ExposedFanIDs_Virgin e
				ON c.fanid = e.fanid
			OPTION(RECOMPILE);

			CREATE CLUSTERED INDEX CIX_ExposedControlIntersection_Virgin_ToDelete ON #ExposedControlIntersection_Virgin_ToDelete (FanID);

			-- Delete intersection

			DELETE FROM [WH_Virgin].[Report].[ControlGroupMembers] 
			WHERE 
			controlgroupid = @ControlGroupID_Virgin
			AND FanID IN (SELECT FanID FROM #ExposedControlIntersection_Virgin_ToDelete);

			-- Update counts table

			SET @NewCount_Virgin = (
				SELECT COUNT(*) FROM [WH_Virgin].[Report].[ControlGroupMembers]
				WHERE ControlGroupID = @ControlGroupID_Virgin
			);

			UPDATE [WH_Virgin].[Report].[ControlGroupMember_Counts]
			SET NumberofFanIDs = @NewCount_Virgin
			WHERE ControlGroupID = @ControlGroupID_Virgin;

			-- Load new intersection results

			IF OBJECT_ID('tempdb..#ExposedControlIntersection_Virgin') IS NOT NULL DROP TABLE #ExposedControlIntersection_Virgin;

			SELECT
				@IronOfferCyclesID_Virgin AS IronOfferCyclesID
				, @ControlGroupID_Virgin AS ControlGroupID
				, 0 AS ControlExposedMembers -- 0 after above delete
			INTO #ExposedControlIntersection_Virgin;

			-- Load Virgin results

			IF OBJECT_ID('tempdb..#Results_Virgin') IS NOT NULL DROP TABLE #Results_Virgin;

			WITH ControlMembers AS (
				SELECT DISTINCT
					i.ControlGroupID
					, COUNT(*) AS ControlMembers
				FROM #ExposedControlIntersection_Virgin i
				INNER JOIN [WH_Virgin].[Report].[ControlGroupMembers] c
					ON i.controlgroupid = c.controlgroupid
				GROUP BY 
					i.ControlGroupID
			)
			, ExposedMembers AS (
				SELECT DISTINCT
					i.ironoffercyclesid
					, COUNT(*) AS ExposedMembers
				FROM #ExposedControlIntersection_Virgin i
				INNER JOIN [WH_Virgin].[Report].[CampaignHistory] h
					ON i.ironoffercyclesid = h.ironoffercyclesid
				GROUP BY 
					i.ironoffercyclesid
				)
			SELECT 
				o.IronOfferID
				, s.OfferTypeForReports
				, o.PartnerID
				, i.ControlGroupID
				, i.IronOfferCyclesID
				, c.ControlMembers
				, e.ExposedMembers
				, i.ControlExposedMembers
			INTO #Results_Virgin
			FROM #ExposedControlIntersection_Virgin i
			LEFT JOIN ControlMembers c
				ON i.controlgroupid = c.controlgroupid
			LEFT JOIN ExposedMembers e
				ON i.ironoffercyclesid = e.ironoffercyclesid
			LEFT JOIN [WH_Virgin].[Report].[IronOfferCycles] cyc
				ON i.ironoffercyclesid = cyc.ironoffercyclesid
			LEFT JOIN [WH_Virgin].[Derived].[IronOffer] o
				ON cyc.ironofferid = o.ironofferid
			LEFT JOIN Warehouse.Relational.IronOfferSegment s
				ON o.ironofferid = s.IronOfferID
			OPTION(RECOMPILE);

			-- Load results into Warehouse.Staging.ControlsBI_ControlSetup_ExposedIntersection table

			INSERT INTO Warehouse.Staging.ControlsBI_ControlSetup_ExposedIntersection (
				StartDate
				, PublisherType
				, IronOfferID
				, OfferTypeForReports
				, PartnerID
				, ControlGroupID
				, ControlGroupTypeID
				, IronOfferCyclesID
				, ControlMembers
				, ExposedMembers
				, ControlExposedMembers
				, ControlExposedMembersProportion
				, ReportDate
			)
			SELECT 
				@SDate AS StartDate
				, 'Virgin' AS PublisherType
				, r.IronOfferID
				, r.OfferTypeForReports
				, r.PartnerID
				, r.ControlGroupID
				, CASE WHEN sec.ControlGroupID IS NOT NULL OR sec2.PartnerID IS NOT NULL THEN 1 ELSE 0 END AS ControlGroupTypeID
				, r.IronOfferCyclesID
				, r.ControlMembers
				, r.ExposedMembers
				, r.ControlExposedMembers
				, ISNULL(CAST(r.ControlExposedMembers AS float)/NULLIF(r.ExposedMembers, 0), 0) AS ControlExposedMembersProportion
				, CAST(GETDATE() AS date) AS ReportDate
			FROM #Results_Virgin r
			LEFT JOIN (SELECT DISTINCT ControlGroupID FROM nFI.Relational.SecondaryControlGroups WHERE 1 = 2) sec	--	RF To reveiw March 2021
				ON r.ControlGroupID = sec.ControlGroupID
			LEFT JOIN (
					SELECT r.RetailerID AS PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
					UNION 
					SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
					INNER JOIN Warehouse.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
					UNION
					SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
					INNER JOIN nFI.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
			) sec2
				ON r.PartnerID = sec2.PartnerID;

			SET @RowNum_Virgin2 = @RowNum_Virgin2 + 1;

		END -- End inner loop (on IronOfferCyclesIDs)

		SET @RowNum_Virgin = @RowNum_Virgin + 1;

	END -- End outer loop (on ControlGroupIDs)

END