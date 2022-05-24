/******************************************************************************
Author: Jason Shipp
Created: 12/03/2018
Purpose:
	- Load control group members into Warehouse.relational.controlgroupmembers
	- Update partner segments' ControlGroupIDs in Warehouse.relational.ironoffercycles with the ControlGroupIDs associated with alternate partner IDs for the same retailer
	- Load check to confirm that all Warehouse offers have control groups for the relevant offer cycle
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 11/07/2018
	- Added logic to only insert new control group members if the ControlGroupID does not already exists in the controlgroupmembers table
Jason Shipp 27/11/2018
	- Added logic to deduplicate control group load commands for cases where 2 control group member tables exist for a retailer (where there are two retailer analysis periods in the cycle)

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_RBS_Load_Control_Members]
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	-- Code for setting up a manual list of control groups to load members for

	EXEC Segmentation.ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro 3421, '2019-05-23', 'Sandbox.ProcessOp.Control342120190523' -- Run missing segmentations

	If object_id('tempdb..#Missing') is not null drop table #Missing; -- Load details for import calls for missing Warehouse control members

	SELECT DISTINCT 
		ioc.ControlGroupID AS RowNo
		, s.RetailerID AS PartnerID
		, s.SegmentCode AS Segment
		, '20190523' AS StartDate -- Cycle start date
	INTO #Missing
	FROM Warehouse.Relational.IronOfferSegment s
	INNER JOIN Warehouse.Relational.ironoffercycles ioc
		ON s.IronOfferID = ioc.IronOfferID	
	WHERE 
		ioc.ControlGroupID IN
		(5464, -- List of Warehouse ControlGroupIDs missing members
		5465,
		5466,
		5467,
		5468,
		5469,
		5470,
		5471,
		5472,
		5475,
		5473,
		5474
		)
		AND s.PublisherGroupName = 'RBS'
	ORDER BY 
		s.RetailerID
		, s.SegmentCode;
	******************************************************************************/

	/******************************************************************************
	Load table names that have been created by Warehouse segmentation process
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
				FROM [Warehouse].[Staging].ControlSetup_PartnersToSeg_Warehouse pts
				INNER JOIN [Warehouse].[Staging].[ControlSetup_OffersSegment_Warehouse] os
					ON pts.PartnerID = os.PartnerID
					AND pts.Segment = os.Segment
				INNER JOIN [Warehouse].[Relational].[IronOffer] iof
					ON os.IronOfferID = iof.IronOfferID
				INNER JOIN [Warehouse].[Relational].[OfferCycles] oc
					ON pts.StartDate = oc.StartDate
					AND pts.EndDate = oc.EndDate
				INNER JOIN [Warehouse].[Relational].[ironoffercycles] ioc
					ON iof.IronOfferID = ioc.ironofferid
					AND oc.OfferCyclesID = ioc.offercyclesid) im -- Or #Missing if running manually for nFI control groups missing members
		INNER JOIN [Sandbox].[sys].[tables] t
			ON t.name = im.TableName
		INNER JOIN [Sandbox].[sys].[schemas] s
			ON t.schema_id = s.schema_id
		WHERE s.name LIKE SYSTEM_USER -- Will look in current users schema
		AND im.Segment != 'B';

	--SELECT *
	--FROM #Imports

	/******************************************************************************
	Create list of execution queries to be run to import Warehouse Control Groups
	******************************************************************************/

		DECLARE @InsertQry VARCHAR(MAX) = '
