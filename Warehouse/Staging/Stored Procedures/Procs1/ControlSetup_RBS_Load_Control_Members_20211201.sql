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
CREATE PROCEDURE [Staging].[ControlSetup_RBS_Load_Control_Members_20211201]
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

	If object_id('tempdb..#Imports') is not null drop table #Imports;

	Select distinct
		a.RowNo
		, a.PartnerID
		, a.Segment
		, a.TableName
	Into #Imports
	From (
		Select 
			*
			, 'Control_'+Cast(PartnerID as varchar(5)) + '_' + convert(Varchar(10), StartDate,112) as TableName
		From Warehouse.Staging.ControlSetup_PartnersToSeg_Warehouse a -- Or #Missing if running manually for nFI control groups missing members
		) a
	Inner join Sandbox.sys.tables t
		on t.name = a.TableName
	Inner join Sandbox.sys.schemas s 
		on t.schema_id = s.schema_id
	Where
		s.name like SYSTEM_USER -- Will look in current users schema
		And a.Segment <> 'B';

	/******************************************************************************
	Create list of execution queries to be run to import Warehouse Control Groups
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
					'Insert into Warehouse.Relational.controlgroupmembers Select top (950000) '
					+ Cast(i.RowNo as varchar(7))
					+' as ControlgroupID,FanID From Sandbox.'
					+System_User
					+'.'
					+i.TableName
					+' Where SegmentID in (6) '+	'Order by NewID()'
				When i.Segment = 'SG' then 
					'Insert into Warehouse.Relational.controlgroupmembers Select top (950000) '
					+ Cast(i.RowNo as varchar(7))
					+' as ControlgroupID,FanID From Sandbox.'
					+System_User
					+'.'
					+i.TableName
					+' Where SegmentID in (5) '+	'Order by NewID()'
				When i.Segment = 'A' then 
					'Insert into Warehouse.Relational.controlgroupmembers Select top (950000) '
					+ Cast(i.RowNo as varchar(7))
					+' as ControlgroupID,FanID From Sandbox.'
					+System_User
					+'.'
					+i.TableName
					+' Where SegmentID in (1,2) '+	'Order by NewID()'
				When i.Segment = 'L' then 
					'Insert into Warehouse.Relational.controlgroupmembers Select top (950000) '
					+ Cast(i.RowNo as varchar(7))
					+' as ControlgroupID,FanID From Sandbox.'
					+System_User+'.'
					+i.TableName
					+' Where SegmentID in (3,4) '
					+'Order by NewID()'
				Else
					'Insert into Warehouse.Relational.controlgroupmembers Select top (950000) '
					+ Cast(i.RowNo as varchar(7))
					+' as ControlgroupID,FanID From Sandbox.'
					+System_User
					+'.'
					+i.TableName
					+' Where SegmentID in (5,6) ' +'Order by NewID()'
				End
			AS ImportCode
			, Row_number() Over(Partition By i.RowNo Order By i.TableName Desc) AS ControlRowNum
			, i.RowNo AS ControlGroupID
		From #Imports i
		Where not exists (
			Select null
			From Warehouse.Relational.controlgroupmembers m
			where Cast(i.RowNo as varchar(7)) = m.controlgroupid
		)
	) x
	Where x.ControlRowNum = 1;

	/******************************************************************************
	Load Warehouse control group members into Warehouse.relational.controlgroupmembers
	******************************************************************************/

	Declare
		@I_RowNo int = 1
		, @I_RowNoMax int = (Select Max(RowNum) From #ImportControl)
		, @QryImport nvarchar(max)
		, @ControlGroupID int;

	While @I_RowNo <= @I_RowNoMax
	
	Begin
	
		Set @ControlGroupID = (Select ControlGroupID From #ImportControl Where RowNum = @I_RowNo)

		If Exists (Select * From Warehouse.Relational.controlgroupmembers Where controlgroupid = @ControlGroupID)
			
			Set @I_RowNo = @I_RowNo+1;
		
		ELSE

			Set @QryImport = (Select [ImportCode] From #ImportControl Where RowNum = @I_RowNo);
			Exec sp_executeSQL @QryImport;
			Set @I_RowNo = @I_RowNo+1;
	
	End

	/******************************************************************************
	Load Universal control group members into Warehouse.relational.controlgroupmembers
	******************************************************************************/

	Declare @Qry_Universal nvarchar(Max);

	Set @Qry_Universal = 
		(Select top (1) 
			'Insert into Warehouse.Relational.controlgroupmembers
			Select top (975000) (Select UniversalControlGroupID From Warehouse.Staging.ControlSetup_UniversalOffer_Warehouse) as ControlGroupID
			, FanID
			From Sandbox.'
			+System_User
			+'.Control_'
			+Cast(PartnerID as Varchar(5))
			+ '_'
			+convert(Varchar(10), StartDate,112)
			+' Order by Newid()'
		From Warehouse.Staging.ControlSetup_PartnersToSeg_Warehouse
		Where Segment = 'B'
		);

	If Not Exists (
		Select * 
		From Warehouse.Relational.controlgroupmembers
		Where controlgroupid = (Select UniversalControlGroupID From Warehouse.Staging.ControlSetup_UniversalOffer_Warehouse)
	)

	Exec SP_ExecuteSQL @Qry_Universal;

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
		on Cast(d.StartDate as date) = Cast(oc.StartDate as date)
		and Cast(d.EndDate as date) = Cast(oc.EndDate as date);

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
						WHERE i.ControlgroupID = cgm.ControlgroupID);
	
END