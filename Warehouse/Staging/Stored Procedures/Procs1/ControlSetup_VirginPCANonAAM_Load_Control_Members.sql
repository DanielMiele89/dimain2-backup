
/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose:
	- Load control group members INTO [WH_VirginPCA].[Report].[ControlGroupMembers]
	- Load check to confirm that all nFI offers have control groups for the relevant offer cycle

------------------------------------------------------------------------------
Modification History

Jason Shipp 11/07/2018
	- Added logic to only insert new control group members if the ControlGroupID does not already exists in the controlgroupmembers table
Jason Shipp 27/11/2018
	- Added logic to deduplicate control group load commands for cases WHERE 2 control group member tables exist for a retailer (WHERE there are two retailer analysis periods in the cycle)

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_VirginPCANonAAM_Load_Control_Members]
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Load table names that have been created by nFI segmentation process
	******************************************************************************/

	/******************************************************************************
	-- Code for setting up a manual list of control groups to load members for

	EXEC Segmentation.ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro 3421, '2019-05-23', 'Sandbox.ProcessOp.Control342120190523' -- Run missing segmentations

	IF OBJECT_ID('tempdb..#Missing') IS NOT NULL DROP TABLE #Missing; -- Load details for import calls for missing nFI control members

	SELECT DISTINCT 
		ioc.ControlGroupID AS RowNo
		, s.RetailerID AS PartnerID
		, s.SegmentCode AS Segment
		, '20190523' AS StartDate -- Cycle start date
	INTO #Missing
	FROM Warehouse.Relational.IronOfferSegment s
	INNER JOIN [WH_VirginPCA].[Report].[IronOfferCycles] ioc
		ON s.IronOfferID = ioc.IronOfferID	
	WHERE 
		ioc.ControlGroupID IN
		(4573, -- List of nFI ControlGroupIDs missing members
		4574,
		4575,
		4576,
		4578
		)
		AND s.PublisherGroupName = 'nFI'
	ORDER BY 
		s.RetailerID
		, s.SegmentCode;
	******************************************************************************/

		IF OBJECT_ID('tempdb..#Imports') IS NOT NULL DROP TABLE #Imports;
		SELECT	DISTINCT
				im.ControlGroupID
			,	CONVERT(VARCHAR(7), im.ControlGroupID) AS ControlGroupID_Var
			,	im.PartnerID
			,	im.Segment
			,	im.TableName
		INTO #Imports
		FROM (	SELECT	ioc.ControlGroupID
					,	pts.PartnerID
					,	pts.Segment
					,	'Control_' + COALESCE(CONVERT(VARCHAR(5), pts.PartnerID), 'Universal') + '_' + CONVERT(VARCHAR(10), pts.StartDate, 112) as TableName
				FROM [Warehouse].[Staging].[ControlSetup_PartnersToSeg_VirginPCA] pts
				INNER JOIN [Warehouse].[Staging].[ControlSetup_OffersSegment_VirginPCA] os
					ON pts.PartnerID = os.PartnerID
					AND pts.Segment = os.Segment
				INNER JOIN [WH_VirginPCA].[Derived].[IronOffer] iof
					ON os.IronOfferID = iof.IronOfferID
				INNER JOIN [WH_VirginPCA].[Report].[OfferCycles] oc
					ON os.StartDate = oc.StartDate
					AND os.EndDate = oc.EndDate
				INNER JOIN [WH_VirginPCA].[Report].[ironoffercycles] ioc
					ON iof.IronOfferID = ioc.ironofferid
					AND oc.OfferCyclesID = ioc.offercyclesid) im -- OR #Missing if running manually for nFI control groups missing members
		INNER JOIN [Sandbox].[sys].[tables] t
			ON t.name = im.TableName
		INNER JOIN [Sandbox].[sys].[schemas] s
			ON t.schema_id = s.schema_id
		WHERE s.name LIKE SYSTEM_USER -- Will look in current users schema
		AND im.Segment != 'B';

		--SELECT *
		--FROM #Imports


	/******************************************************************************
	Create list of execution queries to be run to import nFI Control Groups
	******************************************************************************/

		DECLARE @InsertQry VARCHAR(MAX) = '
