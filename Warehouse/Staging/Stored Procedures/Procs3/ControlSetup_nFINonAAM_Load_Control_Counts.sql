/******************************************************************************
Author: Jason Shipp
Created: 12/03/2018
Purpose:
	- Load new nFI Control Group member counts into nFI.Relational.ControlGroupMember_Counts table
	- Output validation of the new Control Group member counts

------------------------------------------------------------------------------
Modification History

Jason Shipp 16/05/2018
	- Added fix to stop control group members counts being duplicated for control groups running in two different periods in the cycle

Jason Shipp 22/04/2020
	- Added validation of control group member counts

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_nFINonAAM_Load_Control_Counts]
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Declare variables
	******************************************************************************/

	Declare @UN_ID int;
	Declare @SDate date;
	
	Set @UN_ID = (select UniversalControlGroupID from Warehouse.Staging.ControlSetup_UniversalOffer_nFI);
	Set @SDate = (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates);
	/******************************************************************************
	Load new Control Group member counts into nFI.Relational.ControlGroupMember_Counts table
	******************************************************************************/

	-- Non-Universal

	IF OBJECT_ID('tempdb..#PartnerControlGroupIDs') IS NOT NULL DROP TABLE #PartnerControlGroupIDs
	SELECT	pcg.PartnerID
		,	CASE
				WHEN pcg.Segment = 'A' THEN 7
				WHEN pcg.Segment = 'L' THEN 8
				WHEN pcg.Segment = 'S' THEN 9
				WHEN pcg.Segment = 'SR' THEN 10
				WHEN pcg.Segment = 'SG' THEN 11
				ELSE 0
			END AS SuperSegmentID
		,	ioc.ControlGroupID
		,	MIN(CONVERT(DATE, pcg.StartDate)) AS StartDate
	INTO #PartnerControlGroupIDs
	FROM [Warehouse].[Staging].[PartnerControlgroupIDs] pcg
	INNER JOIN [Warehouse].[Staging].[ControlSetup_OffersSegment_nFI] os
		ON pcg.PartnerID = os.PartnerID
		AND pcg.Segment = os.Segment
	INNER JOIN [nFI].[Relational].[OfferCycles] oc
		ON pcg.StartDate = oc.StartDate
		AND pcg.EndDate = CONVERT(DATE, oc.EndDate)
	INNER JOIN [nFI].[Relational].[ironoffercycles] ioc
		ON os.ironofferid = ioc.ironofferid
		AND oc.OfferCyclesID = ioc.offercyclesid
	GROUP BY	pcg.PartnerID
			,	CASE
					WHEN pcg.Segment = 'A' THEN 7
					WHEN pcg.Segment = 'L' THEN 8
					WHEN pcg.Segment = 'S' THEN 9
					WHEN pcg.Segment = 'SR' THEN 10
					WHEN pcg.Segment = 'SG' THEN 11
					ELSE 0
				END
			,	ioc.ControlGroupID

	CREATE CLUSTERED INDEX CIX_ControlGroupID ON #PartnerControlGroupIDs (ControlGroupID)

	DELETE pcg
	FROM #PartnerControlGroupIDs pcg
	WHERE EXISTS (	SELECT 1
					FROM [nFI].[Relational].[ControlGroupMember_Counts] cgm
					WHERE pcg.ControlGroupID = cgm.ControlGroupID
					AND pcg.StartDate = cgm.StartDate)

	DELETE pcg
	FROM #PartnerControlGroupIDs pcg
	WHERE NOT EXISTS (	SELECT 1
						FROM [nFI].[Relational].[ironoffercycles] ioc
						WHERE pcg.ControlGroupID = ioc.ControlGroupID)


	IF OBJECT_ID('tempdb..#ControlGroupMembers') IS NOT NULL DROP TABLE #ControlGroupMembers
	SELECT	cgm.ControlGroupID
		,	COUNT(cgm.FanID) AS NumberOfFanIDs
	INTO #ControlGroupMembers
	FROM [nFI].[Relational].[controlgroupmembers] cgm
	WHERE EXISTS (	SELECT 1
					FROM #PartnerControlGroupIDs pcg
					WHERE cgm.controlgroupid = pcg.ControlGroupID)
	GROUP BY	cgm.ControlGroupID

	CREATE CLUSTERED INDEX CIX_ControlGroupID ON #ControlGroupMembers (ControlGroupID)
	
	;With
	CountsByDateAgg AS (SELECT	pcg.PartnerID
							,	pcg.SuperSegmentID
							,	pcg.ControlGroupID
							,	MIN(pcg.StartDate) as StartDate
							,	MAX(cgm.NumberOfFanIDs) as NumberOfFanIDs
						FROM #PartnerControlGroupIDs pcg
						INNER JOIN #ControlGroupMembers cgm
							ON pcg.ControlGroupID = cgm.ControlGroupID
						GROUP BY	pcg.PartnerID
								,	pcg.SuperSegmentID
								,	pcg.ControlGroupID)

	INSERT INTO [nFI].[Relational].[ControlGroupMember_Counts] (PartnerID, SuperSegmentID, ControlGroupID, StartDate, NumberofFanIDs)
	SELECT	cbd.PartnerID
		,	cbd.SuperSegmentID
		,	cbd.ControlGroupID
		,	cbd.StartDate
		,	cbd.NumberofFanIDs
	FROM CountsByDateAgg cbd
	OPTION (FORCE ORDER);

	-- Universal

	Set @UN_ID = (select UniversalControlGroupID from Warehouse.Staging.ControlSetup_UniversalOffer_nFI);
	Set @SDate = (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates);
	
	INSERT INTO [nFI].[Relational].[ControlGroupMember_Counts] (PartnerID, SuperSegmentID, ControlGroupID, StartDate, NumberofFanIDs)
	SELECT	cgm.PartnerID
		,	cgm.SuperSegmentID
		,	cgm.ControlGroupID
		,	cgm.StartDate
		,	cgm.NumberofFanIDs
	FROM (	SELECT	0 AS PartnerID
				,	0 AS SUperSegmentID
				,	@UN_ID AS ControlGroupID
				,	@SDate AS StartDate
				,	COUNT(*) AS NumberofFanIDs 
			FROM [nFI].[Relational].[controlgroupmembers] cgm
			WHERE ControlGroupID = @UN_ID) cgm
	WHERE NOT EXISTS (	SELECT 1
						FROM [nFI].[Relational].[ControlGroupMember_Counts] cgm
						WHERE cgm.ControlGroupID = cgm.ControlGroupID
						AND cgm.StartDate = cgm.StartDate)
	AND EXISTS (	SELECT 1
					FROM [nFI].[Relational].[ironoffercycles] ioc
					WHERE cgm.ControlGroupID = ioc.ControlGroupID)
	OPTION (FORCE ORDER);

	/******************************************************************************
	CHECK POINT: Check control group member counts

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Control_Counts
		(PublisherType VARCHAR(50)
		, PartnerID INT
		, SuperSegmentID TINYINT
		, SegmentName VARCHAR(50)
		, ControlGroupID INT
		, StartDate DATE
		, NumberofFanIDs INT
		, CONSTRAINT PK_ControlSetup_Validation_nFINonAAM_Control_Counts PRIMARY KEY CLUSTERED (PartnerID, ControlGroupID, StartDate)  
		)
	******************************************************************************/

	TRUNCATE TABLE Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Control_Counts;

	INSERT INTO Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Control_Counts
		(PublisherType
		, PartnerID
		, SuperSegmentID
		, SegmentName
		, ControlGroupID
		, StartDate
		, NumberofFanIDs
		)
	Select
		'nFI' as PublisherType
		, mc.PartnerID
		, mc.SuperSegmentID
		, Case when mc.SuperSegmentID = 0 then 'Universal' else t.SegmentName end AS SegmentName
		, mc.ControlGroupID
		, mc.StartDate
		, mc.NumberofFanIDs
	From nFI.Relational.ControlGroupMember_Counts mc
	Left Join nFI.Segmentation.ROC_Shopper_Segment_Types t
		ON mc.SuperSegmentID = t.ID
	Where 
		mc.StartDate >= @SDate -- Campaign Cycle start date
		And (
			mc.NumberofFanIDs IS NULL
			Or 
			mc.NumberofFanIDs > 975000
			Or
			(mc.SuperSegmentID = 0 and mc.NumberofFanIDs < 100000) -- Check universal member counts
			Or
			( -- Check Acquire non in programme member counts
				(mc.PartnerID Not in (Select RetailerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers Union all Select 4265)) 
				and mc.SuperSegmentID = 7
				and mc.NumberofFanIDs < 300000
			)
			Or
			( -- Check Acquire in programme member counts
				(mc.PartnerID in (Select RetailerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers Union all Select 4265)) 
				and mc.SuperSegmentID = 7
				and mc.NumberofFanIDs < 1000
			)
			OR ( -- Check Lapsed and Shopper member counts
				mc.SuperSegmentID in (8, 9)
				and mc.NumberofFanIDs < 100
				AND mc.PartnerID NOT IN (4812, 4820, 4906,4914 )	--	Exclude retailers with counts too low to form control group (Church's)
			)
		);

END