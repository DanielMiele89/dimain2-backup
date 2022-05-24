/******************************************************************************
Author: Jason Shipp
Created: 31/05/2018
Purpose:
	- Fetches the most recent flash results for a retailer per Iron Offer from Warehouse.Staging.FlashOfferReport_ReportData  
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 03/07/2018
	- Changed logic to fetch data based on the most recent calculation date instead of the most recent analysis dates per retailer 
******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Fetch_ReportData (
	@RetailerID int = NULL
	, @ControlGroupTypeID bit
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
	FROM Warehouse.Staging.FlashOfferReport_ReportData
	GROUP BY
		RetailerID;

	/******************************************************************************
	Fetch report data
	******************************************************************************/

	SELECT 
		d.IronOfferID
		, ISNULL(CASE WHEN CHARINDEX('/', x.IronOfferName) > 0 THEN 
		  CASE WHEN d.RetailerID = 3730 THEN
			 REPLACE(
				RIGHT(x.IronOfferName, CHARINDEX('/', REVERSE(x.IronOfferName), CHARINDEX('/', REVERSE(x.IronOfferName))+1)-1)
				, '/', '-') 
		  WHEN d.RetailerID <> 3730 THEN
			 REPLACE(
				RIGHT(x.IronOfferName, CHARINDEX('/', REVERSE(x.IronOfferName)))
				, '/', '') 
		  ELSE x.IronOfferName 
		  END
	   END, IronOfferName) AS IronOfferName
		, d.StartDate
		, d.EndDate
		, d.OfferSetupStartDate
		, d.OfferSetupEndDate
		, d.PeriodType
		, d.RetailerID
		, p.PartnerName AS RetailerName
		, d.PublisherID
		, CASE WHEN d.PublisherID = 132 THEN 'RBS' ELSE c.ClubName END AS PublisherName
		, d.isWarehouse
		, d.ControlGroupTypeID
		, d.Channel
		, d.Threshold
		, d.Cardholders_E
		, d.Cardholders_C
		, d.Sales
		, d.Sales_E
		, d.Sales_C
		, d.Trans
		, d.Trans_E
		, d.Trans_C
		, d.Spenders
		, d.Spenders_E
		, d.Spenders_C
		, d.Investment
		, d.SPC
		, d.SPS
		, d.RR
		, d.ATV
		, d.ATF
		, d.SPC_C
		, d.SPS_C
		, d.RR_C
		, d.ATV_C
		, d.ATF_C
		, d.SPC_E
		, d.SPS_E
		, d.RR_E
		, d.ATV_E
		, d.ATF_E
		, RR_Uplift
		, d.ATV_Uplift
		, d.ATF_Uplift
		, d.Sales_Uplift
		, d.IncSales
		, d.IncSpenders
		, d.SalesToCostRatio
		, DENSE_RANK() OVER (PARTITION BY d.PeriodType ORDER BY StartDate DESC) AS PeriodID
	FROM Warehouse.Staging.FlashOfferReport_ReportData d
	INNER JOIN #MaxRetailerCalcDates md
		ON d.RetailerID = md.RetailerID
		AND d.CalculationDate = md.MaxCalculationDate
	LEFT JOIN Warehouse.Relational.[Partner] p
		ON d.RetailerID = p.PartnerID
	LEFT JOIN nFI.Relational.Club c
		ON d.PublisherID = c.ClubID
	LEFT JOIN (
			SELECT
			IronOfferID
			, IronOfferName 
			FROM Warehouse.Relational.IronOffer
			UNION ALL
			SELECT 
			ID
			, IronOfferName
			FROM nFI.Relational.IronOffer
			UNION ALL
			SELECT
			IronOfferID
			, TargetAudience
			FROM nFI.Relational.AmexOffer
	) x
		ON d.IronOfferID = x.IronOfferID
	WHERE 
		(d.RetailerID = @RetailerID OR @RetailerID IS NULL)
		AND d.ControlGroupTypeID = @ControlGroupTypeID;

END