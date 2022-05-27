/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Assign nFI partner ControlGroupIDs
	- Add entries to nFI.Relational.ironoffercycles table
	- Load validation of entries added to nFI.Relational.ironoffercycles

Note: 
	- The Universal ControlGroupID will be the minimum ControlGroupID associated with the OfferCyclesIDs being setup
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 11/07/2018
	- Added logic to update ControlGroupIDs for cases where a ControlGroupID already exists for that retailer segment in that cycle
******************************************************************************/
CREATE PROCEDURE [Report].[ControlSetup_Load_ControlGroups]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/*******************************************************************************************************************************************
		1.	Load Campaign Cycle dates
	*******************************************************************************************************************************************/

		DECLARE @StartDate DATETIME
			,	@EndDate DATETIME
		
		SELECT	@StartDate = StartDate
			,	@EndDate = EndDate
		FROM [Report].[ControlSetup_CycleDates]

		--	SELECT @StartDate, @EndDate


	/*******************************************************************************************************************************************
		2.	Create new ControlGroupIDs for Out of Programme
	*******************************************************************************************************************************************/
				
		INSERT INTO [Report].[ControlSetup_ControlGroupIDs] (	RetailerID
															,	SegmentID
															,	IsUniversal
															,	IsInPromgrammeControlGroup
															,	PublisherID
															,	OfferID
															,	StartDate
															,	EndDate
															,	IsSegmented)
		SELECT	DISTINCT
				RetailerID = os.RetailerID
			,	SegmentID = os.SegmentID
			,	IsUniversal =	CASE
									WHEN os.SegmentID = 0 THEN 1
									ELSE 0
								END
			,	IsInPromgrammeControlGroup = 0
			,	PublisherID = NULL
			,	OfferID = NULL
			,	StartDate = @StartDate
			,	EndDate = @EndDate
			,	IsSegmented = 0
		FROM [Report].[ControlSetup_OffersSegment] os
		WHERE NOT EXISTS (	SELECT 1
							FROM [WH_AllPublishers].[Report].[ControlSetup_ControlGroupIDs] cg
							WHERE cg.RetailerID = os.RetailerID
							AND cg.SegmentID = os.SegmentID
							AND cg.IsInPromgrammeControlGroup = 0
							AND cg.StartDate BETWEEN @StartDate AND @EndDate)
		AND os.SegmentID != 0
		ORDER BY	os.RetailerID
				,	os.SegmentID


	/*******************************************************************************************************************************************
		3.	Create new ControlGroupIDs for In Programme
	*******************************************************************************************************************************************/
				
		INSERT INTO [Report].[ControlSetup_ControlGroupIDs] (	RetailerID
															,	SegmentID
															,	IsUniversal
															,	IsInPromgrammeControlGroup
															,	PublisherID
															,	OfferID
															,	StartDate
															,	EndDate
															,	IsSegmented)
		SELECT	DISTINCT
				RetailerID = os.RetailerID
			,	SegmentID = os.SegmentID
			,	IsUniversal =	CASE
									WHEN os.SegmentID = 0 THEN 1
									ELSE 0
								END
			,	IsInPromgrammeControlGroup = 1
			,	PublisherID = os.PublisherID
			,	OfferID = os.OfferID
			,	StartDate = @StartDate
			,	EndDate = @EndDate
			,	IsSegmented = 0
		FROM [Report].[ControlSetup_OffersSegment] os
		INNER JOIN [Selections].[ControlGroupMembers_InProgram] cgm
			ON os.IronOfferID = cgm.IronOfferID
		WHERE NOT EXISTS (	SELECT 1
							FROM [WH_AllPublishers].[Report].[ControlSetup_ControlGroupIDs] cg
							WHERE cg.RetailerID = os.RetailerID
							AND cg.SegmentID = os.SegmentID
							AND cg.IsInPromgrammeControlGroup = 1
							AND cg.StartDate BETWEEN @StartDate AND @EndDate)
		AND (@StartDate BETWEEN os.StartDate AND os.EndDate
		OR @EndDate BETWEEN os.StartDate AND os.EndDate)

						
END