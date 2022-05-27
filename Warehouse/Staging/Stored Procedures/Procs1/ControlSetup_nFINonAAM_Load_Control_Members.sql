/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose:
	- Load control group members into nFI.relational.controlgroupmembers
	- Load check to confirm that all nFI offers have control groups for the relevant offer cycle

------------------------------------------------------------------------------
Modification History

Jason Shipp 11/07/2018
	- Added logic to only insert new control group members if the ControlGroupID does not already exists in the controlgroupmembers table
Jason Shipp 27/11/2018
	- Added logic to deduplicate control group load commands for cases where 2 control group member tables exist for a retailer (where there are two retailer analysis periods in the cycle)

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_nFINonAAM_Load_Control_Members]
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Load table names that have been created by nFI segmentation process
	******************************************************************************/

	/******************************************************************************
	-- Code for setting up a manual list of control groups to load members for

	EXEC Segmentation.ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro 3421, '2019-05-23', 'Sandbox.ProcessOp.Control342120190523' -- Run missing segmentations

	If object_id('tempdb..#Missing') is not null drop table #Missing; -- Load details for import calls for missing nFI control members

	SELECT DISTINCT 
		ioc.ControlGroupID AS RowNo
		, s.RetailerID AS PartnerID
		, s.SegmentCode AS Segment
		, '20190523' AS StartDate -- Cycle start date
	INTO #Missing
	FROM Warehouse.Relational.IronOfferSegment s
	INNER JOIN nFI.Relational.ironoffercycles ioc
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

	If object_id('tempdb..#Imports') is not null drop table #Imports;
	Select	distinct
			pts.RowNo
		,	pts.PartnerID
		,	pts.Segment
		,	pts.TableName
	Into #Imports
	From (	Select	RowNo = ioc.controlgroupid
				,	pts.PartnerID
				,	pts.Segment
				,	'Control_' + COALESCE(CONVERT(VARCHAR(5), pts.PartnerID), 'Universal') + '_' + CONVERT(VARCHAR(10), pts.StartDate, 112) as TableName
			From [Warehouse].[Staging].[ControlSetup_PartnersToSeg_nFI] pts
			INNER JOIN [Warehouse].[Staging].[ControlSetup_OffersSegment_nFI] os
				ON pts.PartnerID = os.PartnerID
				AND pts.Segment = os.Segment
			INNER JOIN [nFI].[Relational].[IronOffer] iof
				ON os.IronOfferID = iof.ID
			INNER JOIN [nFI].[Relational].[OfferCycles] oc
				ON pts.StartDate = oc.StartDate
				AND pts.EndDate = oc.EndDate
			INNER JOIN [nFI].[Relational].[ironoffercycles] ioc
				ON iof.ID = ioc.ironofferid
				AND oc.OfferCyclesID = ioc.offercyclesid) pts -- Or #Missing if running manually for nFI control groups missing members
	Inner join Sandbox.sys.tables t
		on t.name = pts.TableName
	Inner join Sandbox.sys.schemas s 
		on t.schema_id = s.schema_id
	Where
		s.name like SYSTEM_USER -- Will look in current users schema
		And pts.Segment <> 'B';


	--SELECT *
	--FROM #Imports


	/******************************************************************************
	Create list of execution queries to be run to import nFI Control Groups
	******************************************************************************/

	If object_id('tempdb..#ImportControl') is not null drop table #ImportControl;

	Select
	x.ImportCode
	, Row_number() Over(Order BY x.ControlGroupID Asc) AS RowNum
	, x.ControlGroupID
	Into #ImportControl
	From (
		Select distinct
			Case 
				When i.Segment = 'SR' then 
					'Insert into nfi.Relational.controlgroupmembers Select top (950000) '
					+ Cast(i.RowNo as varchar(7))
					+' as ControlgroupID,FanID From Sandbox.'
					+System_User
					+'.'
					+i.TableName
					+' Where SegmentID in (6) '+	'Order by NewID()'
				When i.Segment = 'SG' then 
					'Insert into nfi.Relational.controlgroupmembers Select top (950000) '
					+ Cast(i.RowNo as varchar(7))
					+' as ControlgroupID,FanID From Sandbox.'
					+System_User
					+'.'
					+i.TableName
					+' Where SegmentID in (5) '+	'Order by NewID()'
				When i.Segment = 'A' then 
					'Insert into nfi.Relational.controlgroupmembers Select top (950000) '
					+ Cast(i.RowNo as varchar(7))
					+' as ControlgroupID,FanID From Sandbox.'
					+System_User
					+'.'
					+i.TableName
					+' Where SegmentID in (1,2,7) '+	'Order by NewID()'
				When i.Segment = 'L' then 
					'Insert into nfi.Relational.controlgroupmembers Select top (950000) '
					+ Cast(i.RowNo as varchar(7))
					+' as ControlgroupID,FanID From Sandbox.'
					+System_User+'.'
					+i.TableName 
					+' Where SegmentID in (3,4,8) '
					+'Order by NewID()'
				Else 
					'Insert into nfi.Relational.controlgroupmembers Select top (950000) '
					+ Cast(i.RowNo as varchar(7))
					+' as ControlgroupID,FanID From Sandbox.'
					+System_User+'.'
					+i.TableName
					+' Where SegmentID in (5,6,9) ' +'Order by NewID()'
				End
			AS ImportCode
			, Row_number() Over(Partition By i.RowNo Order By i.TableName Desc) AS ControlRowNum
			, i.RowNo AS ControlGroupID
		From #Imports i
		Where not exists (
			Select null
			From nfi.Relational.controlgroupmembers m
			where Cast(i.RowNo as varchar(7)) = m.controlgroupid
		)
	) x
	Where x.ControlRowNum = 1;

	/******************************************************************************
	Load nFI control group members into nFI.relational.controlgroupmembers
	******************************************************************************/

	Declare
		@I_RowNo int = 1
		, @I_RowNoMax int = (Select Max(RowNum) From #ImportControl)
		, @QryImport nvarchar(max)
		, @ControlGroupID int;

	While @I_RowNo <= @I_RowNoMax
	
	Begin
		
		Set @ControlGroupID = (Select ControlGroupID From #ImportControl Where RowNum = @I_RowNo)

		If Exists (Select * From nFI.Relational.controlgroupmembers Where controlgroupid = @ControlGroupID)
			
			Set @I_RowNo = @I_RowNo+1;
		
		ELSE
	
			Set @QryImport = (Select [ImportCode] From #ImportControl Where RowNum = @I_RowNo);
			Exec sp_executeSQL @QryImport;
			Set @I_RowNo = @I_RowNo+1;

	End

	/******************************************************************************
	Load Universal control group members into nFI.relational.controlgroupmembers
	******************************************************************************/

	Declare @Qry_Universal nvarchar(Max);
	
	Set @Qry_Universal = 
		(Select top 1 
			'Insert into nfi.relational.controlgroupmembers
			Select top (975000) (Select UniversalControlGroupID From Warehouse.Staging.ControlSetup_UniversalOffer_nFI) as ControlGroupID
			, FanID
			From Sandbox.'
			+System_User
			+'.Control'
			+Cast(PartnerID as Varchar(5))
			+convert(Varchar(10), StartDate,112)
			+' Order by Newid()'
		From Warehouse.Staging.ControlSetup_PartnersToSeg_nFI
		Where Segment = 'B'
		);

	If Not Exists (
		Select * 
		From nFI.Relational.controlgroupmembers
		Where controlgroupid = (Select UniversalControlGroupID From Warehouse.Staging.ControlSetup_UniversalOffer_nFI)
	)

	Exec SP_ExecuteSQL @Qry_Universal;

	/******************************************************************************
	CHECK POINT: Check that all nFI offers have control groups for the relevant offer cycle

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Control_Members
		(PublisherType VARCHAR(50)
		, PartnerID INT
		, ControlGroupID INT
		, PartnerName VARCHAR(100)
		, IronOfferName NVARCHAR(200)
		, StartDate DATE
		, EndDate DATE
		, ironoffercyclesid INT
		, CONSTRAINT PK_ControlSetup_Validation_nFINonAAM_Control_Members PRIMARY KEY CLUSTERED (ironoffercyclesid)  
		)
	******************************************************************************/

	if object_id('tempdb..#OCs') is not null drop table #OCs;

	Select Distinct 
		oc.OfferCyclesID
		, d.StartDate
		, d.EndDate
	Into #OCs
	from Warehouse.Staging.ControlSetup_OffersSegment_nFI as d
	Inner join nFI.relational.OfferCycles oc
		on	d.StartDate = oc.StartDate
		and d.EndDate = oc.EndDate;

	-- Load errors

	Truncate table Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Control_Members;

	Insert into Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Control_Members
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
		'nFI' as PublisherType
		, o.PartnerID
		, i.ControlGroupID
		, p.PartnerName
		, o.IronOfferName
		, a.StartDate
		, a.EndDate
		, i.ironoffercyclesid
	From nfi.relational.ironoffercycles i
	Inner join nfi.relational.ironoffer o
		on i.IronofferID = o.ID
	Inner join nfi.relational.partner as p
		on p.PartnerID = o.PartnerID
	Inner join #OCs as a
		on i.offercyclesid = a.OfferCyclesID
	Where NOT (o.PartnerID = 4820 AND o.IronOfferName IN ('Lapsed', 'Shopper'))
	AND NOT EXISTS (SELECT 1
					FROM [nfi].[Relational].[controlgroupmembers] cgm
					WHERE i.controlgroupid = cgm.controlgroupid);
	

END

