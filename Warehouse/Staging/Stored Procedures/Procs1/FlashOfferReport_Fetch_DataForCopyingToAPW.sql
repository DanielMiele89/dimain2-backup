/******************************************************************************
Author: Jason Shipp
Created: 03/04/2019
Purpose:
	- Fetch new weekly results data for copying to AllPublisherWarehouse (Transform.FlashOfferReport_ReportData) using SSIS package
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 15/08/2019
	- Added daily results to fetch

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Fetch_DataForCopyingToAPW
 
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MaxCalcDate date = (SELECT MAX(CalculationDate) FROM Warehouse.Staging.FlashOfferReport_ReportData)
	
	SELECT
		d.IronOfferID
		, d.StartDate
		, d.EndDate
		, d.OfferSetupStartDate
		, d.OfferSetupEndDate
		, d.PeriodType
		, d.RetailerID
		, d.PublisherID
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
		, d.RR_Uplift
		, d.ATV_Uplift
		, d.ATF_Uplift
		, d.Sales_Uplift
		, d.IncSales
		, d.IncSpenders
		, d.SalesToCostRatio
		, d.CalculationDate
	FROM Warehouse.Staging.FlashOfferReport_ReportData d
	WHERE 
		d.CalculationDate = @MaxCalcDate
		AND d.PeriodType IN ('Weekly', 'Daily');

END