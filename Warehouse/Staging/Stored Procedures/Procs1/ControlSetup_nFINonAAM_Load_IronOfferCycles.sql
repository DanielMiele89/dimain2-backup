/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Assign nFI partner ControlGroupIDs
	- Add entries to nFI.Relational.ironoffercycles table
	- Load validation of entries added to nFI.Relational.ironoffercycles

Note: 
	- The Universal ControlGroupID will be the minimum ControlGroupID associated with the OfferCyclesIDs being setup
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 11/07/2018
	- Added logic to update ControlGroupIDs for cases where a ControlGroupID already exists for that retailer segment in that cycle
******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_nFINonAAM_Load_IronOfferCycles]
	
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

	If object_id('tempdb..#PartnerAlternate') is not null drop table #PartnerAlternate;

	SELECT distinct * 
	Into #PartnerAlternate
	FROM 
		(SELECT 
		PartnerID
		, AlternatePartnerID
		FROM Warehouse.APW.PartnerAlternate

		Union all  

		SELECT 
		PartnerID
		, AlternatePartnerID
		FROM nFI.APW.PartnerAlternate
		) x;

	/******************************************************************************
	Create table for storing Universal ControlGroupID:

	CREATE TABLE Warehouse.Staging.ControlSetup_UniversalOffer_nFI
		(UniversalControlGroupID INT
		, CONSTRAINT PK_ControlSetup_UniversalOffer_nFI PRIMARY KEY CLUSTERED (UniversalControlGroupID)
		)
	******************************************************************************/

	-- Clear Staging.ControlSetup_UniversalOffer_nFI table

	TRUNCATE TABLE Warehouse.Staging.ControlSetup_UniversalOffer_nFI;

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
		FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates] d;

		DECLARE @StartDate DATETIME
			,	@EndDate DATETIME
		
		SELECT	@StartDate = StartDate
			,	@EndDate = EndDate
		FROM #Dates

		;WITH
		ExistingUniversal AS (	SELECT	iof.ID AS IronOfferID
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
								FROM [nFI].[Relational].[IronOffer] iof
								INNER JOIN [Warehouse].[Relational].[IronOfferSegment] ios
									ON iof.ID = ios.IronOfferID
								WHERE iof.StartDate <= @EndDate
								AND (@StartDate < iof.EndDate OR iof.EndDate is null)
								AND	iof.IssignedOff = 1
								AND iof.PartnerID NOT IN (4497, 4498)	-- Exclude "Credit Supermarket 1%" and "Spend 0.5%"
								AND iof.IronOfferName NOT LIKE 'Spare%')
		
		SELECT @Universal = MIN(ControlGroupID)
		FROM ExistingUniversal eu		
		INNER JOIN [nFI].[Relational].[OfferCycles] oc
			ON CONVERT(DATE, eu.StartDate) = CONVERT(DATE, oc.StartDate)
			AND CONVERT(DATE, eu.EndDate) = CONVERT(DATE, oc.EndDate)
		INNER JOIN [nFI].[Relational].[ironoffercycles] ioc
			ON eu.IronOfferID = ioc.ironofferid
			AND oc.OfferCyclesID = ioc.offercyclesid

	-- ControlGroupID assignment

	Set @MaxID = (SELECT Max(ControlGroupID) FROM nfi.relational.ironoffercycles);
	Set @MaxID2 = (SELECT Max(ControlGroupID) FROM nfi.relational.controlgroupmembers);

	IF @MaxID > @MaxID2
	Begin
		Set @MaxID2 = @MaxID
	End; 
	Set @Universal = COALESCE(@Universal, @MaxID2+1);

	INSERT INTO Warehouse.Staging.ControlSetup_UniversalOffer_nFI (UniversalControlGroupID) SELECT @Universal; -- Store Universal ControlGroupID for later Use
	Set @MaxRowNo = @MaxID2+1;

	TRUNCATE TABLE Warehouse.Staging.PartnerControlgroupIDs; -- nFI table

	INSERT INTO	Warehouse.Staging.PartnerControlgroupIDs
	SELECT	PartnerID
		,	Segment
		,	DENSE_RANK() OVER(ORDER BY PartnerID,Segment ASC)+@MaxRowNo -- Used as ControlGroupID. Duplicated for partner-segments with same retailerID
		,	StartDate
		,	EndDate
	FROM (	SELECT	COALESCE(pa.AlternatePartnerID, a.PartnerID) AS PartnerID
				,	a.Segment
			--	,	s.Segment
				,	a.StartDate AS StartDate
				,	a.EndDate AS EndDate
			FROM Warehouse.Staging.ControlSetup_OffersSegment_nFI a
			LEFT JOIN #PartnerAlternate pa 
				ON a.PartnerID = pa.PartnerID
			CROSS JOIN (SELECT	DISTINCT
								Segment
						FROM Warehouse.Staging.ControlSetup_OffersSegment_nFI) s
			GROUP BY	COALESCE(pa.AlternatePartnerID, a.PartnerID)
					,	a.Segment
					,	a.StartDate
					,	a.EndDate) a;

	-- Update RowNo (to be used as ControlGroupID) for different PartnerIDs that can be associated to the same RetailerID on Control Group table

	Update cls
	Set RowNo = cls2.RowNo
	FROM Warehouse.Staging.PartnerControlgroupIDs cls
	Inner join warehouse.iron.PrimaryRetailerIdentification a
		on cls.PartnerID = a.PartnerID
	Inner join Warehouse.Staging.PartnerControlgroupIDs cls2
		on cls2.PartnerID = a.PrimaryPartnerID
		and cls2.Segment = cls.Segment
		and cls2.startDate = cls.StartDate
		and CLS2.EndDate  = CLS.Enddate
	Where
		PrimaryPartnerID is not null;

	-- Update RowNo (to be used as ControlGroupID) for cases where a ControlGroupID already exists for that retailer segment in that cycle 

	If object_id('tempdb..#ExistingControlUpdates') is not null drop table #ExistingControlUpdates;

	Select
	x.PartnerID
	, x.Segment	
	, x.ControlGroupID 
	Into #ExistingControlUpdates
	FROM (
		SELECT distinct
			Coalesce(pa.AlternatePartnerID, s.PartnerID) as PartnerID
			, s.Segment	
			, ioc.ControlGroupID
			, Dense_rank() OVER (Partition by Coalesce(pa.AlternatePartnerID, s.PartnerID), s.Segment Order by ioc.ControlGroupID ASC) as ControlGroupIDRank
		FROM Warehouse.Staging.ControlSetup_OffersSegment_nFI s
		LEFT JOIN #PartnerAlternate pa 
				on s.PartnerID = pa.PartnerID
		Inner join nFI.Relational.IronOffer_References ior
			on s.IronOfferID = ior.IronOfferID
		Inner join nFI.Relational.IronOfferCycles ioc
			on ior.ironoffercyclesid = ioc.ironoffercyclesid
		Inner join nFI.Relational.OfferCycles cyc
			on ioc.offercyclesid = cyc.OfferCyclesID
			and CAST(s.StartDate as date) = Cast(cyc.StartDate as date)
			and CAST(s.EndDate as date) = Cast(cyc.EndDate as date)
	) x
	Where x.ControlGroupIDRank = 1;

	Update cls
	Set RowNo = e.controlgroupid
	FROM Warehouse.Staging.PartnerControlgroupIDs cls
	Inner join #ExistingControlUpdates e
		on cls.PartnerID = e.PartnerID
		and cls.Segment = e.Segment;

	/******************************************************************************
	Add new entries to nFI.Relational.ironoffercycles
	******************************************************************************/

	INSERT INTO nfi.Relational.ironoffercycles
	Select	a.IronOfferID
		,	oc.OfferCyclesID
		,	Case
				When a.Segment = 'B' then (SELECT UniversalControlGroupID FROM Warehouse.Staging.ControlSetup_UniversalOffer_nFI)
				Else PG.RowNo
			End as ControlGroupID
		,	NULL
	FROM Warehouse.Staging.ControlSetup_OffersSegment_nFI a
	LEFT JOIN #PartnerAlternate pa 
		on a.PartnerID = pa.PartnerID
	LEFT JOIN Warehouse.Staging.PartnerControlgroupIDs PG
		on Coalesce(pa.AlternatePartnerID, a.PartnerID) = PG.PartnerID
		and a.Segment = PG.Segment
		and a.StartDate = PG.StartDate
		and a.EndDate = PG.EndDate
	INNER join nfi.Relational.OfferCycles oc
		on a.StartDate = oc.StartDate
		and a.EndDate = oc.EndDate
	Where not exists
		(SELECT null FROM nfi.Relational.ironoffercycles d
		WHERE 
			a.IronOfferID = d.ironofferid
			and oc.OfferCyclesID = d.offercyclesid
		);

	/******************************************************************************
	CHECK POINT: Validate entries added to Relational.ironoffercycles

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_nFINonAAM_IronOfferCycles
		(ID INT IDENTITY (1,1)
		, PublisherType VARCHAR(50)
		, PartnerID INT
		, Segment VARCHAR(10)
		, IronOfferID INT
		, IronOfferName NVARCHAR(200)
		, ControlGroupID INT
		, Error VARCHAR(200)
		, CONSTRAINT PK_ControlSetup_Validation_nFINonAAM_IronOfferCycles PRIMARY KEY CLUSTERED (ID)  
		)
	******************************************************************************/

	-- Check base and launch offers all have the same ControlGroupID (across retailer)
	-- Check ALS-Retailer combinations have unique ControlGroupIDs
	-- Check row count matches rows in Warehouse.Staging.ControlSetup_OffersSegment_nFI table

	-- Load new ironoffercycles data

	If object_id ('tempdb..#IOCCheckData') is not null drop table #IOCCheckData;

	Select
		'nFI' as PublisherType
		, i.IronOfferName
		, i.ID as IronOfferID
		, ioc.controlgroupid
		, a.Segment
		, a.RowNo
		, ioc.ironoffercyclesid
		, COALESCE(pa.AlternatePartnerID, i.PartnerID) AS PartnerID
		, oc.startdate
		, oc.enddate
	Into #IOCCheckData
	FROM nFI.relational.ironoffercycles ioc
	Inner join nFI.relational.ironoffer i
		on ioc.ironofferid = i.ID
	LEFT JOIN Warehouse.Staging.PartnerControlgroupIDs a
		on ioc.ControlGroupID = a.RowNo
	Inner join nFI.Relational.OfferCycles oc
		on ioc.offercyclesid = oc.OfferCyclesID
	LEFT JOIN #PartnerAlternate pa
		ON i.PartnerID = pa.PartnerID
	Where
		oc.StartDate <= (SELECT EndDate FROM Warehouse.Staging.ControlSetup_Cycle_Dates)
		and oc.EndDate > (SELECT StartDate FROM Warehouse.Staging.ControlSetup_Cycle_Dates)
	Order by 
		ioc.ironoffercyclesid desc
		,Segment
		, controlgroupid;
	
	-- Load retailer segments associated with more than 1 control group

	If object_id ('tempdb..#DiffConGroups') is not null drop table #DiffConGroups;

	SELECT 
		d.PublisherType
		, d.PartnerID
		, seg.Segment
		, Count(distinct(isnull(d.controlgroupid, 0))) as UniqueControlGroups
		, 'different control groups for base offers' as Error
	Into #DiffConGroups
	FROM #IOCCheckData d
	LEFT JOIN Warehouse.Staging.ControlSetup_OffersSegment_nFI seg
		on d.IronOfferID = seg.ironofferid
		and cast(d.StartDate as date) = cast(seg.StartDate as date)
		and cast(d.EndDate as date) = cast(seg.EndDate as date)
	Cross join (SELECT max(UniversalControlGroupID) AS UniversalControlGroupID FROM Warehouse.Staging.ControlSetup_UniversalOffer_nFI) u
	Where
		(seg.Segment = 'B')
	Group by
		d.PublisherType
		, d.PartnerID
		, seg.Segment
	Having
		Count(distinct(d.controlgroupid)) >1

	Union all

	SELECT 
		d.PublisherType
		, d.PartnerID
		, seg.Segment
		, Count(distinct(isnull(d.controlgroupid, 0))) as UniqueControlGroups
		, 'different control groups per retailer ALS segment' as Error
	FROM #IOCCheckData d
	LEFT JOIN Warehouse.Staging.ControlSetup_OffersSegment_nFI seg
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

	TRUNCATE TABLE Warehouse.Staging.ControlSetup_Validation_nFINonAAM_IronOfferCycles;

	INSERT INTO Warehouse.Staging.ControlSetup_Validation_nFINonAAM_IronOfferCycles
		(PublisherType
		, PartnerID
		, Segment
		, IronOfferID
		, IronOfferName
		, ControlGroupID
		, Error
		)
	SELECT 
		d.PublisherType
		, d.PartnerID
		, d.Segment
		, c.IronOfferID
		, c.IronOfferName
		, ioc.ControlGroupID	
		, d.Error		
	FROM #DiffConGroups d
	LEFT JOIN #IOCCheckData c
		on d.PartnerID = c.PartnerID
		and (d.Segment = coalesce(c.Segment, 'B'))
	LEFT JOIN nFI.Relational.ironoffercycles ioc -- Check for multiple control groups associated with the same Iron Offer in IronOfferReferences table
		ON c.IronOfferID = ioc.ironofferid
	Inner join nFI.Relational.OfferCycles oc
		on ioc.offercyclesid = oc.OfferCyclesID
	Where oc.StartDate >= (SELECT StartDate FROM Warehouse.Staging.ControlSetup_Cycle_Dates)
	
	Union all

	SELECT 
		'nFI' AS PublisherType
		, seg.PartnerID
		, seg.Segment
		, seg.IronOfferID
		, seg.IronOfferName
		, NULL as ControlGroupID	
		, 'no related entry in IronOfferCycles table' AS Error		
	FROM Warehouse.Staging.ControlSetup_OffersSegment_nFI seg
	LEFT JOIN #IOCCheckData d
		on seg.ironofferid = d.IronOfferID
		and cast(seg.StartDate as date) = cast(d.StartDate as date)
		and cast(seg.EndDate as date) = cast(d.EndDate as date)
	Where
		d.IronOfferName is null; -- Check for no entries related to each retailer-segment in IronOfferCycles table
						
END