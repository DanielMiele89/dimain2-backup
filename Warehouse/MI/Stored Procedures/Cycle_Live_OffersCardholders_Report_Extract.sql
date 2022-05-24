-- =============================================
-- Author:		Jason Shipp
-- Create date: 18/07/2017
-- Description: Fetch data for Campaign Cycle Live Offers Report
-- =============================================
CREATE PROCEDURE MI.Cycle_Live_OffersCardholders_Report_Extract
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/**************************************************************************
	Populate temp table with retailer names
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Retailers') IS NOT NULL 
		DROP TABLE #Retailers;

	SELECT
		retailers2.RetailerID
		, retailers2.RetailerName
	INTO #Retailers
	FROM 	
		(SELECT 
		retailers.* 
		, ROW_NUMBER() OVER (PARTITION BY retailers.RetailerID ORDER BY retailers.RetailerName) AS IDRank
		FROM
			(SELECT
			wp.PartnerID AS RetailerID
			, wp.PartnerName AS RetailerName
			FROM Warehouse.Relational.Partner wp
			WHERE wp.BrandID IS NOT NULL

			UNION ALL

			SELECT
			rp.PartnerID AS RetailerID
			, rp.PartnerName AS RetailerName
			FROM nFI.Relational.Partner rp
			) retailers
		) retailers2
	WHERE retailers2.IDRank = 1;

	/**************************************************************************
	Populate temp table with publisher names, colours and an ordering column
	***************************************************************************/

	IF OBJECT_ID('tempdb..#PublisherColours') IS NOT NULL 
			DROP TABLE #PublisherColours;

	WITH 
		Publishers_all AS
			(SELECT 
				ClubID AS PublisherID
				, ClubName AS PublisherName 		
			FROM nFI.Relational.Club
		
			UNION ALL
		
			SELECT
				132 AS PublisherID
				, 'RBS' AS PublisherName 

			UNION ALL

			SELECT
				-1 AS PublisherID
				, 'American Express' AS PublisherName
			)

	SELECT 
		pubs.*
		, col.ColourHexCode
	INTO #PublisherColours
	FROM
		(SELECT 
			p.PublisherID
			, p.PublisherName 
			, ROW_NUMBER() OVER (ORDER BY p.PublisherName DESC) AS PubOrderNum
		FROM Publishers_all p
		WHERE p.PublisherID IN (132, 12)

		UNION ALL

		SELECT 
			p.PublisherID
			, p.PublisherName 
			, ROW_NUMBER() OVER (ORDER BY p.PublisherName) +2 AS PubOrderNum 
		FROM Publishers_all p
		WHERE p.PublisherID NOT IN (-1, 132, 12)

		UNION ALL

		SELECT 
			p.PublisherID
			, p.PublisherName 
			, (SELECT COUNT(*) FROM Publishers_all) AS PubOrderNum 
		FROM Publishers_all p
		WHERE p.PublisherID IN (-1)
		) pubs
	INNER JOIN Warehouse.APW.ColourList col
		ON pubs.PubOrderNum = col.ID;

	/**************************************************************************
	Fetch report data
	***************************************************************************/

	SELECT 
		d.*
		, r.RetailerName
		, p.PublisherName
		, p.ColourHexCode
		, p.PubOrderNum
	FROM Warehouse.MI.Cycle_Live_OffersCardholders d
	LEFT JOIN #Retailers r
		ON d.PartnerID = r.RetailerID
	INNER JOIN #PublisherColours p
		ON d.ClubID = p.PublisherID
	WHERE d.ReportDate =
		(SELECT MAX(ReportDate) FROM Warehouse.MI.Cycle_Live_OffersCardholders)
	AND r.RetailerName IS NOT NULL;

END