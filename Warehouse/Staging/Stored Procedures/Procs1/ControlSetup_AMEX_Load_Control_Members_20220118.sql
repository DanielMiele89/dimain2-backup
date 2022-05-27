/******************************************************************************
Author: Jason Shipp
Created: 15/03/2018
Purpose: 
	- Load AMEX control group members into nFI.Relational.AmexControlGroupMembers
	- Load check to confirm that all AMEX offers have control groups for the relevant offer cycle
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 15/05/2018
	- Changed logic identifying new offer cycles to include any AMEX offer periods overlapping the cycle
	- Identified Sandbox table names based on the partner start date in the Warehouse.Staging.ControlSetup_PartnersToSeg_nFI table instead of the cycle start date

Jason Shipp 28/08/2018
	- Used Warehouse.Relational.IronOfferSegment table as source of segment codes instead of applying string searches to IronOfferNames
Jason Shipp 27/11/2018
	- Added logic to deduplicate control group load commands for cases where 2 control group member tables exist for a retailer (where there are two retailer analysis periods in the cycle)

Jason Shipp 20/06/2019
	- Added logic to optimise load of AMEX control group member counts by checking which counts don't exist in the nFI.relational.AmexControlGroupMember_Counts table before the calculation

Jason Shipp 12/09/2019
	- Added load of segmented control group member tables if missing for retailer cycles

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_AMEX_Load_Control_Members_20220118]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Declare variables
	******************************************************************************/

	Declare @SDate date = (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates);
	Declare @EDate date = (Select EndDate from Warehouse.Staging.ControlSetup_Cycle_Dates);

	/******************************************************************************
	Add new entries to nFI.Relational.OfferCycles
	******************************************************************************/

	Insert into nFI.Relational.OfferCycles 
	Select
		a.*
	From 
		(Select	Distinct 
			StartDate
			, Dateadd(second,-1,Dateadd(day,1,Cast(EndDate as datetime))) as EndDate
		 From nFi.Relational.AmexOffer
		 Where
			StartDate <= @EDate
			and EndDate >= @SDate
		) a
	Left join nFI.Relational.OfferCycles b
		on a.StartDate = b.StartDate
		and a.EndDate = b.EndDate
	Where 
		b.OfferCyclesID is null;

	/******************************************************************************
	Add new entries to nFI.Relational.AmexIronOfferCycles
	******************************************************************************/

	Declare @MaxControlGroupID int = (Select Max(AmexControlGroupID) From nFI.Relational.AmexIronOfferCycles)

	Insert into nFI.Relational.AmexIronOfferCycles
	Select
		a.IronOfferID
		, oc.OfferCyclesID,
		ROW_NUMBER() OVER(ORDER BY a.IronOfferID DESC) + @MaxControlGroupID
	From nFI.Relational.AmexOffer a
	Left join nFI.Relational.AmexIronOfferCycles o
		on a.IronOfferID = o.AmexIronOfferID
	Inner join nFI.Relational.OfferCycles oc
		on a.startDate = oc.StartDate
		and a.EndDate = Cast(oc.EndDate as date)
	Where
		o.AmexIronOfferID is null
		and oc.StartDate <= @EDate
		and oc.EndDate >= @SDate;

	/******************************************************************************
	Load Sandbox table names from which to gather AMEX control group members, using the user's schema
	******************************************************************************/

	if object_id('tempdb..#Tables') is not null drop table #Tables;

	Select distinct
		a.AmexIronOfferID
		, a.OfferCyclesID
		, a.AmexControlGroupID
		, m.RetailerID
		, 'Sandbox.'+System_User+'.Control'+Cast(m.RetailerID as varchar(6))+CONVERT(varchar, COALESCE(p.StartDate, @SDate), 112) as TableName
		, TargetAudience
		, COALESCE(p.StartDate, @SDate) as StartDate
		, ROW_NUMBER() OVER (ORDER BY m.RetailerID, a.OfferCyclesID) as RowNum
	Into #Tables
	From nfi.relational.AmexIronOfferCycles a
	left join nfi.Relational.AmexControlGroupMembers c
		on a.AmexControlGroupID = c.AmexControlgroupID
	Inner join nfi.relational.AmexOffer m
		on a.AmexIronOfferID = m.IronOfferID
	LEFT JOIN [SLC_Report].[dbo].[Partner] pa
		ON m.RetailerID = pa.ID
	Left join 
			(Select distinct PartnerID, StartDate from Warehouse.Staging.ControlSetup_PartnersToSeg_nFI
			Union 
			Select distinct PartnerID, StartDate from Warehouse.Staging.ControlSetup_PartnersToSeg_Warehouse
			) p
		on m.RetailerID = p.PartnerID
	Where
		c.FanID is null
	AND pa.Matcher NOT IN (52)

		--And m.RetailerID not in (4263,4265,4626) -- Remember to include secondary PartnerIDs if setting up a single partner
		--And m.IronOfferID in (-550,-549,-548);

	/******************************************************************************
	Create segmented control group member tables if missing for retailer cycles
	******************************************************************************/

	IF OBJECT_ID('tempdb..#MFDDPartners') IS NOT NULL DROP TABLE #MFDDPartners;

	SELECT DISTINCT
	dd.PartnerID
	INTO #MFDDPartners
	FROM Warehouse.Segmentation.PartnerSettings_DD dd
	UNION
	SELECT
	pa.PartnerID
	FROM Warehouse.Segmentation.PartnerSettings_DD dd
	INNER JOIN Warehouse.APW.partnerAlternate pa
	ON dd.PartnerID = pa.AlternatePartnerID
	UNION 
	SELECT
	pa.PartnerID
	FROM Warehouse.Segmentation.PartnerSettings_DD dd
	INNER JOIN nFI.APW.partnerAlternate pa
	ON dd.PartnerID = pa.AlternatePartnerID;

	DECLARE @CLOSegmentStoredProcedure varchar(100) = 'Warehouse.Segmentation.ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro';
	DECLARE @MFDDSegmentStoredProcedure varchar(100) = 'Warehouse.Segmentation.ROC_Shopper_Segmentation_Individual_Partner_Control_MFDD';

	DECLARE @MinRowNumber int = (SELECT MIN(RowNum) FROM #Tables);
	DECLARE @MaxRowNumber int = (SELECT MAX(RowNum) FROM #Tables);
	DECLARE @RowNumber int = @MinRowNumber;
	DECLARE @TableName varchar(100);
	DECLARE @RetailerID int;
	DECLARE @Date varchar(10);
	DECLARE @Qry nvarchar(max);

	WHILE @RowNumber <= @MaxRowNumber
	BEGIN

		SET @TableName = (Select TableName From #Tables Where RowNum = @RowNumber);

		If object_id(@TableName) is null
		
		BEGIN
		
			SET @RetailerID = (Select RetailerID From #Tables Where RowNum = @RowNumber);
			SET @Date = (Select StartDate From #Tables Where RowNum = @RowNumber);

			SET @Qry = (
				'EXEC '
				+ CASE WHEN @RetailerID IN (SELECT PartnerID FROM #MFDDPartners) THEN @MFDDSegmentStoredProcedure ELSE @CLOSegmentStoredProcedure END
				+ ' '
				+ Cast(@RetailerID as Varchar(4))
				+ ','''
				+ convert(Varchar(10), @Date, 112)
				+ ''',''' 
				+ @TableName
				+ '''' 
			);

			Exec sp_executeSQL @Qry;

		END

		SET @RowNumber = @RowNumber + 1;

	END

	/******************************************************************************
	Create list of execution queries to import AMEX control group members into nFI.Relational.AmexControlGroupMembers table from Sandbox tables
	******************************************************************************/

	If object_id('tempdb..#CGInsertCode') is not null drop table #CGInsertCode;

	Select
	x.EXCcode
	, Row_number() Over(Order By x.AmexControlGroupID Asc) AS RowNum
	, x.AmexControlGroupID
	Into #CGInsertCode	
	From (	
		Select distinct
				'Insert into nFI.Relational.AmexControlGroupMembers
				Select top (950000) '
				+ Cast(t.AmexControlGroupID as varchar(7))
				+ ', FanID From '
				+ t.TableName
				+ ' Where SegmentID '
				+ Case
					When s.SegmentCode = 'SR' then 'in (6)'
					When s.SegmentCode = 'SG' then 'in (5)'
					When s.SegmentCode = 'S' then 'in (5,6)'
					When s.SegmentCode = 'L' then 'in (3,4)'
					When s.SegmentCode = 'A' then 'in (1,2)'
					Else ' > 0'
			End AS EXCcode
			, Row_number() Over(Partition BY t.AmexControlGroupID ORDER BY t.TableName Desc) AS ControlRowNum
			, t.AmexControlGroupID
	From #Tables as t
	Left join Warehouse.Relational.IronOfferSegment s
		on t.AmexIronOfferID = s.IronOfferID
	) x
	Where x.ControlRowNum = 1;

	/******************************************************************************
	Execute queries to import AMEX control group members into nFI.Relational.AmexControlGroupMembers table
	******************************************************************************/
	
	Declare
		@RowNo int = (Select Min(RowNum) From #CGInsertCode)
		, @RowNoMax int = (Select Max(RowNum) From #CGInsertCode)
		, @Qry_LoadCG nvarchar(max)
		, @ControlGroupID int;

	While @RowNo <= @RowNoMax

	Begin

		Set @ControlGroupID = (Select AmexControlGroupID From #CGInsertCode Where @RowNo = RowNum)
		
		If Exists (Select * From nFI.Relational.AmexControlGroupMembers Where AmexControlgroupID = @ControlGroupID)
			
			Set @RowNo = @RowNo+1;
	
		Else

			Set @Qry_LoadCG = 
				(Select EXCcode
				From #CGInsertCode 
				Where
					RowNum = @RowNo 
				);
			Exec sp_executeSQL @Qry_LoadCG;
			Set @RowNo = @RowNo+1;

	End

	/******************************************************************************
	Find AMEX offers missing control group members for the current cycle
	******************************************************************************/

	If object_id('tempdb..#MissingUniversal') is not null drop table #MissingUniversal;

	Select
		a.*
		, m.RetailerID
		, TargetAudience
		, oc.StartDate
	Into #MissingUniversal 
	From nfi.relational.AmexIronOfferCycles a
	Left join nFI.Relational.AmexControlGroupMembers c
		on a.AmexControlGroupID = c.AmexControlgroupID
	Inner join nFI.Relational.AmexOffer m
		on a.AmexIronOfferID = m.IronOfferID
	Inner join nFI.Relational.offercycles oc
		on oc.OfferCyclesID = a.OfferCyclesID
		and oc.StartDate <= @SDate
		and oc.EndDate > @SDate
	Left join Warehouse.Relational.IronOfferSegment s
		on m.IronOfferID = s.IronOfferID
	Where 
		c.FanID is null
		and (s.SegmentCode not in ('SR','SG','S','L','A') or s.SegmentCode is null)
		--and m.RetailerID not in (4263,4265,4626) -- Remember to include secondary PartnerIDs if setting up a single partner

	/******************************************************************************
	Create list of execution queries to import more AMEX control group members into nFI.Relational.AmexControlGroupMembers table from Sandbox tables
	******************************************************************************/

	If object_id('tempdb..#AllMembersCGs') is not null drop table #AllMembersCGs;

	Select top 1 -- There should only be one entry
			'Insert Into nFI.Relational.AmexControlGroupMembers Select top 975000 '
			+ cast(m.AmexControlGroupID as varchar(10)) 
			+ ' as AmexControlGroupID, FanID From Sandbox.'
			+ SYSTEM_USER
			+ '.'
			+ t.name
			+ ' order by newid()'
		as EXCCode
		, ROW_NUMBER() over (order by m.AmexControlGroupID) as RowNum
		, m.AmexControlGroupID
	Into #AllMembersCGs
	From Sandbox.sys.tables t
	Inner join Sandbox.sys.schemas s
		on s.schema_id = t.schema_id
	, #MissingUniversal m
	where
		s.name = SYSTEM_USER
		and t.name like ('Control%'+convert(Varchar(10), m.StartDate,112)); -- Match Sandbox control members tables to offers identified as missing control members in #MissingUniversal
	
	/******************************************************************************
	Execute queries to import more AMEX control group members into nFI.Relational.AmexControlGroupMembers
	******************************************************************************/

	Declare
		@RowNumberAM int = (select Min(rownum) from #AllMembersCGs)
		, @RowNumberAMMax int = (select Max(rownum) from #AllMembersCGs)
		, @QryAllMembers nvarchar(Max)
		, @ControlGroupID2 int;

	While @RowNumberAM <= @RowNumberAMMax 
	
	Begin 

		Set @ControlGroupID2 = (Select AmexControlGroupID From #AllMembersCGs Where RowNum = @RowNumberAM)

		If Exists (Select * From nFI.Relational.AmexControlGroupMembers Where AmexControlgroupID = @ControlGroupID2)
			
			Set @RowNumberAM = @RowNumberAM +1;
		
		ELSE

			Set @QryAllMembers = (Select EXCCode from #AllMembersCGs where RowNum = @RowNumberAM);
			Exec sp_executesql @QryAllMembers;
			Set @RowNumberAM = @RowNumberAM +1;

	End

	/******************************************************************************
	Load AMEX control group member counts into nFI.Relational.AmexControlGroupMember_Counts
	******************************************************************************/
	 
	-- Identify new AMEX control group member counts

	If object_id('tempdb..#MissingCounts') is not null drop table #MissingCounts;
	
	Select 
		ao.RetailerID 
		, ao.SegmentID
		, ISNULL(s.SuperSegmentID, 0) AS SupersegmentID
		, aoc.AmexControlGroupID
		, oc.StartDate
	Into #MissingCounts
	From nFI.Relational.AmexIronOfferCycles aoc
	Inner join nFI.Relational.AmexOffer ao
		on aoc.AmexIronOfferID = ao.IronOfferID
	Inner join nFI.Relational.OfferCycles oc
		on oc.OfferCyclesID = aoc.OfferCyclesID
	Left Join nFI.Relational.AmexControlGroupMember_Counts c
		on c.AmexControlgroupID = aoc.AmexControlGroupID
		And oc.StartDate = c.StartDate
	Left join Warehouse.Relational.IronOfferSegment s
		on ao.IronOfferID = s.IronOfferID
	Where
		c.amexcontrolgroupid is NULL
		and Dateadd(day, -27, oc.StartDate) <= @SDate
		and oc.EndDate > @SDate;

	-- Load new AMEX control group member counts into nFI.Relational.AmexControlGroupMember_Counts

	Insert into nFI.relational.AmexControlGroupMember_Counts
	Select
		mc.RetailerID as PartnerID
		, mc.SuperSegmentID
		, mc.AmexControlGroupID
		, mc.StartDate
		, Count(*) as NumberOfFanIDs
	From #MissingCounts mc
	Inner join nFI.Relational.AmexControlGroupMembers cgm
		on cgm.AmexControlgroupID = mc.amexcontrolgroupid
	Group by
		RetailerID
		, SupersegmentID
		, mc.AmexControlGroupID
		, mc.StartDate;

	/******************************************************************************
	CHECK POINT: Check that all AMEX offers have control groups for the relevant offer cycle

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_AMEX_Control_Members
		(PublisherType VARCHAR(50)
		, PartnerID INT
		, AmexControlGroupID INT
		, AmexIronOfferID INT
		, OfferCyclesID INT
		, TargetAudience VARCHAR(50)
		, CONSTRAINT PK_ControlSetup_Validation_AMEX_Control_Members PRIMARY KEY CLUSTERED (AmexIronOfferID, OfferCyclesID)  
		)
	******************************************************************************/

	-- Load errors

	Truncate table Warehouse.Staging.ControlSetup_Validation_AMEX_Control_Members;

	Insert into Warehouse.Staging.ControlSetup_Validation_AMEX_Control_Members
		(PublisherType
		, PartnerID
		, AmexControlGroupID
		, AmexIronOfferID
		, OfferCyclesID
		, TargetAudience
		)
	Select
		'AMEX' as PublisherType
		, m.RetailerID AS PartnerID
		, a.AmexControlGroupID
		, a.AmexIronOfferID
		, a.OfferCyclesID		
		, m.TargetAudience
	From nFI.Relational.AmexIronOfferCycles a
	Left join nFI.Relational.AmexControlGroupMembers c
		on a.AmexControlGroupID = c.AmexControlgroupID
	Inner join nFI.Relational.AmexOffer m
		on a.AmexIronOfferID = m.IronOfferID
	LEFT JOIN [SLC_Report].[dbo].[Partner] pa
		ON m.RetailerID = pa.ID
	Where 
		c.FanID is null
	AND pa.Matcher NOT IN (52);
				
END