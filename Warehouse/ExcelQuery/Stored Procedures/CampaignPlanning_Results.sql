

/*=================================================================================================
Campaign Planning Procedures
Part 3: Results Extraction
Version 1: P.Lovell 11/11/2015
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[CampaignPlanning_Results] (@IDs VARCHAR(600))
AS
BEGIN
	SET NOCOUNT ON;
SELECT mailed_group
		,control_group
		,total_sales
		,incremental_sales
		,0
		,uplift --+ HALO
		,cost_of_campaign
		,incremental_sales_ROI
		,incremental_sales_ROI_ext
		,billing_rate
		,final_offer_rate

FROM warehouse.ExcelQuery.CampaignPlanning_Calculations
WHERE ID IN (@IDs)
;

END