INSERT INTO [Warehouse].[Relational].[ControlGroupMembers]
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
									FROM [Warehouse].[Relational].[ControlGroupMembers] cgm
									WHERE ControlGroupID_Var = cgm.ControlGroupID)) ic
		WHERE ic.ControlRowNum = 1;

	--SELECT *
	--FROM #ImportControl

	/******************************************************************************
	Load Warehouse control group members into Warehouse.relational.controlgroupmembers
	******************************************************************************/

		DECLARE	@I_RowNo INT = 1
			,	@I_RowNoMax INT = (SELECT MAX(RowNum) FROM #ImportControl)
			,	@QryImport NVARCHAR(MAX)
			,	@ControlGroupID int;

		WHILE @I_RowNo <= @I_RowNoMax
	
		BEGIN
		
			SET @ControlGroupID = (SELECT ControlGroupID FROM #ImportControl WHERE RowNum = @I_RowNo)

			IF EXISTS (SELECT * FROM [Warehouse].[Relational].[ControlGroupMembers] WHERE ControlGroupID = @ControlGroupID)
			
				SET @I_RowNo = @I_RowNo+1;
		
			ELSE
	
				SET @QryImport = (SELECT [ImportCode] FROM #ImportControl WHERE RowNum = @I_RowNo);
				EXEC sp_executeSQL @QryImport;
				SET @I_RowNo = @I_RowNo+1;

		END

	/******************************************************************************
	Load Universal control group members into Warehouse.relational.controlgroupmembers
	******************************************************************************/

		IF OBJECT_ID('tempdb..#Import_Universal') IS NOT NULL DROP TABLE #Import_Universal;
		SELECT	TOP 1
				TableName
		INTO #Import_Universal
		FROM (	SELECT	pts.PartnerID
					,	pts.Segment
					,	'Control_' + COALESCE(CONVERT(VARCHAR(5), pts.PartnerID), 'Universal') + '_' + CONVERT(VARCHAR(10), pts.StartDate, 112) as TableName
				FROM [Warehouse].[Staging].[ControlSetup_PartnersToSeg_Warehouse] pts) im -- OR #Missing if running manually for nFI control groups missing members
		INNER JOIN [Sandbox].[sys].[tables] t
			ON t.name = im.TableName
		INNER JOIN [Sandbox].[sys].[schemas] s
			ON t.schema_id = s.schema_id
		WHERE s.name LIKE SYSTEM_USER -- Will look in current users schema
		AND im.Segment = 'B'
		ORDER BY ABS(CHECKSUM(NEWID()));

		DECLARE @Qry_Universal NVARCHAR(MAX);
		DECLARE @ControlGroupID_Universal NVARCHAR(MAX) = (SELECT UniversalControlGroupID FROM [Warehouse].[Staging].[ControlSetup_UniversalOffer_Warehouse]);

		DECLARE @TableName_Universal NVARCHAR(MAX);

		SELECT	@TableName_Universal = TableName
		FROM #Import_Universal;

		DECLARE @InsertQry_Universal VARCHAR(MAX) = '
INSERT INTO [Warehouse].[Relational].[ControlGroupMembers]
SELECT	TOP (950000)
		'		
		--SELECT *
		--FROM #Import_Universal

		SET @Qry_Universal = @InsertQry_Universal + @ControlGroupID_Universal + ' AS ControlGroupID' + CHAR(10) + '		,	FanID' + CHAR(10) + 'FROM Sandbox.' + SYSTEM_USER + '.' + @TableName_Universal

		IF NOT EXISTS (	SELECT * 
						FROM [Warehouse].[Relational].[ControlGroupMembers]
						WHERE ControlGroupID = @ControlGroupID_Universal)
			BEGIN
				EXEC SP_ExecuteSQL @Qry_Universal;
			END

	/******************************************************************		
	Update partner segments' ControlGroupIDs in Warehouse.relational.ironoffercycles with the ControlGroupIDs associated with alternate partner IDs for the same retailer
	******************************************************************/

	-- Load alternate PartnerIDs

	If object_id('tempdb..#PartnerAlternate') is not null drop table #PartnerAlternate;
	
	Select distinct 
	* 
	Into #PartnerAlternate
	From 
		(Select 
		PartnerID
		, AlternatePartnerID
		From Warehouse.APW.PartnerAlternate

		UNION ALL 

		Select 
		PartnerID
		, AlternatePartnerID
		From nFI.APW.PartnerAlternate
		) x;

	-- Load new ControlGroupIDs

	If object_id('tempdb..#NewControlGroupIDs') is not null drop table #NewControlGroupIDs;
	
	With ControlGroupIDsToUpdate as
		(Select 
			pa.PartnerID
			, pa.AlternatePartnerID
			 , p.PartnerName
			 , os.Segment
			 , i.ControlGroupID
			 , i.ironoffercyclesid
		From Warehouse.Staging.ControlSetup_OffersSegment_Warehouse os
		Inner join Warehouse.relational.ironoffercycles i
			on os.IronofferID = i.IronOfferID
		Inner join Warehouse.Relational.OfferCycles cyc1
				on i.offercyclesid = cyc1.OfferCyclesID
		Left join Warehouse.relational.[partner] p
			on os.PartnerID = p.PartnerID
		Left join #PartnerAlternate pa
			on os.PartnerID = pa.PartnerID
		WHERE 
			 pa.AlternatePartnerID IS NOT NULL -- Partners for which alternate partner IDs are used in the report process
			 and cyc1.StartDate >= (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates)
			)

	, ControlGroupIDsToKeep as
		(Select 
			os.PartnerID
			 , p.PartnerName
			 , os.Segment
			 , Max(i.ControlGroupID) AS ControlGroupID -- Latest ControlGroupID used for the retailer segment
		From Warehouse.Staging.ControlSetup_OffersSegment_Warehouse os
		Inner join Warehouse.relational.ironoffercycles i
			on os.IronofferID = i.IronOfferID
		Inner join Warehouse.Relational.OfferCycles cyc1
				on i.offercyclesid = cyc1.OfferCyclesID
		Left join Warehouse.relational.[partner] p
			on os.PartnerID = p.PartnerID
		Left join #PartnerAlternate pa
			on os.PartnerID = pa.PartnerID
		WHERE 
			 pa.AlternatePartnerID IS NULL -- Partner IDs used in the report process
			 and cyc1.StartDate >= (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates)
		Group by
			os.PartnerID
			 , p.PartnerName
			 , os.Segment
			)
	
	Select 
		u.PartnerID
		, u.PartnerName
		, u.Segment
		, u.ControlGroupID as CurrentControlGroupID 
		, u.ironoffercyclesid
		, k.ControlGroupID as NewControlGroupID
	Into #NewControlGroupIDs
	From ControlGroupIDsToUpdate u
	Inner join ControlGroupIDsToKeep k
		on u.AlternatePartnerID = k.PartnerID
		and u.Segment = k.Segment;

	-- Update partner segments' ControlGroupIDs in Warehouse.relational.ironoffercycles with the ControlGroupIDs associated with alternate partner IDs for the same retailer

	Update ioc
	Set
		ioc.ControlGroupID = n.NewControlGroupID
	From Warehouse.relational.ironoffercycles ioc
	Inner join #NewControlGroupIDs n
		on ioc.controlgroupid = n.CurrentControlGroupID
		and ioc.ironoffercyclesid = n.ironoffercyclesid
	Inner join Warehouse.Relational.OfferCycles cyc
		on ioc.offercyclesid = cyc.OfferCyclesID
	Where
		cyc.StartDate >= (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates);

	/******************************************************************************
	CHECK POINT: Check that all Warehouse offers have control groups for the relevant offer cycle

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_RBS_Control_Members
		(PublisherType VARCHAR(50)
		, PartnerID INT
		, ControlGroupID INT
		, PartnerName VARCHAR(100)
		, IronOfferName NVARCHAR(200)
		, StartDate DATE
		, EndDate DATE
		, ironoffercyclesid INT
		, CONSTRAINT PK_ControlSetup_Validation_RBS_Control_Members PRIMARY KEY CLUSTERED (ironoffercyclesid)  
		)
	******************************************************************************/

	If object_id('tempdb..#OCs') is not null drop table #OCs;

	Select Distinct
		oc.OfferCyclesID
		,d.StartDate
		,d.EndDate
	Into #OCs
	from Warehouse.Staging.ControlSetup_OffersSegment_Warehouse d
	Inner join Warehouse.relational.OfferCycles oc
		on	d.StartDate = oc.StartDate
		and d.EndDate = oc.EndDate;

	-- Load errors

	Truncate table Warehouse.Staging.ControlSetup_Validation_RBS_Control_Members;

	Insert into Warehouse.Staging.ControlSetup_Validation_RBS_Control_Members
		(PublisherType
		, PartnerID
		, ControlGroupID
		, PartnerName
		, IronOfferName
		, StartDate
		, EndDate
		, ironoffercyclesid
		)	
	Select Distinct
		'Warehouse' as PublisherType
		, o.PartnerID
		, i.ControlGroupID
		, p.PartnerName
		, IronOfferName
		, a.StartDate
		, a.EndDate
		, i.ironoffercyclesid
	From Warehouse.relational.ironoffercycles i
	Inner join Warehouse.relational.ironoffer o
		on i.IronofferID = o.IronOfferID
	Inner join Warehouse.relational.[partner] p
		on p.PartnerID = o.PartnerID
	Inner join #OCs a
		on i.offercyclesid = a.OfferCyclesID
	Where NOT EXISTS (	SELECT 1
						FROM Warehouse.relational.controlgroupMembers cgm
						WHERE i.ControlgroupID = cgm.ControlgroupID)
	AND p.PartnerID NOT IN (4820, 99999, 99999, 99999, 99999, 99999, 99999, 99999, 99999, 99999, 99999);
	
END
