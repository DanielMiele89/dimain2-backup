/******************************************************************************
Author: Jason Shipp
Created: 13/03/2018
Purpose: 
	- Load offers for which to setup control members for
	- Load offer segments into Warehouse.Staging.ControlSetup_OffersSegment_Secondary table
	- Load validation of segment types assigned to each offer
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 11/07/2018
	- Updated date logic to match IronOffer_References

Jason Shipp 28/08/2018
	- Used Warehouse.Relational.IronOfferSegment table as source of segment codes instead of applying string searches to IronOfferNames

Jason Shipp 11/09/2019
	- Paramatised query so it can be run for specific retailers (using @RetailerID)

******************************************************************************/
CREATE PROCEDURE Staging.ControlSetup_Secondary_Load_Segments (@RetailerID int)
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Declare variables
	******************************************************************************/

	Declare @SDate date = (Select StartDate from Warehouse.Staging.ControlSetup_Cycle_Dates)

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
	Clear staging table
	******************************************************************************/

	Truncate table Warehouse.Staging.ControlSetup_OffersSegment_Secondary
	
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
	- Assign segment type to each offer
	- Load results into Warehouse.Staging.ControlSetup_OffersSegment_Secondary table

	Create tables for storing results:

	CREATE TABLE Warehouse.Staging.ControlSetup_OffersSegment_Secondary
		(IronOfferID INT
		, IronOfferName NVARCHAR(200)
		, StartDate DATE
		, EndDate DATE
		, Segment VARCHAR(50)
		, PartnerID INT
		, PublisherType VARCHAR(50) 
		, CONSTRAINT PK_ControlSetup_OffersSegment_Secondary PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)
		)
	******************************************************************************/

	-- nFI

	Insert into Warehouse.Staging.ControlSetup_OffersSegment_Secondary
	Select
		o.ID as IronOfferID
		, o.IronOfferName
		, Case
				When o.StartDate > (Select StartDate From #Dates) then o.StartDate
				Else (Select StartDate From #Dates)
			End as StartDate
			, Case
				When o.EndDate < (Select EndDate From #Dates) then o.EndDate
				Else (Select EndDate From #Dates)
			End as EndDate
		, s.SegmentCode as Segment
		, Coalesce(pa.AlternatePartnerID, o.PartnerID) as PartnerID
		, 'nFI' as PublisherType
	From nfi.Relational.IronOffer o
	Left join Warehouse.Relational.IronOfferSegment s
		on o.ID = s.IronOfferID
	Left join #PartnerAlternate pa 
		on o.PartnerID = pa.PartnerID
	Where
		o.PartnerID in (Select PartnerID from #PartnerIDs)
		and o.StartDate <= @SDate 
		and (o.EndDate is null or EndDate > @SDate);

	-- Warehouse

	Insert into Warehouse.Staging.ControlSetup_OffersSegment_Secondary
	Select
		o.IronOfferID
		, o.IronOfferName
		,  Case
				When o.StartDate > (Select StartDate From #Dates) then o.StartDate
				Else (Select StartDate From #Dates)
			End as StartDate
			, Case
				When o.EndDate < (Select EndDate From #Dates) then o.EndDate
				Else (Select EndDate From #Dates)
			End as EndDate
		, s.SegmentCode as Segment
		, Coalesce(pa.AlternatePartnerID, o.PartnerID) as PartnerID
		, 'Warehouse' as PublisherType
	From Warehouse.Relational.IronOffer o
	Left join Warehouse.Relational.IronOfferSegment s
		on o.IronOfferID = s.IronOfferID
	Left join #PartnerAlternate pa 
		on o.PartnerID = pa.PartnerID
	Where 
		o.PartnerID in (Select PartnerID from #PartnerIDs)
		and o.StartDate <= @SDate
		and (o.EndDate is null or EndDate > @SDate);

	/******************************************************************************
	CHECK POINT: If any entries are blank, check offer name follows naming convention

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_Secondary_Segments
		(PublisherType VARCHAR(50)
		, PartnerID INT
		, IronOfferID INT
		, IronOfferName NVARCHAR(200)
		, StartDate DATE
		, EndDate DATE
		, Segment VARCHAR(10)
		, CONSTRAINT PK_ControlSetup_Validation_Secondary_Segments PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)  
		)
	******************************************************************************/

	-- Load errors

	Truncate table Warehouse.Staging.ControlSetup_Validation_Secondary_Segments;

	Insert into Warehouse.Staging.ControlSetup_Validation_Secondary_Segments
		(PublisherType
		, PartnerID
		, IronOfferID
		, IronOfferName
		, StartDate
		, EndDate
		, Segment
		)
	Select 
		d.PublisherType
		, PartnerID
		, d.IronOfferID
		, d.IronOfferName
		, d.StartDate
		, d.EndDate
		, d.Segment
	From Warehouse.Staging.ControlSetup_OffersSegment_Secondary d -- Contains Warehouse and nFI Iron Offers
	Where
		(Segment = '' or Segment is null);
						
END