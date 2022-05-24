/******************************************************************************
Author: Jason Shipp
Created: 08/03/2018
Purpose: 
	- Load Warehouse offers for which to setup control members for
	- Add entries to Warehouse.Relational.OfferCycles tables
	- Load offer segments into Warehouse.Staging.ControlSetup_OffersSegment_Warehouse table
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
CREATE PROCEDURE [Staging].[ControlSetup_RBS_Load_Segments] (@OnlyRunForFlashReportRetailers bit,  @IronOfferIDList varchar(max))
	
AS
BEGIN
	
	SET NOCOUNT ON;


	-- For testing
	--DECLARE @OnlyRunForFlashReportRetailers bit = 0;
	--DECLARE @IronOfferIDList varchar(max) = NULL;

	-- Remove new lines from Iron Offer list (if applicable) and spaces after commas
	SET @IronOfferIDList = REPLACE(REPLACE(@IronOfferIDList, CHAR(13) + CHAR(10), ','), ', ', ',');

	/******************************************************************************
	Load Flash Report retailer PartnerIDs
	******************************************************************************/

	If object_id('tempdb..#FlashRetailerPartnerIDs') is not null drop table #FlashRetailerPartnerIDs;

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

	If object_id('tempdb..#Dates') is not null drop table #Dates;
	
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
	Load Iron Offers active during period that are not already in Warehouse.Relational.ironoffercycles
	******************************************************************************/

	If object_id('tempdb..#OffersWarehouse') is not null drop table #OffersWarehouse;

	Select
		x.IronOfferID
		, x.IronOfferName
		, x.PartnerID
		, x.PartnerName
		, x.StartDate,
		x.EndDate
	Into #OffersWarehouse
	From (	
		Select
			i.IronOfferID
			, i.IronOfferName
			, i.PartnerID
			, p.PartnerName
			, Case
				When i.StartDate > (Select StartDate From #Dates) then i.StartDate
				Else (Select StartDate From #Dates)
			End as StartDate
			, Case
				When i.EndDate < (Select EndDate From #Dates) then i.EndDate
				Else (Select EndDate From #Dates)
			End as EndDate
		From Warehouse.relational.IronOffer as i
		Inner join Warehouse.relational.partner as p
			on	i.PartnerID = p.PartnerID
		Left Outer join warehouse.Relational.nFI_Partner_Deals as q
			ON	p.PartnerID = Q.PartnerID AND
				ManagedBy <> 1 and
				q.ClubID in (132,138)
		Where i.StartDate <= (Select EndDate From #Dates)
			and (i.EndDate > (Select StartDate From #Dates) or i.EndDate is null)
			and	IssignedOff = 1
			and i.PartnerID not in (4497, 4498) -- Exclude "Credit Supermarket 1%" and "Spend 0.5%"
			and IronOfferName not like 'Spare%'
			and (i.PartnerID in (SELECT PartnerID FROM #FlashRetailerPartnerIDs) OR @OnlyRunForFlashReportRetailers = 0)
			and ( -- Control whether to include a bespoke list of IronOfferIDs
				len(@IronOfferIDList) = 0 
				or len(@IronOfferIDList) is null 
				or (len(@IronOfferIDList) >0 and charindex(',' + cast(i.IronOfferID AS varchar) + ',', ',' + @IronOfferIDList + ',') > 0)
			)
		) x;

	CREATE CLUSTERED INDEX CIX_OfferDate ON #OffersWarehouse (IronOfferID, StartDate, EndDate)


	/******************************************************************************
	Load active offers that have members
	******************************************************************************/

	If object_id('tempdb..#OffersWithMembersWarehouse') is not null drop table #OffersWithMembersWarehouse;
	SELECT	ow.IronOfferID
		,	ow.IronOfferName
		,	ow.StartDate
		,	ow.EndDate
		,	ow.PartnerID
		,	ow.PartnerName
	INTO #OffersWithMembersWarehouse
	FROM #OffersWarehouse ow
	WHERE EXISTS (	SELECT	1
					FROM [SLC_Report].[dbo].[IronOfferMember] iom
					WHERE ow.IronOfferID = iom.IronOfferID
					AND iom.StartDate <= ow.EndDate
					AND iom.EndDate >= ow.StartDate)

	UNION 

	SELECT	ow.IronOfferID
		,	ow.IronOfferName
		,	ow.StartDate
		,	ow.EndDate
		,	ow.PartnerID
		,	ow.PartnerName
	FROM #OffersWarehouse ow
	WHERE EXISTS (	SELECT	1
					FROM [SLC_Report].[dbo].[IronOfferMember] iom
					WHERE ow.IronOfferID = iom.IronOfferID
					AND iom.StartDate <= ow.EndDate
					AND iom.EndDate IS NULL)

	UNION 

	-- Bespoke logic for Morrisons Universal offers whose members will be loaded as members fall out of their original segments
	SELECT	ow.IronOfferID
		,	ow.IronOfferName
		,	ow.StartDate
		,	ow.EndDate
		,	ow.PartnerID
		,	ow.PartnerName
	From #OffersWarehouse ow
	WHERE ow.PartnerID = 4263 
	AND ow.IronOfferName LIKE '%Universal%';



	/******************************************************************************
	Add entries to OfferCycles table (if new dates)
	******************************************************************************/

	Insert into Warehouse.relational.OfferCycles 
	Select Distinct
		d.StartDate
		, d.Enddate 
	From #OffersWithMembersWarehouse d
	Left Outer Join Warehouse.relational.OfferCycles as oc
		on d.StartDate = oc.StartDate
		and d.EndDate = oc.EndDate
	Where
		oc.OfferCyclesID is null;

	/******************************************************************************
	- Assign Segment type to each offer
	- Load results into Warehouse.Staging.ControlSetup_OffersSegment_Warehouse table


	Create table for storing results:

	CREATE TABLE Warehouse.Staging.ControlSetup_OffersSegment_Warehouse
		(IronOfferID INT
		, IronOfferName NVARCHAR(200)
		, StartDate DATETIME
		, EndDate DATETIME
		, PartnerID INT
		, PartnerName VARCHAR(100)
		, Segment VARCHAR(50)
		, CONSTRAINT PK_ControlSetup_OffersSegment_Warehouse PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)
		)
	******************************************************************************/
	 
	Truncate table Warehouse.Staging.ControlSetup_OffersSegment_Warehouse;
	
	Insert into Warehouse.Staging.ControlSetup_OffersSegment_Warehouse
		(IronOfferID
		, IronOfferName
		, StartDate
		, EndDate
		, PartnerID
		, PartnerName
		, Segment
		)
	Select 
		o.IronOfferID
		, o.IronOfferName
		, o.StartDate
		, o.EndDate
		, o.PartnerID
		, o.PartnerName
		, s.SegmentCode as Segment
	From #OffersWithMembersWarehouse o
	Left join Warehouse.Relational.IronOfferSegment s
		on o.IronOfferID = s.IronOfferID;
		
	
	--	Commented out until first run through

	--	In the case that a IronOFfer has had a change in it's start date or end date since the last crontrol group run, update the OfferCyclesID in [nFI].[Relational].[ironoffercycles]
	--	to prevent a second control group being sest up for the same retailer / segment
		
	--UPDATE ioc
	--SET ioc.OfferCyclesID = oc2.OfferCyclesID
	--FROM [Warehouse].[Staging].[ControlSetup_OffersSegment_Warehouse] os
	--INNER JOIN [Warehouse].[Relational].[ironoffercycles] ioc
	--	ON os.IronOfferID = ioc.IronOfferID
	--INNER JOIN [Warehouse].[Relational].[OfferCycles] oc
	--	ON ioc.OfferCyclesID = oc.OfferCyclesID
	--INNER JOIN [Staging].[ControlSetup_Cycle_Dates] cd
	--	ON oc.StartDate BETWEEN cd.StartDate AND cd.EndDate
	--INNER JOIN [Warehouse].[Relational].[OfferCycles] oc2
	--	ON os.StartDate = CONVERT(DATE, oc2.StartDate)
	--	AND os.EndDate = CONVERT(DATE, oc2.EndDate)
	--WHERE 1 = 1
	--AND oc.OfferCyclesID != oc2.OfferCyclesID



	/******************************************************************************
	CHECK POINT: If any entries are blank, check offer name follows naming convention

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_RBS_Segments
		(PublisherType VARCHAR(50)
		, IronOfferID INT
		, IronOfferName NVARCHAR(200)
		, StartDate DATE
		, EndDate DATE
		, PartnerID INT
		, PartnerName VARCHAR(200)
		, Segment VARCHAR(10)
		, CONSTRAINT PK_ControlSetup_Validation_RBS_Segments PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)  
		)
	******************************************************************************/
	
	-- Load errors

	Truncate table Warehouse.Staging.ControlSetup_Validation_RBS_Segments;

	Insert into Warehouse.Staging.ControlSetup_Validation_RBS_Segments
		(PublisherType  
		, IronOfferID
		, IronOfferName
		, StartDate
		, EndDate
		, PartnerID
		, PartnerName
		, Segment
		)

	Select 
		'Warehouse' as PublisherType
		, s.IronOfferID
		, s.IronOfferName
		, s.StartDate
		, s.EndDate
		, s.PartnerID
		, s.PartnerName
		, s.Segment
	From Warehouse.Staging.ControlSetup_OffersSegment_Warehouse s
	Where (Segment = '' or Segment is null);

END