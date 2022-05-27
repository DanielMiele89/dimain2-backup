/******************************************************************************
Author: Jason Shipp
Created: 08/03/2018
Purpose: 
	- Load nFI offers for which to setup control members for
	- Add entries to nFI.Relational.OfferCycles table
	- Load offer segments into Warehouse.Staging.ControlSetup_OffersSegment_nFI table
	- Load validation of segment types assigned to each offer
	- @IronOfferIDList is a list of IronOffers, separated by commas or new lines, all in one string
	 
------------------------------------------------------------------------------
Modification History

Jason Shipp 28/08/2018
	- Used Warehouse.Relational.IronOfferSegment table as source of segment codes instead of applying string searches to IronOfferNames

Jason Shipp 22/04/2020
	- Parameterised query to add control over whether to run for all retailers or just retailers requiring flash reports

Jason Shipp 04/05/2020
	- Added parameterisation control whether to include a bespoke list of IronOfferIDs

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_nFINonAAM_Load_Segments] (@OnlyRunForFlashReportRetailers bit,  @IronOfferIDList varchar(max))
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- For testing
	--DECLARE @OnlyRunForFlashReportRetailers bit = 0;
	--DECLARE @IronOfferIDList varchar(max) = '';

	-- Remove new lines from Iron Offer list (if applicable) and spaces after commas
	SET @IronOfferIDList = REPLACE(REPLACE(@IronOfferIDList, CHAR(13) + CHAR(10), ','), ', ', ',');

	/******************************************************************************
	Load Flash Report retailer PartnerIDs
	******************************************************************************/

	IF OBJECT_ID('tempdb..#FlashRetailerPartnerIDs') IS NOT NULL DROP TABLE #FlashRetailerPartnerIDs;

	SELECT PartnerID
	INTO #FlashRetailerPartnerIDs	
	FROM ( 
			SELECT r.RetailerID AS PartnerID FROM Warehouse.Staging.ControlSetup_FlashReportRetailers r
			UNION 
			SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_FlashReportRetailers r
			INNER JOIN Warehouse.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
			UNION
			SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_FlashReportRetailers r
			INNER JOIN nFI.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
		) x;

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
	From Warehouse.Staging.ControlSetup_Cycle_Dates d;

	/******************************************************************************
	Load Iron Offers active during period that are not already in nFI.Relational.ironoffercycles
	******************************************************************************/

	IF OBJECT_ID('tempdb..#OffersnFI') IS NOT NULL DROP TABLE #OffersnFI;

	Select
		x.IronOfferID
		, x.IronOfferName
		, x.PartnerID
		, x.PartnerName
		, x.ClubID
		, x.StartDate,
		x.EndDate
	Into #OffersnFI
	From (
		Select
			i.ID as IronOfferID
			, i.IronOfferName
			, i.PartnerID
			, p.PartnerName
			, i.ClubID
			, Case
				When i.StartDate > (Select StartDate From #Dates) then i.StartDate
				Else (Select StartDate From #Dates)
			End as StartDate
			, Case
				When i.EndDate < (Select EndDate From #Dates) then i.EndDate
				Else (Select EndDate From #Dates)
			End as EndDate
		From nFI.relational.IronOffer as i
		Inner join nfi.Relational.club as c
			on	i.ClubID = c.ClubID
		Inner join nfi.relational.partner as p
			on	i.PartnerID = p.PartnerID
		Left Outer join warehouse.Relational.nFI_Partner_Deals as q
			ON	p.PartnerID = Q.PartnerID AND
				ManagedBy <> 1 and
				i.ClubID = q.ClubID
		Where i.StartDate <= (Select EndDate From #Dates)
			and (i.EndDate > (Select StartDate From #Dates) or i.EndDate is null)
			and	IssignedOff = 1
			and IronOfferName NOT like 'Spare%' -- Exclude spare offers
			and IsAppliedToAllMembers = 0
			and (i.PartnerID in (SELECT PartnerID FROM #FlashRetailerPartnerIDs) OR @OnlyRunForFlashReportRetailers = 0)
			and ( -- Control whether to include a bespoke list of IronOfferIDs
				len(@IronOfferIDList) = 0 
				or len(@IronOfferIDList) is null 
				or (len(@IronOfferIDList) >0 and charindex(',' + cast(i.ID AS varchar) + ',', ',' + @IronOfferIDList + ',') > 0)
			)
		) x;

	CREATE CLUSTERED INDEX CIX_OfferDate ON #OffersnFI (IronOfferID, StartDate, EndDate)
	
	/******************************************************************************
	Load active offers that have members
	******************************************************************************/

	IF OBJECT_ID('tempdb..#OffersWithMembersnFI') IS NOT NULL DROP TABLE #OffersWithMembersnFI
	SELECT	o.IronOfferID
		,	o.IronOfferName
		,	o.StartDate
		,	o.EndDate
		,	o.PartnerID
		,	o.ClubID
		,	o.PartnerName
	INTO #OffersWithMembersnFI
	FROM #OffersnFI o
	WHERE EXISTS (	SELECT 1
					FROM [SLC_Report].[dbo].[IronOfferMember] iom
					WHERE o.IronOfferID = iom.IronOfferID
					AND iom.StartDate <= o.EndDate
					AND iom.EndDate >= o.StartDate)
	GROUP BY	o.IronOfferID
			,	o.IronOfferName
			,	o.StartDate
			,	o.EndDate
			,	o.PartnerID
			,	o.ClubID
			,	o.PartnerName

	UNION

	SELECT	o.IronOfferID
		,	o.IronOfferName
		,	o.StartDate
		,	o.EndDate
		,	o.PartnerID
		,	o.ClubID
		,	o.PartnerName
	FROM #OffersnFI o
	WHERE EXISTS (	SELECT 1
					FROM [SLC_Report].[dbo].[IronOfferMember] iom
					WHERE o.IronOfferID = iom.IronOfferID
					AND iom.StartDate <= o.EndDate
					AND iom.EndDate IS NULL)
	GROUP BY	o.IronOfferID
			,	o.IronOfferName
			,	o.StartDate
			,	o.EndDate
			,	o.PartnerID
			,	o.ClubID
			,	o.PartnerName

	UNION

	-- Bespoke logic for Morrisons Universal offers whose members will be loaded as members fall out of their original segments
	SELECT	o.IronOfferID
		,	o.IronOfferName
		,	o.StartDate
		,	o.EndDate
		,	o.PartnerID
		,	o.ClubID
		,	o.PartnerName
	From #OffersnFI as o
	Where 
		o.PartnerID = 4263 
		and o.IronOfferName like '%Universal%';

	/******************************************************************************
	Add entries to OfferCycles table (if new dates)
	******************************************************************************/

	Insert into nFI.relational.OfferCycles
	Select Distinct
		d.StartDate
		, d.Enddate 
	From #OffersWithMembersnFI d
	Left join nFI.relational.OfferCycles as oc
		on	d.StartDate = oc.StartDate
		and d.EndDate = oc.EndDate
	Where
		oc.OfferCyclesID is null;

	/******************************************************************************
	- Assign Segment type to each offer
	- Load results into Warehouse.Staging.ControlSetup_OffersSegment_nFI table

	Create table for storing results:

	CREATE TABLE Warehouse.Staging.ControlSetup_OffersSegment_nFI
		(IronOfferID INT
		, IronOfferName NVARCHAR(200)
		, StartDate DATETIME
		, EndDate DATETIME
		, PartnerID INT
		, ClubID INT
		, PartnerName VARCHAR(100)
		, Segment VARCHAR(50)
		, CONSTRAINT PK_ControlSetup_OffersSegment_nFI PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)
		)
	******************************************************************************/
	 
	Truncate table Warehouse.Staging.ControlSetup_OffersSegment_nFI;

	Insert into Warehouse.Staging.ControlSetup_OffersSegment_nFI
		(IronOfferID
		, IronOfferName
		, StartDate
		, EndDate
		, PartnerID
		, ClubID
		, PartnerName
		, Segment
		)		
	Select 
		o.IronOfferID
		, o.IronOfferName
		, o.StartDate
		, o.EndDate
		, o.PartnerID
		, o.ClubID
		, o.PartnerName
		, s.SegmentCode as Segment
	From #OffersWithMembersnFI o
	Left join Warehouse.Relational.IronOfferSegment s
		on o.IronOfferID = s.IronOfferID;

	-- Delete CTEM Iron Offer

	Delete from Warehouse.Staging.ControlSetup_OffersSegment_nFI
	Where 
		ironofferid = 12071;

	--	In the case that a IronOFfer has had a change in it's start date or end date since the last crontrol group run, update the OfferCyclesID in [nFI].[Relational].[ironoffercycles]
	--	to prevent a second control group being sest up for the same retailer / segment

	UPDATE ioc
	SET ioc.OfferCyclesID = oc2.OfferCyclesID
	FROM [Warehouse].[Staging].[ControlSetup_OffersSegment_nFI] os
	INNER JOIN [nFI].[Relational].[ironoffercycles] ioc
		ON os.IronOfferID = ioc.IronOfferID
	INNER JOIN [nfi].[Relational].[OfferCycles] oc
		ON ioc.OfferCyclesID = oc.OfferCyclesID
	INNER JOIN [Staging].[ControlSetup_Cycle_Dates] cd
		ON oc.StartDate BETWEEN cd.StartDate AND cd.EndDate
	INNER JOIN [nFI].[Relational].[OfferCycles] oc2
		ON os.StartDate = CONVERT(DATE, oc2.StartDate)
		AND os.EndDate = CONVERT(DATE, oc2.EndDate)
	WHERE 1 = 1
	AND oc.OfferCyclesID != oc2.OfferCyclesID



	/******************************************************************************
	CHECK POINT: If any entries are blank, check offer name follows naming convention

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Segments
		(PublisherType VARCHAR(50)
		, IronOfferID INT
		, IronOfferName NVARCHAR(200)
		, StartDate DATE
		, EndDate DATE
		, PartnerID INT
		, ClubID INT
		, PartnerName VARCHAR(200)
		, Segment VARCHAR(10)
		, CONSTRAINT PK_ControlSetup_Validation_nFINonAAM_Segments PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)  
		)
	******************************************************************************/

	-- Load errors

	Truncate table Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Segments;

	Insert into Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Segments
		(PublisherType  
		, IronOfferID
		, IronOfferName
		, StartDate
		, EndDate
		, PartnerID
		, ClubID
		, PartnerName
		, Segment
		)
	Select
		'nFI' as PublisherType  
		, d.IronOfferID
		, d.IronOfferName
		, d.StartDate
		, d.EndDate
		, d.PartnerID
		, d.ClubID
		, d.PartnerName
		, d.Segment
	From Warehouse.Staging.ControlSetup_OffersSegment_nFI d
	Where (Segment = '' or Segment is null);

END



