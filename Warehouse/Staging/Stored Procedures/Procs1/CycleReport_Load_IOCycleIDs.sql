/******************************************************************************
Author: Jason Shipp
Created: 12/12/2018
Purpose: 
	- Load IronOfferIDs and IronOfferCyclesIDs associated with the retailer analysis periods flagged as not yet calculated in the Staging.CycleReport_RetailerAnalysisDates table

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.CycleReport_Load_IOCycleIDs
	
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE Warehouse.Staging.CycleReport_IronOfferCycles;

	INSERT INTO Warehouse.Staging.CycleReport_IronOfferCycles (
		RetailerAnalysisID
		, RetailerID
		, StartDate
		, EndDate
		, IsBespoke
		, IronOfferID
		, IronOfferCyclesID
		, PublisherGroupName
	)
	SELECT -- RBS Iron Offers
		d.RetailerAnalysisID
		, d.RetailerID
		, d.StartDate
		, d.EndDate
		, d.IsBespoke
		, s.IronOfferID
		, ioc.ironoffercyclesid
		, s.PublisherGroupName
	FROM Warehouse.Staging.CycleReport_RetailerAnalysisDates d
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON d.RetailerID = s.RetailerID
		AND s.OfferStartDate <= d.EndDate
		AND (s.OfferEndDate >= d.StartDate OR s.OfferEndDate IS NULL)
	LEFT JOIN Warehouse.Relational.ironoffercycles ioc
		ON s.IronOfferID = ioc.ironofferid
	LEFT JOIN Warehouse.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	WHERE 
		d.IsCalculated = 0
		AND cyc.StartDate <= d.EndDate
		AND (cyc.EndDate >= d.StartDate)
		AND s.PublisherGroupName = 'RBS'

	UNION ALL

	SELECT -- nFI Iron Offers
		d.RetailerAnalysisID
		, d.RetailerID
		, d.StartDate
		, d.EndDate
		, d.IsBespoke
		, s.IronOfferID
		, ioc.ironoffercyclesid
		, s.PublisherGroupName
	FROM Warehouse.Staging.CycleReport_RetailerAnalysisDates d
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON d.RetailerID = s.RetailerID
		AND s.OfferStartDate <= d.EndDate
		AND (s.OfferEndDate >= d.StartDate OR s.OfferEndDate IS NULL)
	LEFT JOIN nFI.Relational.ironoffercycles ioc
		ON s.IronOfferID = ioc.ironofferid
	LEFT JOIN nFI.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	WHERE 
		d.IsCalculated = 0
		AND cyc.StartDate <= d.EndDate
		AND (cyc.EndDate >= d.StartDate)
		AND s.PublisherGroupName = 'nFI'

	UNION ALL

	SELECT DISTINCT -- AMEX Iron Offers
		d.RetailerAnalysisID
		, d.RetailerID
		, d.StartDate
		, d.EndDate
		, d.IsBespoke
		, s.IronOfferID
		, NULL AS ironoffercyclesid
		, s.PublisherGroupName
	FROM Warehouse.Staging.CycleReport_RetailerAnalysisDates d
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON d.RetailerID = s.RetailerID
		AND s.OfferStartDate <= d.EndDate
		AND (s.OfferEndDate >= d.StartDate OR s.OfferEndDate IS NULL)
	LEFT JOIN nFI.Relational.AmexIronOfferCycles ioc
		ON s.IronOfferID = ioc.AmexIronOfferID
	LEFT JOIN nFI.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	WHERE 
		d.IsCalculated = 0
		AND cyc.StartDate <= d.EndDate
		AND (cyc.EndDate >= d.StartDate)
		AND s.PublisherGroupName = 'AMEX';

	/******************************************************************************
	-- Create table

	CREATE TABLE Warehouse.Staging.CycleReport_IronOfferCycles (
		ID int IDENTITY (1,1) NOT NULL
		, RetailerAnalysisID int NOT NULL
		, RetailerID int NOT NULL
		, StartDate date NOT NULL
		, EndDate date NOT NULL
		, IsBespoke BIT NOT NULL
		, IronOfferID int NOT NULL
		, IronOfferCyclesID int
		, PublisherGroupName varchar(40)
		, CONSTRAINT PK_CycleReport_IronOfferCycles PRIMARY KEY CLUSTERED (ID)
		, CONSTRAINT AK_CycleReport_IronOfferCycles UNIQUE(IronOfferID, IronOfferCyclesID)
	);

	CREATE NONCLUSTERED INDEX IX_CycleReport_IronOfferCycles ON Warehouse.Staging.CycleReport_IronOfferCycles
	(IronOfferID, IronOfferCyclesID, PublisherGroupName);	
	******************************************************************************/

END