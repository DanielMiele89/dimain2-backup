/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Load nFI PartnerIDs to run segmentations for
	- Load validation of retailer offers to be segmented
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 10/04/2019
	-- Added partner settings for MFDD partners
		
******************************************************************************/

CREATE PROCEDURE [Report].[ControlSetup_Load_ControlMembers_InProgram]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/*******************************************************************************************************************************************
		1.	Create table of segmentation calls
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ToSegment') IS NOT NULL DROP TABLE #ToSegment;
		SELECT	cg.RetailerID
			,	cg.StartDate
			,	cg.EndDate
			,	cg.PublisherID
			,	cg.OfferID
			,	o.IronOfferID
			,	cg.ControlGroupID
		INTO #ToSegment
		FROM [Report].[ControlSetup_ControlGroupIDs] cg
		INNER JOIN [Derived].[Offer] o
			ON cg.OfferID = o.OfferID
		WHERE IsSegmented = 0
		AND IsInPromgrammeControlGroup = 1;

		CREATE CLUSTERED INDEX CIX_CINID ON #ToSegment (PublisherID, IronOfferID, StartDate, EndDate, ControlGroupID);


	/*******************************************************************************************************************************************
		2.	Execute segmentation calls to segment customers & load them to Sandbox tables & ControlGroupMembers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ControlGroupMembers') IS NOT NULL DROP TABLE #ControlGroupMembers;
		SELECT	DISTINCT
				ts.ControlGroupID
			,	cg.FanID
		INTO #ControlGroupMembers
		FROM #ToSegment ts
		INNER JOIN [Selections].[ControlGroupMembers_InProgram] cg
			ON ts.PublisherID = cg.PublisherID
			AND ts.IronOfferID = cg.IronOfferID
			AND ts.EndDate <= cg.EndDate
			AND cg.StartDate <= ts.StartDate
		WHERE cg.ExcludeFromAnalysis = 0;

		CREATE CLUSTERED INDEX CIX_CINID ON #ControlGroupMembers (ControlGroupID, FanID);


	/*******************************************************************************************************************************************
		3.	Load through ControlGroupIDs adding the members
	*******************************************************************************************************************************************/


		DECLARE	@ControlGroupID INT
			,	@ControlGroupIDMax INT
			,	@SegmentID INT
				
		SELECT	@ControlGroupID = MIN(ControlGroupID)
			,	@ControlGroupIDMax = MAX(ControlGroupID)
		FROM #ToSegment

		WHILE @ControlGroupID <= @ControlGroupIDMax
			BEGIN

				IF EXISTS (SELECT 1 FROM [Report].[OfferReport_ControlGroupMembers] cgm WHERE cgm.ControlGroupID = @ControlGroupID)
					BEGIN
						DELETE cgm
						FROM [Report].[OfferReport_ControlGroupMembers] cgm
						WHERE cgm.ControlGroupID = @ControlGroupID
					END

				INSERT INTO [Report].[OfferReport_ControlGroupMembers]
				SELECT	TOP (950000)
						@ControlGroupID
					,	FanID
				FROM #ControlGroupMembers
				WHERE ControlGroupID = @ControlGroupID

				;WITH
				OfferReport_ControlGroupMembers_Counts AS (SELECT	cg.RetailerID
																,	cg.SegmentID
																,	cg.ControlGroupID
																,	cg.StartDate
																,	cg.EndDate
																,	@@ROWCOUNT AS Customers
																,	GETDATE() AS AddedDate
																,	GETDATE() AS ModifiedDate
															FROM #ToSegment tsl
															INNER JOIN [Report].[ControlSetup_ControlGroupIDs] cg
																ON tsl.RetailerID = cg.RetailerID
																AND tsl.StartDate = cg.StartDate
																AND tsl.EndDate = cg.EndDate
																AND tsl.ControlGroupID = cg.ControlGroupID
															WHERE cg.ControlGroupID = @ControlGroupID
															AND cg.IsInPromgrammeControlGroup = 1)


				MERGE [Report].[OfferReport_ControlGroupMembers_Counts] target			-- Destination table
				USING OfferReport_ControlGroupMembers_Counts source						-- Source table
				ON target.ControlGroupID = source.ControlGroupID						-- Match criteria

					WHEN MATCHED THEN
						UPDATE SET	target.RetailerID		= source.RetailerID			-- If matched, update to new value
								,	target.SegmentID		= source.SegmentID
								,	target.StartDate		= source.StartDate
								,	target.EndDate			= source.EndDate
								,	target.Customers		= source.Customers
								,	target.ModifiedDate		= source.ModifiedDate

					WHEN NOT MATCHED THEN												-- If not matched, add new rows
						INSERT (RetailerID
							,	SegmentID
							,	ControlGroupID
							,	StartDate
							,	EndDate
							,	Customers
							,	AddedDate)
						VALUES (source.RetailerID
							,	source.SegmentID
							,	source.ControlGroupID
							,	source.StartDate
							,	source.EndDate
							,	source.Customers
							,	source.AddedDate);

					UPDATE cg
					SET cg.IsSegmented = 1
					FROM [Report].[ControlSetup_ControlGroupIDs] cg
					WHERE cg.ControlGroupID = @ControlGroupID
					AND EXISTS (SELECT 1
								FROM [Report].[OfferReport_ControlGroupMembers] cgm
								WHERE cg.ControlGroupID = cgm.ControlGroupID)

					SELECT	@ControlGroupID = MIN(ControlGroupID)
					FROM #ToSegment
					WHERE @ControlGroupID < ControlGroupID

			END

END