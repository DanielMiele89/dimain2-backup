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
CREATE PROCEDURE [Staging].[ControlSetup_nFINonAAM_Load_Control_Counts_20210913]
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

	With CountsByDate as (
		Select	
			b.PartnerID
			, Case
				When b.Segment = 'A' then 7
				When b.Segment = 'L' then 8
				When b.Segment = 'S' then 9
				When b.Segment = 'SR' then 10
				When b.Segment = 'SG' then 11
				Else 0
			End as SuperSegmentID
			, b.RowNo as ControlGroupID
			, Cast(b.StartDate as Date) as StartDate
			, Cast(b.EndDate as Date) as EndDate
			, Count(cgm.FanID) as NumberofFanIDs
		From Warehouse.Staging.PartnerControlgroupIDs as b
		Inner join nFI.Relational.controlgroupmembers as cgm
			on b.RowNo = cgm.controlgroupid
		Group By
			b.PartnerID
			, b.RowNo
			, Cast(b.StartDate as Date)
			, Cast(b.EndDate as Date)
			, Case
				When b.Segment = 'A' then 7
				When b.Segment = 'L' then 8
				When b.Segment = 'S' then 9
				When b.Segment = 'SR' then 10
				When b.Segment = 'SG' then 11
				Else 0
			End
	), CountsByDateAgg as (
		Select
			c.PartnerID
			, c.SuperSegmentID
			, c.ControlGroupID
			, Min(c.StartDate) as StartDate
			, Max(c.NumberofFanIDs) as NumberofFanIDs
		From CountsByDate c
		Group by 
			c.PartnerID
			, c.SuperSegmentID
			, c.ControlGroupID
	)
	Insert into nFI.Relational.ControlGroupMember_Counts (PartnerID, SuperSegmentID, ControlGroupID, StartDate, NumberofFanIDs)
	Select 
		c.PartnerID
		, c.SuperSegmentID
		, c.ControlGroupID
		, c.StartDate
		, c.NumberofFanIDs
	From CountsByDateAgg c
	Where not exists (
		Select NULL from nFI.Relational.ControlGroupMember_Counts x
		Where
			c.ControlGroupID = x.ControlGroupID
			and c.StartDate = x.StartDate
	)	
	And Exists (
		Select NULL From nFI.Relational.ironoffercycles ioc
		Where
			c.ControlGroupID = ioc.controlgroupid
	)
	OPTION (FORCE ORDER);

	-- Universal

	Set @UN_ID = (select UniversalControlGroupID from Warehouse.Staging.ControlSetup_UniversalOffer_nFI);
	Set @SDate = (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates);

	Insert into nFI.Relational.ControlGroupMember_Counts (PartnerID, SuperSegmentID, ControlGroupID, StartDate, NumberofFanIDs)
	Select 
		x.PartnerID
		, x.SuperSegmentID
		, x.ControlGroupID
		, x.StartDate
		, x.NumberofFanIDs
	From (
		Select
			0 as PartnerID
			, 0 as SUperSegmentID
			, @UN_ID as ControlGroupID
			, @SDate as StartDate
			, Count(*) as NumberofFanIDs 
		From nFI.Relational.controlgroupmembers cgm
		Where
			ControlGroupID = @UN_ID
	) x
	Where not exists (
		Select NULL From nFI.Relational.ControlGroupMember_Counts d
		Where
			x.ControlGroupID = d.ControlGroupID
			And x.StartDate = d.StartDate
	)
	And Exists (
		Select NULL From nFI.Relational.ironoffercycles ioc
		Where
			x.ControlGroupID = ioc.controlgroupid
	)
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
				AND mc.PartnerID NOT IN (4812)	--	Exclude retailers with counts too low to form control group (Church's)
			)
		);

END