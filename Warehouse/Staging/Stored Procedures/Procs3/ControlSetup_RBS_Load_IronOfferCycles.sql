/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Assign Warehouse partner ControlGroupIDs
	- Add entries to Warehouse.Relational.ironoffercycles table
	- Load validation of entries added to Warehouse.Relational.ironoffercycles

Note: 
	- The Universal ControlGroupID will be the minimum ControlGroupID associated with the OfferCyclesIDs being setup
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 11/07/2018
	- Added logic to update ControlGroupIDs for cases where a ControlGroupID already exists for that retailer segment in that cycle
******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_RBS_Load_IronOfferCycles]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Assign Partner ControlGroupIDs
	******************************************************************************/

	-- Declare variables

	Declare @MaxID int;
	Declare @MaxID2 int;
	Declare @Universal int;
	Declare @MaxRowNo int;

	/******************************************************************************
	Load partner alternates
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;

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

	/******************************************************************************
	Create table for storing Universal ControlGroupID:

	CREATE TABLE Warehouse.Staging.ControlSetup_UniversalOffer_Warehouse
		(UniversalControlGroupID INT
		, CONSTRAINT PK_ControlSetup_UniversalOffer_Warehouse PRIMARY KEY CLUSTERED (UniversalControlGroupID)
		)
	******************************************************************************/

	-- Clear Staging.ControlSetup_UniversalOffer_Warehouse table

	Truncate table Warehouse.Staging.ControlSetup_UniversalOffer_Warehouse;

	/******************************************************************************
	Load Campaign Cycle dates
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;
	
	Select
		MAX(d.StartDate) AS StartDate
		, DATEADD(SECOND, -1
			, (DATEADD(day, 1
				, (CAST(MAX(d.EndDate) AS DATETIME))
			))
		) AS EndDate
	Into #Dates
	From [Warehouse].[Staging].[ControlSetup_Cycle_Dates] d;
	
	/******************************************************************************
	Load Iron Offers active during period that are not already in Warehouse.Relational.ironoffercycles
	******************************************************************************/

		DECLARE @StartDate DATETIME
			,	@EndDate DATETIME
		
		SELECT	@StartDate = StartDate
			,	@EndDate = EndDate
		FROM #Dates

		;WITH
		ExistingUniversal AS (	SELECT	iof.IronOfferID
									,	iof.IronOfferName
									,	iof.PartnerID
									,	ios.SegmentCode
									,	CASE
											WHEN @StartDate < iof.StartDate THEN iof.StartDate
											ELSE @StartDate
										END AS StartDate
									,	CASE
											WHEN iof.EndDate < @EndDate THEN iof.EndDate
											ELSE @EndDate
										END AS EndDate
								FROM [Warehouse].[Relational].[IronOffer] iof
								INNER JOIN [Warehouse].[Relational].[IronOfferSegment] ios
									ON iof.IronOfferID = ios.IronOfferID
									AND ios.SegmentCode = 'B'
								WHERE iof.StartDate <= @EndDate
								AND (@StartDate < iof.EndDate OR iof.EndDate is null)
								AND	iof.IssignedOff = 1
								AND iof.PartnerID NOT IN (4497, 4498)	-- Exclude "Credit Supermarket 1%" and "Spend 0.5%"
								AND iof.IronOfferName NOT LIKE 'Spare%')
		
		SELECT @Universal = MIN(ControlGroupID)
		FROM ExistingUniversal eu		
		INNER JOIN [Relational].[OfferCycles] oc
			ON CONVERT(DATE, eu.StartDate) = CONVERT(DATE, oc.StartDate)
			AND CONVERT(DATE, eu.EndDate) = CONVERT(DATE, oc.EndDate)
		INNER JOIN [Relational].[ironoffercycles] ioc
			ON eu.IronOfferID = ioc.ironofferid
			AND oc.OfferCyclesID = ioc.offercyclesid


	-- ControlGroupID assignment

	Set @MaxID = (Select Max(ControlGroupID) From Warehouse.relational.ironoffercycles);
	Set @MaxID2 = (Select Max(ControlGroupID) From Warehouse.relational.controlgroupmembers);

	IF @MaxID > @MaxID2
	Begin
		Set @MaxID2 = @MaxID
	End;

	Set @Universal = COALESCE(@Universal, @MaxID2+1);


	INSERT INTO Warehouse.Staging.ControlSetup_UniversalOffer_Warehouse (UniversalControlGroupID) SELECT @Universal; -- Store Universal ControlGroupID for later Use
	Set @MaxRowNo = @MaxID2+1;

	Truncate Table Warehouse.Staging.PartnerControlgroupIDs_RBSG;

	Insert Into	Warehouse.Staging.PartnerControlgroupIDs_RBSG
	Select	
		PartnerID
		, Segment
		, DENSE_RANK() OVER(ORDER BY PartnerID,Segment ASC)+@MaxRowNo -- Used as ControlGroupID. Duplicated for partner-segments with same retailerID
		, StartDate
		, EndDate
	From (
		Select Distinct
			Coalesce(pa.AlternatePartnerID, a.PartnerID) as PartnerID
			, a.Segment
		--	, s.Segment
			, a.StartDate
			, a.EndDate
		from Warehouse.Staging.ControlSetup_OffersSegment_Warehouse a
		Left join #PartnerAlternate pa 
			on a.PartnerID = pa.PartnerID
		left join Warehouse.Staging.PartnerControlgroupIDs_RBSG as c
			on a.partnerid = c.PartnerID
		, (Select distinct Segment from Warehouse.Staging.ControlSetup_OffersSegment_Warehouse) s -- Cross join
		Where c.PartnerID is null
	) as a;

	-- Use same RowNo (to be used as ControlGroupID) for different PartnerIDs that can be associated to the same RetailerID on Control Group table

	Update cls
	Set RowNo = cls2.RowNo
	From Warehouse.Staging.PartnerControlgroupIDs_RBSG as cls
	Inner join warehouse.iron.PrimaryRetailerIdentification as a
		on cls.PartnerID = a.PartnerID
	Inner join Warehouse.Staging.PartnerControlgroupIDs_RBSG as cls2
		on cls2.PartnerID = a.PrimaryPartnerID
		and cls2.Segment = cls.Segment
		and cls2.startDate = cls.StartDate
		and CLS2.EndDate  = CLS.Enddate
	Where 
		PrimaryPartnerID is not null;

	-- Update RowNo (to be used as ControlGroupID) for cases where a ControlGroupID already exists for that retailer segment in that cycle 

	IF OBJECT_ID('tempdb..#ExistingControlUpdates') IS NOT NULL DROP TABLE #ExistingControlUpdates;
	SELECT	os.PartnerID
		,	os.Segment	
		,	os.ControlGroupID 
	INTO #ExistingControlUpdates
	From (	SELECT	DISTINCT
					COALESCE(pa.AlternatePartnerID, os.PartnerID) AS PartnerID
				,	os.Segment	
				,	ioc.ControlGroupID
				,	DENSE_RANK() OVER (PARTITION BY COALESCE(pa.AlternatePartnerID, os.PartnerID), os.Segment ORDER BY ioc.ControlGroupID ASC) AS ControlGroupIDRank
			FROM [Staging].[ControlSetup_OffersSegment_Warehouse] os
			LEFT JOIN #PartnerAlternate pa 
				ON os.PartnerID = pa.PartnerID
			INNER JOIN [Relational].[OfferCycles] oc
				ON CONVERT(DATE, os.StartDate) = CONVERT(DATE, oc.StartDate)
				AND CONVERT(DATE, os.EndDate) = CONVERT(DATE, oc.EndDate)
			INNER JOIN [Relational].[ironoffercycles] ioc
				ON os.IronOfferID = ioc.ironofferid
				AND oc.OfferCyclesID = ioc.offercyclesid) os
	Where os.ControlGroupIDRank = 1;

	Update cls
	Set RowNo = e.controlgroupid
	FROM [Warehouse].[Staging].[PartnerControlgroupIDs_RBSG] cls
	Inner join #ExistingControlUpdates e
		on cls.PartnerID = e.PartnerID
		and cls.Segment = e.Segment;

	/******************************************************************************
	Add new entries to Warehouse.Relational.ironoffercycles
	******************************************************************************/

	Insert into Warehouse.Relational.ironoffercycles
	Select	a.IronOfferID
		,	oc.OfferCyclesID
		,	Case
				When a.Segment = 'B' then (Select UniversalControlGroupID from Warehouse.Staging.ControlSetup_UniversalOffer_Warehouse)
				Else PG.RowNo
			End as ControlGroupID
		,	NULL
	From Warehouse.Staging.ControlSetup_OffersSegment_Warehouse a
	Left join #PartnerAlternate pa 
		on a.PartnerID = pa.PartnerID
	Left join Warehouse.Staging.PartnerControlgroupIDs_RBSG PG
		on Coalesce(pa.AlternatePartnerID, a.PartnerID) = PG.PartnerID
		and a.Segment = PG.Segment
		and a.StartDate = PG.StartDate
		and a.EndDate = PG.EndDate
	Inner join Warehouse.Relational.OfferCycles oc
		on a.StartDate = oc.StartDate
		and a.EndDate = oc.EndDate
	Where not exists
		(Select null from Warehouse.Relational.ironoffercycles d
		WHERE 
			a.IronOfferID = d.ironofferid
			and oc.OfferCyclesID = d.offercyclesid
		);
		
	/******************************************************************************
	CHECK POINT: Validate entries added to Relational.ironoffercycles

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_RBS_IronOfferCycles
		(ID INT IDENTITY (1,1)
		, PublisherType VARCHAR(50)
		, PartnerID INT
		, Segment VARCHAR(10)
		, IronOfferID INT
		, IronOfferName NVARCHAR(200)
		, ControlGroupID INT
		, Error VARCHAR(200)
		, CONSTRAINT PK_ControlSetup_Validation_RBS_IronOfferCycles PRIMARY KEY CLUSTERED (ID)  
		)
	******************************************************************************/

	-- Check base and launch offers all have the same ControlGroupID (across retailer)
	-- Check ALS-Retailer combinations have unique ControlGroupIDs
	-- Check row count matches rows in Warehouse.Staging.ControlSetup_OffersSegment_Warehouse table

	-- Load new ironoffercycles data

	IF OBJECT_ID ('tempdb..#IOCCheckData') IS NOT NULL DROP TABLE #IOCCheckData;

	Select
		'Warehouse' as PublisherType
		, i.IronOfferName
		, i.IronOfferID
		, ioc.controlgroupid
		, a.Segment
		, a.RowNo
		, ioc.ironoffercyclesid
		, COALESCE(pa.AlternatePartnerID, i.PartnerID) AS PartnerID
		, oc.startdate
		, oc.enddate
	Into #IOCCheckData
	From Warehouse.relational.ironoffercycles ioc
	Inner join Warehouse.relational.ironoffer i
		on ioc.ironofferid = i.IronOfferID
	Left join Warehouse.Staging.PartnerControlgroupIDs_RBSG a
		on ioc.ControlGroupID = a.RowNo
	Inner join Warehouse.Relational.OfferCycles oc
		on ioc.offercyclesid = oc.OfferCyclesID
	Left join #PartnerAlternate pa
		ON i.PartnerID = pa.PartnerID
	Where
		oc.StartDate <= (Select EndDate From Warehouse.Staging.ControlSetup_Cycle_Dates)
		and oc.EndDate > (Select StartDate From Warehouse.Staging.ControlSetup_Cycle_Dates)
	Order by 
		ioc.ironoffercyclesid desc
		,Segment
		, controlgroupid;
	
	-- Load retailer segments associated with more than 1 control group

	IF OBJECT_ID ('tempdb..#DiffConGroups') IS NOT NULL DROP TABLE #DiffConGroups;

	Select 
		d.PublisherType
		, d.PartnerID
		, seg.Segment
		, Count(distinct(isnull(d.controlgroupid, 0))) as UniqueControlGroups
		, 'different control groups for base offers' as Error
	Into #DiffConGroups
	From #IOCCheckData d
	Left join Warehouse.Staging.ControlSetup_OffersSegment_Warehouse seg
		on d.IronOfferID = seg.ironofferid
		and cast(d.StartDate as date) = cast(seg.StartDate as date)
		and cast(d.EndDate as date) = cast(seg.EndDate as date)
	Cross join (select max(UniversalControlGroupID) AS UniversalControlGroupID from Warehouse.Staging.ControlSetup_UniversalOffer_Warehouse) u
	Where
		(seg.Segment = 'B')
	Group by
		d.PublisherType
		, d.PartnerID
		, seg.Segment
	Having
		Count(distinct(d.controlgroupid)) >1

	Union all

	Select 
		d.PublisherType
		, d.PartnerID
		, seg.Segment
		, Count(distinct(isnull(d.controlgroupid, 0))) as UniqueControlGroups
		, 'different control groups per retailer ALS segment' as Error
	From #IOCCheckData d
	Left join Warehouse.Staging.ControlSetup_OffersSegment_Warehouse seg
		on d.IronOfferID = seg.ironofferid
		and cast(d.StartDate as date) = cast(seg.StartDate as date)
		and cast(d.EndDate as date) = cast(seg.EndDate as date)
	Where
		seg.Segment IN ('A', 'L', 'S')
	Group by
		d.PublisherType
		, d.PartnerID
		, seg.Segment
	Having
		Count(distinct(d.controlgroupid)) >1;

	-- Load errors

	Truncate table Warehouse.Staging.ControlSetup_Validation_RBS_IronOfferCycles;

	Insert into Warehouse.Staging.ControlSetup_Validation_RBS_IronOfferCycles
		(PublisherType
		, PartnerID
		, Segment
		, IronOfferID
		, IronOfferName
		, ControlGroupID
		, Error
		)
	Select 
		d.PublisherType
		, d.PartnerID
		, d.Segment
		, c.IronOfferID
		, c.IronOfferName
		, ioc.ControlGroupID	
		, d.Error		
	From #DiffConGroups d
	Left join #IOCCheckData c
		on d.PartnerID = c.PartnerID
		and (d.Segment = coalesce(c.Segment, 'B'))
	Left join Warehouse.Relational.ironoffercycles ioc -- Check for multiple control groups associated with the same Iron Offer in IronOfferReferences table
		ON c.IronOfferID = ioc.ironofferid
	Inner join Warehouse.Relational.OfferCycles oc
		on ioc.offercyclesid = oc.OfferCyclesID
	Where oc.StartDate >= (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates)
	
	Union all

	Select 
		'Warehouse' AS PublisherType
		, seg.PartnerID
		, seg.Segment
		, seg.IronOfferID
		, seg.IronOfferName
		, NULL as ControlGroupID	
		, 'no related entry in IronOfferCycles table' AS Error		
	From Warehouse.Staging.ControlSetup_OffersSegment_Warehouse seg
	Left join #IOCCheckData d
		on seg.ironofferid = d.IronOfferID
		and cast(seg.StartDate as date) = cast(d.StartDate as date)
		and cast(seg.EndDate as date) = cast(d.EndDate as date)
	Where
		d.IronOfferName is null; -- Check for no entries related to each retailer-segment in IronOfferCycles table
		
END