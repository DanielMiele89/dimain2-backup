/******************************************************************************
Author: Jason Shipp
Created: 11/06/2018
Purpose: 
	- Fetches the most recent flash incentivised transaction results from Warehouse.Staging.FlashTransactionReport_ReportData table
	- Results aggregated by retailer, period, Shopper ALS segment and Offer Type
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 03/07/2018
	- Changed logic to fetch data based on the most recent calculation date instead of the most recent analysis dates per retailer 

Jason Shipp 01/02/2019
	- Updated ColourHexCodes to match new brand colours

******************************************************************************/
CREATE PROCEDURE Staging.FlashTransactionReport_Fetch_ReportData (
	@RetailerID int = NULL
)
 
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Load maximum calculation dates per retailer
	******************************************************************************/

	IF OBJECT_ID('tempdb..#MaxRetailerCalcDates') IS NOT NULL DROP TABLE #MaxRetailerCalcDates;

	SELECT 
		RetailerID
		, MAX(CalculationDate) AS MaxCalculationDate
	INTO #MaxRetailerCalcDates
	FROM Warehouse.Staging.FlashTransactionReport_ReportData
	GROUP BY
		RetailerID;

	/******************************************************************************
	Load segment-colour map
	******************************************************************************/

	IF OBJECT_ID('tempdb..#ColourMap') IS NOT NULL DROP TABLE #ColourMap;

	SELECT 
	b.SuperSegmentID
	, b.OfferTypeID
	, CASE col.ColourHexCode WHEN '#4b196e' THEN '#1e5cc0' WHEN '#dc0f50' THEN '#ea0c5c' ELSE col.ColourHexCode END AS ColourHexCode 
	INTO #ColourMap
	FROM (
		SELECT
		SuperSegmentID
		, OfferTypeID
		, ROW_NUMBER() OVER (ORDER BY (CASE WHEN OfferTypeID = 14 THEN 1 ELSE 2 END) ASC, SuperSegmentID ASC) AS ColID
		FROM (
			SELECT DISTINCT 
			d.SuperSegmentID
			, d.OfferTypeID
			FROM Warehouse.Staging.FlashTransactionReport_ReportData d
			INNER JOIN #MaxRetailerCalcDates md
				ON d.RetailerID = md.RetailerID
				AND d.CalculationDate = md.MaxCalculationDate
			WHERE (d.RetailerID = @RetailerID OR @RetailerID IS NULL)
		) a
	) b
	INNER JOIN Warehouse.APW.ColourList col
		ON b.ColID = col.ID;

	/******************************************************************************
	Fetch report data
	******************************************************************************/

	SELECT 
		d.ID
		, d.RetailerID
		, d.RetailerName
		, d.StartDate
		, d.EndDate
		, d.PeriodType
		, d.SuperSegmentID
		, d.SuperSegmentName
		, d.OfferTypeID
		, d.TypeDescription
		, CASE 
			WHEN d.OfferTypeID = 14
			THEN CONCAT('Shopper Segment - ',  d.SuperSegmentName)
			ELSE (CASE WHEN d.TypeDescription = 'ShopperSegment' THEN 'Shopper Segment' ELSE d.TypeDescription END)
		END AS OfferGroup
		, CASE 
			WHEN d.OfferTypeID = 14
			THEN d.SuperSegmentName
			ELSE (CASE WHEN d.TypeDescription = 'ShopperSegment' THEN 'ShopperSegment' ELSE d.TypeDescription END)
		END AS OfferGroupShort
		, d.Cardholders
		, d.Sales
		, Spenders
		, d.Transactions
		, d.Investment
		, d.ATV
		, d.ATF
		, d.RR
		, d.SPS
		, d.SalesToCostRatio
		, d.CumulativeSpendersInPeriod
		, col.ColourHexCode
		, DENSE_RANK() OVER (PARTITION BY d.PeriodType ORDER BY StartDate DESC) AS PeriodID
	FROM Warehouse.Staging.FlashTransactionReport_ReportData d
	INNER JOIN #MaxRetailerCalcDates md
		ON d.RetailerID = md.RetailerID
		AND d.CalculationDate = md.MaxCalculationDate
	LEFT JOIN #ColourMap col
		ON (d.SuperSegmentID = col.SuperSegmentID OR d.SuperSegmentID IS NULL AND col.SuperSegmentID IS NULL)
		AND d.OfferTypeID = col.OfferTypeID OR (d.OfferTypeID IS NULL AND col.OfferTypeID IS NULL)
	WHERE
		(d.RetailerID = @RetailerID OR @RetailerID IS NULL);

END