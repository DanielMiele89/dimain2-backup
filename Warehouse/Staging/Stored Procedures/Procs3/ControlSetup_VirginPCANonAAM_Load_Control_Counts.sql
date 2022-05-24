
/******************************************************************************
Author: Jason Shipp
Created: 12/03/2018
Purpose:
	- Load new nFI Control Group member counts INTO [WH_VirginPCA].[Report].[ControlGroupMember_Counts] table
	- Output validation of the new Control Group member counts

------------------------------------------------------------------------------
Modification History

Jason Shipp 16/05/2018
	- Added fix to stop control group members counts being duplicated for control groups running in two different periods in the cycle

Jason Shipp 22/04/2020
	- Added validation of control group member counts

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_VirginPCANonAAM_Load_Control_Counts]
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	DECLARE variables
	******************************************************************************/

		DECLARE @UN_ID INT;
		DECLARE @SDate DATE;
	
		SET @UN_ID = (SELECT UniversalControlGroupID FROM [Warehouse].[Staging].[ControlSetup_UniversalOffer_VirginPCA]);
		SET @SDate = (SELECT StartDate FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates]);

	/******************************************************************************
	Load new Control Group member counts INTO [WH_VirginPCA].[Report].[ControlGroupMember_Counts] table
	******************************************************************************/

	-- Non-Universal

	WITH
	CountsByDate AS (	SELECT	pcg.PartnerID
							,	CASE
									WHEN pcg.Segment = 'A' THEN 7
									WHEN pcg.Segment = 'L' THEN 8
									WHEN pcg.Segment = 'S' THEN 9
									WHEN pcg.Segment = 'SR' THEN 10
									WHEN pcg.Segment = 'SG' THEN 11
									ELSE 0
								END AS SuperSegmentID
							,	ioc.ControlGroupID
							,	CONVERT(DATE, pcg.StartDate) AS StartDate
							,	CONVERT(DATE, pcg.EndDate) AS EndDate
							,	COUNT(DISTINCT cgm.FanID) AS NumberofFanIDs
						FROM [WH_VirginPCA].[Report].[PartnerControlGroupIDs] pcg
						INNER JOIN [Warehouse].[Staging].[ControlSetup_OffersSegment_VirginPCA] os
							ON pcg.PartnerID = os.PartnerID
							AND pcg.Segment = os.Segment
						INNER JOIN [WH_VirginPCA].[Report].[OfferCycles] oc
							ON pcg.StartDate = oc.StartDate
							AND pcg.EndDate = CONVERT(DATE, oc.EndDate)
						INNER JOIN [WH_VirginPCA].[Report].[ironoffercycles] ioc
							ON os.ironofferid = ioc.ironofferid
							AND oc.OfferCyclesID = ioc.offercyclesid
						INNER JOIN [WH_VirginPCA].[Report].[ControlGroupMembers] AS cgm
							ON ioc.ControlGroupID = cgm.ControlGroupID
						GROUP BY	pcg.PartnerID
								,	ioc.ControlGroupID
								,	CONVERT(DATE, pcg.StartDate)
								,	CONVERT(DATE, pcg.EndDate)
								,	CASE
										WHEN pcg.Segment = 'A' THEN 7
										WHEN pcg.Segment = 'L' THEN 8
										WHEN pcg.Segment = 'S' THEN 9
										WHEN pcg.Segment = 'SR' THEN 10
										WHEN pcg.Segment = 'SG' THEN 11
										ELSE 0
									END),
									
	CountsByDateAgg AS (SELECT	c.PartnerID
							,	c.SuperSegmentID
							,	c.ControlGroupID
							,	MIN(c.StartDate) AS StartDate
							,	MAX(c.NumberofFanIDs) AS NumberofFanIDs
						FROM CountsByDate c
						GROUP BY	c.PartnerID
								,	c.SuperSegmentID
								,	c.ControlGroupID)

	INSERT INTO [WH_VirginPCA].[Report].[ControlGroupMember_Counts] (PartnerID, SuperSegmentID, ControlGroupID, StartDate, NumberofFanIDs)
	SELECT	cbd.PartnerID
		,	cbd.SuperSegmentID
		,	cbd.ControlGroupID
		,	cbd.StartDate
		,	cbd.NumberofFanIDs
	FROM CountsByDateAgg cbd
	WHERE NOT EXISTS (	SELECT 1
						FROM [WH_VirginPCA].[Report].[ControlGroupMember_Counts] cgmc
						WHERE cbd.ControlGroupID = cgmc.ControlGroupID
						AND cbd.StartDate = cgmc.StartDate)	
	AND EXISTS (	SELECT 1
					FROM [WH_VirginPCA].[Report].[IronOfferCycles] ioc
					WHERE cbd.ControlGroupID = ioc.ControlGroupID)
	OPTION (FORCE ORDER);

	-- Universal

	SET @UN_ID = (SELECT UniversalControlGroupID FROM [Warehouse].[Staging].[ControlSetup_UniversalOffer_VirginPCA]);
	SET @SDate = (SELECT StartDate FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates]);

	INSERT INTO [WH_VirginPCA].[Report].[ControlGroupMember_Counts] (PartnerID, SuperSegmentID, ControlGroupID, StartDate, NumberofFanIDs)
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
			FROM [WH_VirginPCA].[Report].[ControlGroupMembers] cgm
			WHERE ControlGroupID = @UN_ID) cgm
	WHERE NOT EXISTS (	SELECT 1
						FROM [WH_VirginPCA].[Report].[ControlGroupMember_Counts] d
						WHERE cgm.ControlGroupID = d.ControlGroupID
						AND cgm.StartDate = d.StartDate)
	AND EXISTS (SELECT 1
				FROM [WH_VirginPCA].[Report].[IronOfferCycles] ioc
				WHERE cgm.ControlGroupID = ioc.ControlGroupID)
	OPTION (FORCE ORDER);

	/******************************************************************************
	CHECK POINT: Check control group member counts

	CREATE TABLE for storing validation results

	CREATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Control_Counts] (	PublisherType VARCHAR(50)
																							,	PartnerID INT
																							,	SuperSegmentID TINYINT
																							,	SegmentName VARCHAR(50)
																							,	ControlGroupID INT
																							,	StartDate DATE
																							,	NumberofFanIDs INT
																							,	CONSTRAINT PK_ControlSetup_Validation_VirginPCANonAAM_Control_Counts PRIMARY KEY CLUSTERED (PartnerID, ControlGroupID, StartDate))

	******************************************************************************/

	TRUNCATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Control_Counts];

	INSERT INTO [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Control_Counts] (	PublisherType
																							,	PartnerID
																							,	SuperSegmentID
																							,	SegmentName
																							,	ControlGroupID
																							,	StartDate
																							,	NumberofFanIDs)
	SELECT	'VirginPCA' AS PublisherType
		,	mc.PartnerID
		,	mc.SuperSegmentID
		,	Case when mc.SuperSegmentID = 0 then 'Universal' else t.SegmentName end AS SegmentName
		,	mc.ControlGroupID
		,	mc.StartDate
		,	mc.NumberofFanIDs
	FROM [WH_VirginPCA].[Report].[ControlGroupMember_Counts] mc
	LEFT JOIN [nFI].[Segmentation].[ROC_Shopper_Segment_Types] t
		ON mc.SuperSegmentID = t.ID
	WHERE mc.StartDate >= @SDate -- Campaign Cycle start date
	AND (
			mc.NumberofFanIDs IS NULL
			Or 
			mc.NumberofFanIDs > 975000
			Or
			(mc.SuperSegmentID = 0 AND mc.NumberofFanIDs < 100000) -- Check universal member counts
			Or
			( -- Check Acquire non in programme member counts
				(mc.PartnerID Not in (SELECT RetailerID FROM [Warehouse].[Staging].[ControlSetup_BespokeControlGroupRetailers] UNION ALL SELECT 4265)) 
				AND mc.SuperSegmentID = 7
				AND mc.NumberofFanIDs < 300000
			)
			Or
			( -- Check Acquire in programme member counts
				(mc.PartnerID in (SELECT RetailerID FROM [Warehouse].[Staging].[ControlSetup_BespokeControlGroupRetailers] UNION ALL SELECT 4265)) 
				AND mc.SuperSegmentID = 7
				AND mc.NumberofFanIDs < 1000
			)
			OR ( -- Check Lapsed AND Shopper member counts
				mc.SuperSegmentID in (8, 9)
				AND mc.NumberofFanIDs < 100
				AND mc.PartnerID NOT IN (4812, 4728, 4862, 4263, 4916, 4906, 4914)	--	Exclude retailers with counts too low to form control group (Church's)
			)
		);

END

/*

SELECT *
FROM Warehouse.Staging.ControlSetup_Validation_VirginPCANonAAM_Control_Counts c
INNER JOIN SLC_REPL..Partner p
	ON c.PArtnerID = p.ID

*/