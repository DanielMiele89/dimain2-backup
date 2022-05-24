


/*=================================================================================================
Campaign Planning Procedures
Part 4: Results Extraction for Booking calendar population
Version 2: P.Lovell 13/11/2015
Revisions: Summarises by ClientservicesRef
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[CampaignPlanning_Results2] (@IDs VARCHAR(600))
AS
BEGIN
	SET NOCOUNT ON;
SELECT distinct cs.ClientServicesRef
		,cs.startdate
		,cs.enddate
		,SUM(mailed_group)
		,SUM(control_group)
		,ci.CustomerBaseID
		,AVG(audience_fcst)
		,AVG(OfferRate)
		,SUM(total_sales)
		,SUM(Qualifying_sales)
		,SUM(incremental_sales)
		,0
		,0
		,0
		,0
		,SUM((Qualifying_sales * OfferRate) + ((Total_sales-Qualifying_sales)*baserate))
		,SUM((Qualifying_sales * OfferRate) + ((Total_sales-Qualifying_sales)*baserate)) *0.35
		,SUM(Cost_of_Campaign - (Qualifying_sales * OfferRate))
		,SUM((Qualifying_sales * OfferRate) * 0.35)
		,c_length
		

FROM warehouse.ExcelQuery.CampaignPlanning_Calculations as cc
INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cs with (NOLOCK)
	ON cc.ID = cs.ID
INNER JOIN warehouse.Staging.CampaignPlanningTool_CampaignInput as ci with (NOLOCK)
	ON cs.ClientServicesRef = ci.ClientServicesRef 

GROUP BY cs.ClientServicesRef
		,cs.startdate
		,cs.enddate
		,c_length
		,ci.CustomerBaseID
		
;



END