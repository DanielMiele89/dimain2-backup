
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
CREATE PROCEDURE [Staging].[ControlSetup_VirginPCANonAAM_Load_Partners_To_Segment]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Load combined POS partner AND MFDD partner settings

		IF OBJECT_ID('tempdb..#PartnerSettings') IS NOT NULL DROP TABLE #PartnerSettings;
		SELECT	dd.PartnerID
			,	dd.Acquire
			,	dd.Lapsed
			,	dd.Shopper
			,	dd.StartDate
			,	dd.EndDate
			,	dd.AutoRun
		INTO #PartnerSettings
		FROM [Warehouse].[Segmentation].[PartnerSettings_DD] dd

		UNION ALL
	
		SELECT	ps.PartnerID
			,	ps.Acquire
			,	ps.Lapsed
			,	ps.Shopper
			,	ps.StartDate
			,	ps.EndDate
			,	ps.AutoRun
		FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings] ps
		WHERE NOT EXISTS (	SELECT 1	--	Logic to avoid duplication
							FROM [Warehouse].[Segmentation].[PartnerSettings_DD] dd
							WHERE ps.PartnerID = dd.PartnerID
							AND (ps.StartDate <= dd.EndDate OR dd.EndDate IS NULL)
							AND (ps.EndDate >= dd.StartDate OR ps.EndDate IS NULL));

		CREATE NONCLUSTERED INDEX ix_PartnerSettings ON #PartnerSettings (PartnerID, StartDate);

	/******************************************************************************
	Load PartnerIDs to run Segmentations for

	CREATE TABLE for storing results:

	CREATE TABLE [Warehouse].[Staging].[ControlSetup_PartnersToSeg_VirginPCA] (ControlGroupID INT
																		,	PartnerID INT
																		,	StartDate DATE
																		,	EndDate DATE
																		,	Segment VARCHAR(50)
																		,	CONSTRAINT PK_ControlSetup_PartnersToSeg_VirginPCA PRIMARY KEY CLUSTERED (ControlGroupID, PartnerID, StartDate, EndDate))

	******************************************************************************/


	-- Load PartnerIDs

		TRUNCATE TABLE [Warehouse].[Staging].[ControlSetup_PartnersToSeg_VirginPCA];

		INSERT INTO [Warehouse].[Staging].[ControlSetup_PartnersToSeg_VirginPCA]
		SELECT	DISTINCT
				pcg.ControlGroupID
			,	b.PartnerID
			,	pcg.StartDate
			,	pcg.EndDate
			,	pcg.Segment
		FROM [WH_VirginPCA].[Report].[PartnerControlGroupIDs] pcg
		INNER JOIN #PartnerSettings b
			ON pcg.PartnerID = b.PartnerID
		INNER JOIN [WH_VirginPCA].[Derived].[Partner] p
			ON b.PartnerID = p.PartnerID;

	-- Load more PartnerIDs

		INSERT INTO [Warehouse].[Staging].[ControlSetup_PartnersToSeg_VirginPCA]
		SELECT	DISTINCT 
				pcg.ControlGroupID
			,	pa.ID AS PartnerID
			,	pcg.StartDate
			,	pcg.EndDate
			,	pcg.Segment
		FROM [WH_VirginPCA].[Report].[PartnerControlGroupIDs] pcg
		LEFT JOIN [Warehouse].[Staging].[ControlSetup_PartnersToSeg_VirginPCA] pts
			on pcg.ControlGroupID = pts.ControlGroupID
		INNER JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri
			on pcg.PartnerID = pri.PrimaryPartnerID
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			on pri.PartnerID = pa.ID
		INNER JOIN #PartnerSettings ps
			on pa.ID = ps.partnerID
		WHERE pts.ControlGroupID IS NULL;

	/******************************************************************************
	CHECK POINT: Check which segments are missing

	CREATE TABLE for storing validation results

	CREATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Partners_To_Segment] (	ID INT IDENTITY (1,1)
																		,	PublisherType VARCHAR(50)
																		,	PartnerID INT
																		,	Segment VARCHAR(10)
																		,	ControlGroupID INT
																		,	StartDate DATE
																		,	EndDate DATE
																		,	CONSTRAINT PK_ControlSetup_Validation_VirginPCANonAAM_Partners_To_Segment PRIMARY KEY CLUSTERED (ID))

	******************************************************************************/

	-- Load errors

		TRUNCATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Partners_To_Segment];

		INSERT INTO [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Partners_To_Segment] (	PublisherType
																									,	PartnerID
																									,	Segment
																									,	ControlGroupID
																									,	StartDate
																									,	EndDate)
		SELECT	'VirginPCA' AS PublisherType
			,	pcg.PartnerID
			,	pcg.Segment
			,	pcg.ControlGroupID
			,	pcg.StartDate
			,	pcg.EndDate
		FROM [WH_VirginPCA].[Report].[PartnerControlGroupIDs] pcg
		WHERE NOT EXISTS (	SELECT 1
							FROM [Warehouse].[Staging].[ControlSetup_PartnersToSeg_VirginPCA]  pts
							WHERE pcg.ControlGroupID = pts.ControlGroupID);

END