INSERT INTO [WH_VirginPCA].[Report].[ControlGroupMembers]
SELECT	TOP (950000)
		'

		IF OBJECT_ID('tempdb..#ImportControl') IS NOT NULL DROP TABLE #ImportControl;
		SELECT	ic.ImportCode
			,	ROW_NUMBER() OVER (ORDER BY ic.ControlGroupID) AS RowNum
			,	ic.ControlGroupID
		INTO #ImportControl
		FROM (	SELECT	DISTINCT
						CASE 
							WHEN i.Segment = 'SR' THEN @InsertQry + ControlGroupID_Var + ' AS ControlGroupID' + CHAR(10) + '		,	FanID' + CHAR(10) + 'FROM Sandbox.' + SYSTEM_USER + '.' + i.TableName + CHAR(10) + 'WHERE SegmentID IN (6)' + CHAR(10) + 'ORDER BY ABS(CHECKSUM(NEWID()))'
							WHEN i.Segment = 'SG' THEN @InsertQry + ControlGroupID_Var + ' AS ControlGroupID' + CHAR(10) + '		,	FanID' + CHAR(10) + 'FROM Sandbox.' + SYSTEM_USER + '.' + i.TableName + CHAR(10) + 'WHERE SegmentID IN (5)' + CHAR(10) + 'ORDER BY ABS(CHECKSUM(NEWID()))'
							WHEN i.Segment = 'A' THEN @InsertQry + ControlGroupID_Var + ' AS ControlGroupID' + CHAR(10) + '		,	FanID' + CHAR(10) + 'FROM Sandbox.' + SYSTEM_USER + '.' + i.TableName + CHAR(10) + 'WHERE SegmentID IN (1, 2, 7)' + CHAR(10) + 'ORDER BY ABS(CHECKSUM(NEWID()))'
							WHEN i.Segment = 'L' THEN @InsertQry + ControlGroupID_Var + ' AS ControlGroupID' + CHAR(10) + '		,	FanID' + CHAR(10) + 'FROM Sandbox.' + SYSTEM_USER + '.' + i.TableName + CHAR(10) + 'WHERE SegmentID IN (3, 4, 8)' + CHAR(10) + 'ORDER BY ABS(CHECKSUM(NEWID()))'
							ELSE @InsertQry + ControlGroupID_Var + ' AS ControlGroupID' + CHAR(10) + '		,	FanID' + CHAR(10) + 'FROM Sandbox.' + SYSTEM_USER + '.' + i.TableName + CHAR(10) + 'WHERE SegmentID IN (5, 6, 9)' + CHAR(10) + 'ORDER BY ABS(CHECKSUM(NEWID()))'
						END	AS ImportCode
					,	ROW_NUMBER() OVER (PARTITION BY i.ControlGroupID ORDER BY i.TableName Desc) AS ControlRowNum
					,	i.ControlGroupID
				FROM #Imports i
				WHERE NOT EXISTS (	SELECT 1
									FROM [WH_VirginPCA].[Report].[ControlGroupMembers] cgm
									WHERE ControlGroupID_Var = cgm.ControlGroupID)) ic
		WHERE ic.ControlRowNum = 1;

	/******************************************************************************
	Load nFI control group members INTO [WH_VirginPCA].[Report].[ControlGroupMembers]
	******************************************************************************/

		DECLARE	@I_RowNo INT = 1
			,	@I_RowNoMax INT = (SELECT MAX(RowNum) FROM #ImportControl)
			,	@QryImport NVARCHAR(MAX)
			,	@ControlGroupID int;

		WHILE @I_RowNo <= @I_RowNoMax
	
		BEGIN
		
			SET @ControlGroupID = (SELECT ControlGroupID FROM #ImportControl WHERE RowNum = @I_RowNo)

			IF EXISTS (SELECT * FROM [WH_VirginPCA].[Report].[ControlGroupMembers] WHERE ControlGroupID = @ControlGroupID)
			
				SET @I_RowNo = @I_RowNo+1;
		
			ELSE
	
				SET @QryImport = (SELECT [ImportCode] FROM #ImportControl WHERE RowNum = @I_RowNo);
				EXEC sp_executeSQL @QryImport;
				SET @I_RowNo = @I_RowNo+1;

		END

	/******************************************************************************
	Load Universal control group members INTO [WH_VirginPCA].[Report].[ControlGroupMembers]
	******************************************************************************/

		IF OBJECT_ID('tempdb..#Import_Universal') IS NOT NULL DROP TABLE #Import_Universal;
		SELECT	TOP 1
				TableName
		INTO #Import_Universal
		FROM (	SELECT	pts.ControlGroupID
					,	pts.PartnerID
					,	pts.Segment
					,	'VirginPCAControl' + CONVERT(VARCHAR(5), pts.PartnerID) + CONVERT(VARCHAR(10), pts.StartDate, 112) AS TableName
				FROM [Warehouse].[Staging].[ControlSetup_PartnersToSeg_VirginPCA] pts) im -- OR #Missing if running manually for nFI control groups missing members
		INNER JOIN [Sandbox].[sys].[tables] t
			ON t.name = im.TableName
		INNER JOIN [Sandbox].[sys].[schemas] s
			ON t.schema_id = s.schema_id
		WHERE s.name LIKE SYSTEM_USER -- Will look in current users schema
		AND im.Segment = 'B'
		ORDER BY ABS(CHECKSUM(NEWID()));

		DECLARE @Qry_Universal NVARCHAR(MAX);
		DECLARE @ControlGroupID_Universal NVARCHAR(MAX) = (SELECT UniversalControlGroupID FROM [Warehouse].[Staging].[ControlSetup_UniversalOffer_VirginPCA]);

		DECLARE @TableName_Universal NVARCHAR(MAX);

		SELECT	@TableName_Universal = TableName
		FROM #Import_Universal;

		DECLARE @InsertQry_Universal VARCHAR(MAX) = '
INSERT INTO [WH_VirginPCA].[Report].[ControlGroupMembers]
SELECT	TOP (950000)
		'
	
		SET @Qry_Universal = @InsertQry_Universal + @ControlGroupID_Universal + ' AS ControlGroupID' + CHAR(10) + '		,	FanID' + CHAR(10) + 'FROM ' + @TableName_Universal

		IF NOT EXISTS (	SELECT * 
						FROM [WH_VirginPCA].[Report].[ControlGroupMembers]
						WHERE ControlGroupID = @ControlGroupID_Universal)
			BEGIN
				EXEC SP_ExecuteSQL @Qry_Universal;
			END


	/******************************************************************************
	CHECK POINT: Check that all nFI offers have control groups for the relevant offer cycle

	CREATE TABLE for storing validation results

	CREATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Control_Members] (	PublisherType VARCHAR(50)
																							,	PartnerID INT
																							,	ControlGroupID INT
																							,	PartnerName VARCHAR(100)
																							,	IronOfferName NVARCHAR(200)
																							,	StartDate DATE
																							,	EndDate DATE
																							,	IronOfferCyclesID INT
																							,	CONSTRAINT PK_ControlSetup_Validation_VirginPCANonAAM_Control_Members PRIMARY KEY CLUSTERED (IronOfferCyclesID))

	******************************************************************************/

	IF OBJECT_ID('tempdb..#OCs') IS NOT NULL DROP TABLE #OCs;
	SELECT	DISTINCT 
			oc.OfferCyclesID
		,	d.StartDate
		,	d.EndDate
	INTO #OCs
	FROM [Warehouse].[Staging].[ControlSetup_OffersSegment_VirginPCA] AS d
	INNER JOIN [WH_VirginPCA].[Report].[OfferCycles] oc
		ON d.StartDate = oc.StartDate
		AND d.EndDate = oc.EndDate;

	-- Load errors

	TRUNCATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Control_Members];

	INSERT INTO [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Control_Members] (	PublisherType
																							,	PartnerID
																							,	ControlGroupID
																							,	PartnerName
																							,	IronOfferName
																							,	StartDate
																							,	EndDate
																							,	IronOfferCyclesID)
	SELECT	DISTINCT
			'VirginPCA' AS PublisherType
		,	iof.PartnerID
		,	ioc.ControlGroupID
		,	pa.PartnerName
		,	iof.IronOfferName
		,	oc.StartDate
		,	oc.EndDate
		,	ioc.IronOfferCyclesID
	FROM [WH_VirginPCA].[Report].[IronOfferCycles] ioc
	INNER JOIN [WH_VirginPCA].[Derived].[IronOffer] iof
		ON ioc.IronOfferID = iof.IronOfferID
	INNER JOIN [WH_VirginPCA].[Derived].[Partner] pa
		ON iof.PartnerID = pa.PartnerID
	INNER JOIN #OCs oc
		ON ioc.OfferCyclesID = oc.OfferCyclesID
	WHERE NOT (iof.PartnerID = 4820 AND iof.IronOfferName = 'Shopper')
	AND NOT EXISTS (SELECT 1
					FROM [WH_VirginPCA].[Report].[ControlGroupMembers] cgm
					WHERE ioc.ControlGroupID = cgm.ControlGroupID);
	

END
