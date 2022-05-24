/******************************************************************************
Author: Jason Shipp
Created: 11/12/2018
Purpose:
	- Setup new analysis periods for retailers
	- Default to retailers' default analysis period increment for retailers with a previous calculation, from the end of the last calculated period. 
	- If there is no recent analysis period, use most recent complete calendar month
	- For new retailers, default to the beginning to end of earliest-activity calendar month in the last 2 months
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.CycleReport_RetailerAnalysisDates_Update
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @Today date = CAST(GETDATE() AS date);
	DECLARE @DefaultMonthStart date = (SELECT DATEADD(month, -1, DATEADD(day, -((DATEPART(day, @Today))-1), @Today))); -- Beginning of last complete calendar month

	/******************************************************************************
	Load new retailers: retailers without a standard reporting analysis period increment and active offers in the last 2 months
	******************************************************************************/

	IF OBJECT_ID('tempdb..#NewRetailers') IS NOT NULL DROP TABLE #NewRetailers;

	SELECT DISTINCT RetailerID
	INTO #NewRetailers
	FROM Warehouse.Relational.IronOfferSegment s
	WHERE 
		s.OfferStartDate >= DATEADD(month, -2, @Today) -- Only include retailers with offers active in the last 2 months
		AND NOT EXISTS (
			SELECT NULL FROM Warehouse.Staging.CycleReport_RetailerStandardIncrements i
				WHERE s.RetailerID = i.RetailerID
		);
	  
	/******************************************************************************
	Load maximum analysis period end dates previously calculated for retailers, excluding bespoke periods and retailers without an analysis period in the last month 
	******************************************************************************/	

	IF OBJECT_ID('tempdb..#MaxRetailerAnalysisDates') IS NOT NULL DROP TABLE #MaxRetailerAnalysisDates;

	SELECT 
		d.RetailerID
		, MAX(d.EndDate) AS MaxAnalysisEndDate
	INTO #MaxRetailerAnalysisDates
	FROM Warehouse.Staging.CycleReport_RetailerAnalysisDates d
	WHERE
		d.IsBespoke = 0
		AND d.IsCalculated = 1
		AND d.EndDate >= DATEADD(month, -1, @Today)
	GROUP BY 
		d.RetailerID;

	/******************************************************************************
	Load new analysis periods for non-new retailers. Default to start and end of last complete calendar month if retailer has had a gap in recent analysis periods
	******************************************************************************/	

	WITH NewRetailerAnalysisDatesStaging AS (
		SELECT 
			i.RetailerID
			, COALESCE(DATEADD(day, 1, d.MaxAnalysisEndDate), @DefaultMonthStart) AS StartDate
			, COALESCE(	
				CASE i.StandardReportingIncrement
					WHEN 'day' THEN DATEADD(day, i.StandardIncrementAmount, d.MaxAnalysisEndDate)
					WHEN 'week' THEN DATEADD(week, i.StandardIncrementAmount, d.MaxAnalysisEndDate)
					WHEN 'month' THEN EOMONTH(DATEADD(month, i.StandardIncrementAmount, d.MaxAnalysisEndDate))
					ELSE NULL -- Will cause insert error if NULL
				END
				, EOMONTH(@DefaultMonthStart)
			) AS EndDate
		FROM Warehouse.Staging.CycleReport_RetailerStandardIncrements i
		LEFT JOIN #MaxRetailerAnalysisDates d
			ON i.RetailerID = d.RetailerID
	)
	INSERT INTO Warehouse.Staging.CycleReport_RetailerAnalysisDates (
		RetailerID
		, StartDate
		, EndDate
		, IsBespoke
		, IsCalculated
	)
	SELECT 
		d.RetailerID
		, d.StartDate
		, d.EndDate
		, 0 AS IsBespoke
		, 0 AS IsCalculated
	FROM NewRetailerAnalysisDatesStaging d
	WHERE 
		d.EndDate < CAST(@Today AS date) -- Exclude analysis periods still ongoing
		AND EXISTS ( -- Check retailer has offers active in analysis period
			SELECT NULL FROM Warehouse.Relational.IronOfferSegment s
			WHERE
				d.RetailerID = s.RetailerID
				AND s.OfferStartDate <= d.EndDate
				AND (s.OfferEndDate >= d.StartDate OR s.OfferEndDate IS NULL)
		)
		AND NOT EXISTS ( -- Exclude retailer periods already inserted
			SELECT NULL FROM Warehouse.Staging.CycleReport_RetailerAnalysisDates x
			WHERE
				d.RetailerID = x.RetailerID
				AND d.StartDate = x.StartDate
				AND d.EndDate = x.EndDate
		);

	/******************************************************************************
	Load retailer analysis periods for new retailers (default to start and end of earliest-activity calendar month in the last 2 months)
	NOTE- This insert can be made bespoke, depending on what RP want for new retailers
	******************************************************************************/	

	WITH NewRetailerAnalysisDatesStaging AS (
		SELECT
			r.RetailerID
			, DATEADD (day, -((DATEPART(day, MIN(s.OfferStartDate)))-1), MIN(s.OfferStartDate))	AS StartDate
			, EOMONTH(DATEADD (day, -((DATEPART(day, MIN(s.OfferStartDate)))-1), MIN(s.OfferStartDate))) AS EndDate
			, 0 AS IsBespoke
			, 0 AS IsCalculated
		FROM #NewRetailers r
		INNER JOIN Warehouse.Relational.IronOfferSegment s
			ON r.RetailerID = s.RetailerID
		GROUP BY
			r.retailerID
	)
	INSERT INTO Warehouse.Staging.CycleReport_RetailerAnalysisDates (
		RetailerID
		, StartDate
		, EndDate
		, IsBespoke
		, IsCalculated
	)
	OUTPUT 'Proposed new retailer analysis dates' AS SetupToCheck, INSERTED.*
	SELECT 
		d.RetailerID
		, d.StartDate
		, d.EndDate
		, 0 AS IsBespoke
		, 0 AS IsCalculated
	FROM NewRetailerAnalysisDatesStaging d
	WHERE
		d.StartDate >= DATEADD(month, -2, @Today) -- Only include retailers with offers active in the last 2 months
		AND d.EndDate < CAST(@Today AS date) -- Exclude analysis periods still ongoing
		AND EXISTS ( -- Check retailer has offers active in analysis period
			SELECT NULL FROM Warehouse.Relational.IronOfferSegment s
			WHERE
				d.RetailerID = s.RetailerID
				AND s.OfferStartDate <= d.EndDate
				AND (s.OfferEndDate >= d.StartDate OR s.OfferEndDate IS NULL)
		)
		AND NOT EXISTS ( -- Exclude retailer periods already inserted
			SELECT NULL FROM Warehouse.Staging.CycleReport_RetailerAnalysisDates x
			WHERE
				d.RetailerID = x.RetailerID
				AND d.StartDate = x.StartDate
				AND d.EndDate = x.EndDate
		);					

	/******************************************************************************
	Load new retailer standard reporting analysis period increments (default to 1 month)
	NOTE- This insert can be made bespoke, depending on what RP want for new retailers
	******************************************************************************/	

	INSERT INTO Warehouse.Staging.CycleReport_RetailerStandardIncrements (
		RetailerID
		, StandardReportingIncrement
		, StandardIncrementAmount
	)
	OUTPUT 'Proposed new retailer standard reporting period increment ' AS SetupToCheck, INSERTED.*
	SELECT 
		r.RetailerID
		, 'month' AS StandardReportingIncrement
		, 1 AS StandardIncrementAmount
	FROM #NewRetailers r;
	
	/******************************************************************************
	-- Create tables

	CREATE TABLE Warehouse.Staging.CycleReport_RetailerAnalysisDates (
		RetailerAnalysisID int IDENTITY (1,1) NOT NULL
		, RetailerID int NOT NULL
		, StartDate date NOT NULL
		, EndDate date NOT NULL
		, IsBespoke bit NOT NULL
		, IsCalculated bit NOT NULL
	);

	ALTER TABLE Warehouse.Staging.CycleReport_RetailerAnalysisDates ADD CONSTRAINT [PK_CycleReport_RetailerAnalysisDates] PRIMARY KEY CLUSTERED 
	(RetailerAnalysisID ASC);
	
	ALTER TABLE Warehouse.Staging.CycleReport_RetailerAnalysisDates  
	ADD CONSTRAINT Constraint_CycleReport_RetailerAnalysisDates UNIQUE (RetailerID, StartDate, EndDate);

	CREATE TABLE Warehouse.Staging.CycleReport_RetailerStandardIncrements (
		RetailerID int NOT NULL
		, StandardReportingIncrement varchar(50) NOT NULL
		, StandardIncrementAmount int NOT NULL
	);

	ALTER TABLE Warehouse.Staging.CycleReport_RetailerStandardIncrements ADD CONSTRAINT [PK_CycleReport_RetailerStandardIncrements] PRIMARY KEY CLUSTERED 
	(RetailerID ASC);
	******************************************************************************/

END