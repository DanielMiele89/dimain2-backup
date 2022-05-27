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
CREATE PROCEDURE [Report].[ControlSetup_Load_ExposedIntersection]
	
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
		2.	Load OfferReportingPeriods
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#OfferReportingPeriods') IS NOT NULL DROP TABLE #OfferReportingPeriods;
		SELECT	OfferReportingPeriodsID = CONVERT(INT, orp.OfferReportingPeriodsID)
			,	ControlGroupID = orp.ControlGroupID_OutOfProgramme
			,	StartDate = orp.StartDate
			,	EndDate = orp.EndDate
			,	RowNum = ROW_NUMBER() OVER (ORDER BY orp.OfferReportingPeriodsID, orp.ControlGroupID_OutOfProgramme, orp.StartDate)
		INTO #OfferReportingPeriods	
		FROM [Report].[OfferReport_OfferReportingPeriods] orp
		WHERE orp.EndDate >= @StartDate
		AND orp.StartDate <= @EndDate
		AND orp.ControlGroupID_OutOfProgramme IS NOT NULL
		
		INSERT INTO #OfferReportingPeriods
		SELECT	OfferReportingPeriodsID = orp.OfferReportingPeriodsID
			,	ControlGroupID = orp.ControlGroupID_InProgramme
			,	StartDate = orp.StartDate
			,	EndDate = orp.EndDate
			,	RowNum = ROW_NUMBER() OVER (ORDER BY orp.OfferReportingPeriodsID, orp.ControlGroupID_OutOfProgramme, orp.StartDate) + COALESCE(@@ROWCOUNT, 0)
		FROM [Report].[OfferReport_OfferReportingPeriods] orp
		WHERE orp.EndDate >= @StartDate
		AND orp.StartDate <= @EndDate
		AND orp.ControlGroupID_InProgramme IS NOT NULL;
		

	/*******************************************************************************************************************************************
		3.	Load ControlGroupIDs to iterate over
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ControlGroupIDs') IS NOT NULL DROP TABLE #ControlGroupIDs;
		SELECT	ControlGroupID
			,	ROW_NUMBER() OVER (ORDER BY ControlGroupID) AS RowNum
		INTO #ControlGroupIDs
		FROM (	SELECT	DISTINCT
						ControlGroupID
				FROM #OfferReportingPeriods) x;
		

	/*******************************************************************************************************************************************
		4.	Loop through each ControlGroupID & it's OfferReportingPeriodsID's, removing customers from [Report].[OfferReport_ControlGroupMembers]
			if they are also in [Report].[OfferReport_ExposedMembers]
	*******************************************************************************************************************************************/
	
			TRUNCATE TABLE [Report].[ControlSetup_ExposedIntersection];

		/***************************************************************************************************************************************
			4.1.	Load iteration variables
		***************************************************************************************************************************************/

			-- Declare outer loop variables

			DECLARE @RowNum_Control int;
			DECLARE @MaxRowNum_Control int;
			DECLARE @ControlGroupID int;
			DECLARE @ControlGroupMembers int;
			DECLARE @ControlGroupMembersRemoved int;
	
			-- Declare inner loop variables

			DECLARE @RowNum_Control_Exposed int;
			DECLARE @MaxRowNum_Control_Exposed int;
			DECLARE @OfferReportingPeriodsID int;
			DECLARE @ExposedMembers int;
			DECLARE @NewCount int;

		/***************************************************************************************************************************************
			4.2.	Outer loop: Iterate over ControlGroupIDs
		***************************************************************************************************************************************/

			SELECT	@RowNum_Control = 1
				,	@MaxRowNum_Control = COUNT(*)
			FROM #ControlGroupIDs;

			WHILE @RowNum_Control < @MaxRowNum_Control
				BEGIN
		
					SET @ControlGroupMembers = 0
					SET @ControlGroupMembersRemoved = 0
					SET @ExposedMembers = 0

					SELECT @ControlGroupID = ControlGroupID
					FROM #ControlGroupIDs
					WHERE RowNum = @RowNum_Control;

					-- Load control FanIDs

					IF OBJECT_ID('tempdb..#ControlFanIDs') IS NOT NULL DROP TABLE #ControlFanIDs;
					SELECT	FanID
					INTO #ControlFanIDs
					FROM [Report].[OfferReport_ControlGroupMembers]
					WHERE ControlGroupID = @ControlGroupID;

					SET @ControlGroupMembers = COALESCE(@@ROWCOUNT, 0)

					CREATE CLUSTERED INDEX CIX_ControlFanIDs ON #ControlFanIDs (FanID);

					-- Load OfferReportingPeriodsIDs associated with the ControlGroupID variable to iterate over in inner loop

					IF OBJECT_ID ('tempdb..#OfferReportingPeriodsIDs') IS NOT NULL DROP TABLE #OfferReportingPeriodsIDs;
					SELECT	@ControlGroupID AS ControlGroupID
						,	cyc.OfferReportingPeriodsID AS OfferReportingPeriodsID
						,	ROW_NUMBER () OVER (ORDER BY OfferReportingPeriodsID) AS RowNum
					INTO #OfferReportingPeriodsIDs
					FROM #OfferReportingPeriods cyc
					WHERE ControlGroupID = @ControlGroupID;

				/***************************************************************************************************************************************
					4.3.	Inner loop: Iterate over OfferReportingPeriodsIDs
				***************************************************************************************************************************************/

					SELECT	@RowNum_Control_Exposed = 1
						,	@MaxRowNum_Control_Exposed = COUNT(*)
					FROM #OfferReportingPeriodsIDs;

					WHILE @RowNum_Control_Exposed <= @MaxRowNum_Control_Exposed
						BEGIN

							SELECT @OfferReportingPeriodsID = OfferReportingPeriodsID
							FROM #OfferReportingPeriodsIDs
							WHERE RowNum = @RowNum_Control_Exposed;

							-- Load exposed FanIDs

							IF OBJECT_ID('tempdb..#ExposedFanIDs') IS NOT NULL DROP TABLE #ExposedFanIDs;
							SELECT	FanID
							INTO #ExposedFanIDs
							FROM [Report].[OfferReport_ExposedMembers]
							WHERE OfferReportingPeriodsID = @OfferReportingPeriodsID;
							
							SET @ExposedMembers = COALESCE(@@ROWCOUNT, 0)

							CREATE CLUSTERED INDEX CIX_ExposedFanIDs ON #ExposedFanIDs (FanID);

							-- Load Warehouse members in the exposed and control group for the same Iron Offer

							IF OBJECT_ID('tempdb..#ExposedControlIntersection_ToDelete') IS NOT NULL DROP TABLE #ExposedControlIntersection_ToDelete;
							SELECT	OfferReportingPeriodsID = @OfferReportingPeriodsID
								,	ControlGroupID = @ControlGroupID
								,	FanID = c.FanID
							INTO #ExposedControlIntersection_ToDelete
							FROM #ControlFanIDs c
							WHERE EXISTS (	SELECT 1
											FROM #ExposedFanIDs e
											WHERE c.FanID = e.FanID)
							OPTION(RECOMPILE);

							CREATE CLUSTERED INDEX CIX_ExposedControlIntersection_ToDelete ON #ExposedControlIntersection_ToDelete (FanID);

							-- Delete intersection

							DELETE cgm
							FROM [Report].[OfferReport_ControlGroupMembers] cgm
							WHERE ControlGroupID = @ControlGroupID
							AND EXISTS (	SELECT 1
											FROM #ExposedControlIntersection_ToDelete e
											WHERE cgm.FanID = e.FanID);

							SET @ControlGroupMembersRemoved = COALESCE(@@ROWCOUNT, 0)

							-- Update counts table
							
							UPDATE [Report].[OfferReport_ControlGroupMembers_Counts]
							SET Customers = Customers - @ControlGroupMembersRemoved
							,	ModifiedDate = GETDATE()
							WHERE ControlGroupID = @ControlGroupID
							AND @ControlGroupMembersRemoved > 0;

							-- Load new intersection results

							IF OBJECT_ID('tempdb..#ExposedControlIntersection') IS NOT NULL DROP TABLE #ExposedControlIntersection;
							SELECT	@OfferReportingPeriodsID AS OfferReportingPeriodsID
								,	@ControlGroupID AS ControlGroupID
								,	0 AS ControlExposedMembers -- 0 after above delete
							INTO #ExposedControlIntersection;

							-- Load Warehouse results

							IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;
							SELECT	OfferID = o.OfferID
								,	IronOfferID = o.IronOfferID
								,	OfferTypeForReports = s.OfferTypeForReports
								,	PartnerID = o.PartnerID
								,	ControlGroupID = i.ControlGroupID
								,	OfferReportingPeriodsID = i.OfferReportingPeriodsID
								,	ControlMembers = @ControlGroupMembers - @ControlGroupMembersRemoved
								,	ExposedMembers = @ExposedMembers
								,	ControlExposedMembersRemoved = @ControlGroupMembersRemoved
								,	ControlExposedMembers = i.ControlExposedMembers
							INTO #Results
							FROM #ExposedControlIntersection i
							LEFT JOIN [Report].[OfferReport_OfferReportingPeriods] orp
								ON i.OfferReportingPeriodsID = orp.OfferReportingPeriodsID
							LEFT JOIN [Derived].[Offer] o
								ON orp.OfferID = o.OfferID
							LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] s
								ON o.IronOfferID = s.IronOfferID
							OPTION(RECOMPILE);

							-- Load results into [Report].[ControlSetup_ExposedIntersection] table
				
							INSERT INTO [Report].[ControlSetup_ExposedIntersection] (	StartDate
																					,	PublisherType
																					,	OfferID
																					,	IronOfferID
																					,	OfferTypeForReports
																					,	PartnerID
																					,	ControlGroupID
																					,	ControlGroupTypeID
																					,	OfferReportingPeriodsID
																					,	ControlMembers
																					,	ExposedMembers
																					,	ControlExposedMembersRemoved
																					,	ControlExposedMembers
																					,	ControlExposedMembersProportion
																					,	ReportDate)
							SELECT	StartDate = @StartDate
								,	PublisherType = 'All'
								,	OfferID = r.OfferID
								,	IronOfferID = r.IronOfferID
								,	OfferTypeForReports = r.OfferTypeForReports
								,	PartnerID = r.PartnerID
								,	ControlGroupID = r.ControlGroupID
								,	ControlGroupTypeID = 0
								,	OfferReportingPeriodsID = r.OfferReportingPeriodsID
								,	ControlMembers = r.ControlMembers
								,	ExposedMembers = r.ExposedMembers
								,	ControlExposedMembersRemoved = r.ControlExposedMembersRemoved
								,	ControlExposedMembers = r.ControlExposedMembers
								,	ControlExposedMembersProportion = ISNULL(CAST(r.ControlExposedMembers AS float)/NULLIF(r.ExposedMembers, 0), 0)
								,	ReportDate = CAST(GETDATE() AS date)
							FROM #Results r;

							SET @RowNum_Control_Exposed = @RowNum_Control_Exposed + 1;

						END	--	@RowNum_Control_Exposed <= @MaxRowNum_Control_Exposed	--	End inner loop (on OfferReportingPeriodsIDs)

					SET @RowNum_Control = @RowNum_Control + 1;

				END	--	@RowNum_Control < @MaxRowNum_Control	--	End outer loop (on ControlGroupIDs)

END