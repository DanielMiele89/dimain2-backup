/******************************************************************************
Author: Jason Shipp
Created: 13/03/2018
Purpose:
	- Load In Programme control group members into nFI/Warehouse Relational.controlgroupmembers tables
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 11/07/2018
	- Added logic to update ControlGroupIDs for cases where a ControlGroupID already exists for that retailer segment in that cycle

Jason Shipp 11/07/2018
	- Added load of new control group member counts into nFI and Warehouse Relational.ControlGroupMember_Counts tables

Jason Shipp 31/01/2019
	- Updated base control members table to Warehouse.Staging.ControlSetup_Waitrose_IPControlGroupsFrom01102017

Jason Shipp 11/09/2019
	- Paramatised query so it can be run for specific retailers (using @RetailerID)
	- Added primary and fallback source of in programme universe for cycle:
		- Primary: [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram]
		- Fallback: Warehouse.Staging.ControlGroupInProgramme_Fallback: this table must be manually maintained
	- Added control of where segments are derived from:
		- CLO retailer: Warehouse.Segmentation.Roc_Shopper_Segment_Members
		- MFDD retailer: Warehouse.Segmentation.CustomerSegment_DD

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_Secondary_Load_Control_Members] (@RetailerID int)

AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @StartDate date = (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates);
	DECLARE @CycleEndDate date = DATEADD(day, 27, @StartDate);

	---- For testing
	--DECLARE @RetailerID int = 4265;

	/******************************************************************************
	Load partner alternates
	******************************************************************************/

	If object_id('tempdb..#PartnerAlternate') is not null drop table #PartnerAlternate;

	Select distinct * 
	Into #PartnerAlternate
	From 
		(Select 
		PartnerID
		, AlternatePartnerID
		From Warehouse.APW.PartnerAlternate

		Union all  

		Select 
		PartnerID
		, AlternatePartnerID
		From nFI.APW.PartnerAlternate
		) x;

	If object_id('tempdb..#PartnerIDs') is not null drop table #PartnerIDs;

	Select @RetailerID AS PartnerID
	Into #PartnerIDs
	Union
	Select PartnerID From #PartnerAlternate
	Where AlternatePartnerID = @RetailerID;

	/******************************************************************************
	Load FanIDs to create control groups from
	******************************************************************************/

	-- Load customer Table

	IF OBJECT_ID('tempdb..#Control_Full') IS NOT NULL DROP TABLE #Control_Full;

	CREATE TABLE #Control_Full (
		FanID int
		, CurrentSegment varchar(30)
	);
	
	IF @RetailerID IN ( -- Check in programme members table contains members for the retailer for Iron Offers overlapping the cycle
		SELECT DISTINCT s.PartnerID 
		FROM Warehouse.Relational.IronOfferSegment s
		INNER JOIN [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] ip 
		ON s.IronOfferID = ip.IronOfferID
		WHERE 
		(s.RetailerID = @RetailerID OR s.PartnerID = @RetailerID)
		AND s.OfferStartDate <= @CycleEndDate
		AND (s.OfferEndDate >= @StartDate OR s.OfferEndDate IS NULL)
	)
	BEGIN -- Load source control group members where in programme members exist in the [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] table
		With IronOfferIDs AS (
			Select IronOfferID from Warehouse.Relational.IronOfferSegment s
			Where 
			(s.RetailerID = @RetailerID OR s.PartnerID = @RetailerID)
			AND s.OfferStartDate <= @CycleEndDate
			AND (s.OfferEndDate >= @StartDate OR s.OfferEndDate IS NULL)
		)
		Insert into #Control_Full (FanID, CurrentSegment)
		Select
			DISTINCT(cg.FanID) AS FanID
			, NULL AS CurrentSegment
		From [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cg
		Inner Join Relational.Customer c -- Make sure in programme
			on cg.FanID = c.FanID
		Where 
			cg.IronOfferID in (Select IronOfferID from IronOfferIDs)
			and cg.ExcludeFromAnalysis = 0;
	END
	ELSE
	BEGIN -- Load source control group members where in programme members don't exist in the [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] table; use fallback table instead
		Insert into #Control_Full (FanID, CurrentSegment)
		Select
			cg.FanID
			, NULL AS CurrentSegment
		From Warehouse.Staging.ControlGroupInProgramme_Fallback cg
		Inner Join Relational.Customer c -- Make sure in programme
			on cg.FanID = c.FanID
		Where
			cg.RetailerID = @RetailerID
			and cg.StartDate <= @CycleEndDate
			and (cg.EndDate IS NULL OR cg.EndDate >= @StartDate)
			
	END

	CREATE UNIQUE CLUSTERED INDEX UCIX_Control_Full ON #Control_Full  (FanID);

	-- Update members' current ALS segment types

	If object_id('tempdb..#Updates') is not null drop table #Updates;

	CREATE TABLE #Updates (
		FanID int
		, ShopperSegmentTypeID varchar(30)
	);

	If (
		Select COUNT(*) from #PartnerIDs
		Where PartnerID in (SELECT PartnerID FROM Warehouse.Segmentation.PartnerSettings_DD) -- Check if @RetailerID is associated with MFDD partners
	) > 0
	BEGIN -- Use Warehouse.Segmentation.CustomerSegment_DD table as segemnt source for MFDD partners
		Insert into #Updates (FanID, ShopperSegmentTypeID)
			Select 
				t.FanID
				, MAX(ssm.ShopperSegmentTypeID) AS ShopperSegmentTypeID
			From #Control_Full t
			Inner Join Warehouse.Segmentation.CustomerSegment_DD ssm
				on t.FanID = ssm.FanID
				and (ssm.EndDate is null or ssm.EndDate >= @StartDate)
				and ssm.StartDate <= @CycleEndDate
			Where 
				ssm.PartnerID IN (Select PartnerID From #PartnerIDs)
			Group by
				t.FanID;
	END
	ELSE
	BEGIN -- Use Warehouse.Segmentation.Roc_Shopper_Segment_Members table as segemnt source for CLO partners
		Insert into #Updates (FanID, ShopperSegmentTypeID)
			Select 
				t.FanID
				, MAX(ssm.ShopperSegmentTypeID) AS ShopperSegmentTypeID
			From #Control_Full t
			Inner Join Warehouse.Segmentation.Roc_Shopper_Segment_Members ssm
				on t.FanID = ssm.FanID
				and (ssm.EndDate is null or ssm.EndDate >= @StartDate)
				and ssm.StartDate <= @CycleEndDate
			Where 
				ssm.PartnerID IN (Select PartnerID From #PartnerIDs)
			Group by
				t.FanID;
	END

	Update t
	Set t.CurrentSegment = u.ShopperSegmentTypeID 
	From #Control_Full t
	Inner join #Updates u
	on t.FanID = u.FanID;

	-- Delete members with no ALS segment type

	Delete from #Control_Full
	Where
		CurrentSegment is null;

	/******************************************************************************
	Load nFI ControlGroupIDs into nFI.Relational.SecondaryControlGroups (for In Programme)
	******************************************************************************/

	-- Create table of ControlGroupID updates for cases where a ControlGroupID already exists for that retailer segment in that cycle 

	If object_id('tempdb..#ExistingControlUpdates_nFI') is not null drop table #ExistingControlUpdates_nFI;

	Select
	x.PartnerID
	, x.Segment	
	, x.ControlGroupID 
	Into #ExistingControlUpdates_nFI
	From (
		Select Distinct
			s.PartnerID
			, s.Segment	
			, scg.ControlGroupID
			, Dense_rank() OVER (Partition by s.PartnerID, s.Segment Order by scg.ControlGroupID ASC) as ControlGroupIDRank
		From Warehouse.Staging.ControlSetup_OffersSegment_Secondary s
		Inner join nFI.Relational.IronOffer_References ior
			on s.IronOfferID = ior.IronOfferID
		Inner join nFI.Relational.IronOfferCycles ioc
			on ior.ironoffercyclesid = ioc.ironoffercyclesid
		Inner join nFI.Relational.SecondaryControlGroups scg
			on ior.ironoffercyclesid = scg.ironoffercyclesid
		Inner join nFI.Relational.OfferCycles cyc
			on ioc.offercyclesid = cyc.OfferCyclesID
			and CAST(s.StartDate as date) = Cast(cyc.StartDate as date)
			and CAST(s.EndDate as date) = Cast(cyc.EndDate as date)
		Where
			s.PublisherType = 'nFI'
			and s.PartnerID = @RetailerID
	) x
	Where x.ControlGroupIDRank = 1;

	-- Load ControlGroupIDs

	Declare @MaxID1 int = (Select Max(ControlGroupID) From nFI.Relational.controlgroupmembers);
	Declare @MaxID2 int = (Select Max(ControlGroupID) From nFI.Relational.ironoffercycles);
	
	If @MaxID2 > @MaxID1 set @MaxID1 = @MaxID2

	Insert into nFI.Relational.SecondaryControlGroups
	Select
		i.IronOfferCyclesID
		, COALESCE (
			e.ControlGroupID
			, Case 
				when os.Segment = 'A' then @MaxID1+1
				when os.Segment = 'L' then @MaxID1+2
				when os.Segment = 'S' then @MaxID1+3
				when os.Segment = 'SR' then @MaxID1+4
				when os.Segment = 'SG' then @MaxID1+5
			Else 0 
			End				
		) as ControlGroupID
		, 1 as ControlGroupTypeID
	From nFI.Relational.ironoffercycles i
	Inner join nFI.relational.OfferCycles o
		on i.offercyclesid = o.OfferCyclesID
	Left join nFI.Relational.SecondaryControlGroups a
		on i.ironoffercyclesid = a.IronOfferCyclesID
	Inner join Warehouse.Staging.ControlSetup_OffersSegment_Secondary os
		on os.IronOfferID = i.ironofferid
		and os.PublisherType = 'nFI'
	Left join #ExistingControlUpdates_nFI e
		on os.PartnerID = e.PartnerID
		and os.Segment = e.Segment
	Where 
		o.StartDate >= @StartDate 
		and a.IronOfferCyclesID is null
		and os.PartnerID = @RetailerID;

	/******************************************************************************
	Load nFI control group members into nFI.relational.controlgroupmembers (for In Programme)
	******************************************************************************/

	-- Load new ControlGroupIDs

	If object_id('tempdb..#SecondaryNewControlGroupIDs_nFI') is not null drop table #SecondaryNewControlGroupIDs_nFI;

	Select
		o.Segment
		, Case o.Segment
			When 'A' then 7
			When 'L' then 8
			When 'S' then 9
			when 'SR' then 10
			when 'SG' then 11
		Else NULL
		END
		AS ShopperSegmentTypeID
		, max(t.ControlGroupID) as LastControlGroupID
	Into #SecondaryNewControlGroupIDs_nFI
	From nFI.Relational.SecondaryControlGroups t
	Inner join nFI.Relational.ironoffercycles i
		on i.ironoffercyclesid = t.ironoffercyclesid
	Inner join Warehouse.Staging.ControlSetup_OffersSegment_Secondary o 
		on o.IronOfferID = i.ironofferid 
		and o.PublisherType = 'nFI'
	Inner join nfi.Relational.IronOffer io
		on io.id = o.IronOfferID
	Inner join nfi.Relational.OfferCycles oc 
		on oc.OfferCyclesID = i.offercyclesid
	Where
		oc.startdate >= @StartDate
		and o.PartnerID = @RetailerID
	Group by
			o.Segment;

	-- Insert members into nFI.Relational.controlgroupmembers with the new ControlGroupIDs

	Insert into nFI.Relational.controlgroupmembers
	Select distinct
		cid.LastControlGroupID as ControlGroupID
		, t.FanID
	From #Control_Full t
	Inner join #SecondaryNewControlGroupIDs_nFI cid
		on t.CurrentSegment = cid.ShopperSegmentTypeID
	Where not exists (
		Select NULL From nFI.Relational.controlgroupmembers d
			Where cid.LastControlGroupID = d.controlgroupid
	);

	/******************************************************************************
	Load nFI control group members counts
	******************************************************************************/

	If object_id('tempdb..#NewControlGroupIDs_nFI') is not null drop table #NewControlGroupIDs_nFI;

	Select distinct
		ControlGroupID
	Into #NewControlGroupIDs_nFI
	From nFI.Relational.SecondaryControlGroups s
	Where not exists (
		Select null from nFI.Relational.ControlGroupMember_Counts c
		Where s.ControlGroupID = c.ControlGroupID
	);

	WITH Counts AS (
		Select 
			m.ControlGroupID
			, Count(*) as NumberofFanIDs
		From nFI.Relational.controlgroupmembers m
		Inner join #NewControlGroupIDs_nFI n
			on m.controlgroupid = n.ControlGroupID
		Group by 
			m.ControlGroupID
	)	
	Insert into nFI.Relational.ControlGroupMember_Counts (PartnerID, SuperSegmentID, ControlGroupID, StartDate, NumberofFanIDs)
	Select Distinct
		Max(Coalesce(pa.AlternatePartnerID, o.PartnerID)) over (partition by c.controlgroupid) as PartnerID	-- Shouldn't need the window function, but to ensure there is no duplication 
		, Max(s.SegmentID) over (partition by c.controlgroupid) as SuperSegmentID
		, c.controlgroupid
		, @StartDate as StartDate
		, c.NumberofFanIDs
	From Counts c
	Inner join nFI.Relational.SecondaryControlGroups sg
		on c.controlgroupid = sg.ControlGroupID
	Inner join nFI.Relational.ironoffercycles ioc
		on sg.IronOfferCyclesID = ioc.ironoffercyclesid
	Left join nFI.Relational.IronOffer o
		on ioc.ironofferid = o.ID
	Left join Warehouse.Relational.IronOfferSegment s
		on o.ID = s.IronOfferID
	Left join #PartnerAlternate pa
		on o.PartnerID = pa.PartnerID
	WHERE s.SegmentID IS NOT NULL
	;

	/******************************************************************************
	Load Warehouse ControlGroupIDs into Warehouse.Relational.SecondaryControlGroups (for In Programme)
	******************************************************************************/

	-- Create table of ControlGroupID updates for cases where a ControlGroupID already exists for that retailer segment in that cycle 

	If object_id('tempdb..#ExistingControlUpdates_Warehouse') is not null drop table #ExistingControlUpdates_Warehouse;

	Select
	x.PartnerID
	, x.Segment	
	, x.ControlGroupID 
	Into #ExistingControlUpdates_Warehouse
	From (
		Select distinct
			s.PartnerID
			, s.Segment	
			, scg.ControlGroupID
			, Dense_rank() OVER (Partition by s.PartnerID, s.Segment Order by scg.ControlGroupID ASC) as ControlGroupIDRank
		From Warehouse.Staging.ControlSetup_OffersSegment_Secondary s
		Inner join Warehouse.Relational.IronOffer_References ior
			on s.IronOfferID = ior.IronOfferID
		Inner join Warehouse.Relational.IronOfferCycles ioc
			on ior.ironoffercyclesid = ioc.ironoffercyclesid
		Inner join Warehouse.Relational.SecondaryControlGroups scg
			on ior.ironoffercyclesid = scg.ironoffercyclesid
		Inner join Warehouse.Relational.OfferCycles cyc
			on ioc.offercyclesid = cyc.OfferCyclesID
			and CAST(s.StartDate as date) = Cast(cyc.StartDate as date)
			and CAST(s.EndDate as date) = Cast(cyc.EndDate as date)
		Where
			s.PublisherType = 'Warehouse'
			and s.PartnerID = @RetailerID
	) x 
	Where x.ControlGroupIDRank = 1;

	-- Load ControlGroupIDs

	Declare @MaxID3 int = (Select Max(ControlGroupID) From Warehouse.Relational.controlgroupmembers);
	Declare @MaxID4 int = (Select Max(ControlGroupID) From Warehouse.Relational.ironoffercycles);
	
	If @MaxID4 > @MaxID3 set @MaxID3 = @MaxID4

	Insert into Warehouse.Relational.SecondaryControlGroups
	Select
		i.IronOfferCyclesID
		, COALESCE (
			e.ControlGroupID
			, Case
				when os.Segment = 'A' then @MaxID3+1
				when os.Segment = 'L' then @MaxID3+2
				when os.Segment = 'S' then @MaxID3+3
				when os.Segment = 'SR' then @MaxID1+4
				when os.Segment = 'SG' then @MaxID1+5
			Else 0 End
		) as ControlGroupID
		, 1 as ControlGroupTypeID
	From Warehouse.Relational.ironoffercycles i
	Inner join warehouse.relational.OfferCycles o
		on i.offercyclesid = o.OfferCyclesID
	Left join Warehouse.Relational.SecondaryControlGroups a
		on i.ironoffercyclesid = a.IronOfferCyclesID
	Inner join Warehouse.Staging.ControlSetup_OffersSegment_Secondary os
		on os.ironofferid = i.ironofferid
		and os.PublisherType = 'Warehouse'
	Left join #ExistingControlUpdates_Warehouse e
		on os.PartnerID = e.PartnerID
		and os.Segment = e.Segment
	Where
		o.StartDate >= @StartDate
		and a.IronOfferCyclesID is null
		and os.PartnerID = @RetailerID;

	/******************************************************************************
	Load Warehouse control group members into Warehouse.relational.controlgroupmembers (for In Programme)
	******************************************************************************/

	-- Load new ControlGroupIDs

	If object_id('tempdb..#SecondaryNewControlGroupIDs_Warehouse') is not null drop table #SecondaryNewControlGroupIDs_Warehouse;

	Select
		o.Segment
		, Case o.Segment
			When 'A' then 7
			When 'L' then 8
			When 'S' then 9
			when 'SR' then 10
			when 'SG' then 11
		Else NULL
		END
		AS ShopperSegmentTypeID
		, max(t.ControlGroupID) as LastControlGroupID
	Into #SecondaryNewControlGroupIDs_Warehouse
	From Warehouse.Relational.SecondaryControlGroups t
	Inner join Warehouse.Relational.ironoffercycles i
		on i.ironoffercyclesid = t.ironoffercyclesid
	Inner join Warehouse.Staging.ControlSetup_OffersSegment_Secondary o 
		on o.IronOfferID = i.ironofferid 
		and o.PublisherType = 'Warehouse'
	Inner join Warehouse.Relational.IronOffer io
		on io.IronOfferID = o.IronOfferID
	Inner join Warehouse.Relational.OfferCycles oc 
		on oc.OfferCyclesID = i.offercyclesid
	Where
		oc.startdate >= @StartDate
		and o.PartnerID = @RetailerID
	Group by
			o.Segment;

	-- Insert members into Warehouse.Relational.controlgroupmembers with the new ControlGroupIDs

	Insert into Warehouse.Relational.controlgroupmembers
	Select distinct
		cid.LastControlGroupID as ControlGroupID
		, t.FanID
	From #Control_Full t
	Inner join #SecondaryNewControlGroupIDs_Warehouse cid
		on t.CurrentSegment = cid.ShopperSegmentTypeID
	Where not exists (
		Select NULL From Warehouse.Relational.controlgroupmembers d
			Where cid.LastControlGroupID = d.controlgroupid
	);

	/******************************************************************************
	Load Warehouse control group members counts
	******************************************************************************/

	If object_id('tempdb..#NewControlGroupIDs_Warehouse') is not null drop table #NewControlGroupIDs_Warehouse;

	Select distinct
		ControlGroupID
	Into #NewControlGroupIDs_Warehouse
	From Warehouse.Relational.SecondaryControlGroups s
	Where not exists (
		Select null from Warehouse.Relational.ControlGroupMember_Counts c
		Where s.ControlGroupID = c.ControlGroupID
	);

	WITH Counts AS (
		Select 
			m.ControlGroupID
			, Count(*) as NumberofFanIDs
		From Warehouse.Relational.controlgroupmembers m
		Inner join #NewControlGroupIDs_Warehouse n
			on m.controlgroupid = n.ControlGroupID
		Group by 
			m.ControlGroupID
	)	
	Insert into Warehouse.Relational.ControlGroupMember_Counts (PartnerID, SuperSegmentID, ControlGroupID, StartDate, NumberofFanIDs)
	Select Distinct
		Max(Coalesce(pa.AlternatePartnerID, o.PartnerID)) over (partition by c.controlgroupid) as PartnerID	-- Shouldn't need the window function, but to ensure there is no duplication 
		, Max(s.SegmentID) over (partition by c.controlgroupid) as SuperSegmentID
		, c.controlgroupid
		, @StartDate as StartDate
		, c.NumberofFanIDs
	From Counts c
	Inner join Warehouse.Relational.SecondaryControlGroups sg
		on c.controlgroupid = sg.ControlGroupID
	Inner join Warehouse.Relational.ironoffercycles ioc
		on sg.IronOfferCyclesID = ioc.ironoffercyclesid
	Left join Warehouse.Relational.IronOffer o
		on ioc.ironofferid = o.IronOfferID
	Left join Warehouse.Relational.IronOfferSegment s
		on o.IronOfferID = s.IronOfferID
	Left join #PartnerAlternate pa
		on o.PartnerID = pa.PartnerID
	WHERE s.SegmentID IS NOT NULL;

END