


/*=================================================================================================
Campaign Planning Procedures
Part 4: Results Extraction for Booking calendar population part 3
Version 1: P.Lovell 13/11/2015
Revisions: Summarises by ClientservicesRef
=================================================================================================*/

CREATE PROCEDURE [ExcelQuery].[CampaignPlanning_Results3] (@IDs VARCHAR(600))
	--WITH EXECUTE AS OWNER
AS
BEGIN
	SET NOCOUNT ON;
SELECT distinct cs.ClientServicesRef
		,cs.startdate
		,cs.enddate
		,CASE  WHEN HTMID IS NULL AND   Lapser				= 1 THEN 'C01'
									WHEN HTMID IS NULL AND Homemover			= 1 THEN 'A'
									WHEN HTMID IS NULL AND CompetitorShopper4wk = 1 THEN 'D'
									WHEN HTMID IS NULL AND Student				= 1 THEN 'S'
									WHEN HTMID IS NULL AND SuperSegmentID		IS NOT NULL THEN CONVERT(varchar(5),SuperSegmentID) 					
									ELSE CONVERT(varchar(5),HTMID) END 
		,Gender
		,MinAge
		,MaxAge
		,DriveTimeband
		,CAMEO_CODE_GRP
		,SocialClass
		,MinHeatMapScore
		,MaxHeatMapScore
		,max(bespoketargeting)
		,max(QualifyingMids)
		,SUM(mailed_group)
		,SUM(control_group)
		,0
		,0
		,0
		,SUM(total_sales)
		,SUM(Qualifying_sales)
		,SUM(incremental_sales)
		

FROM warehouse.ExcelQuery.CampaignPlanning_Calculations as cc
INNER JOIN warehouse.staging.CampaignPlanningTool_CampaignSegment as cs with (NOLOCK)
	ON cc.ID = cs.ID

WHERE cc.ID IN (@IDs)


GROUP BY ClientServicesRef
		,startdate
		,enddate
	,CASE  WHEN HTMID IS NULL AND   Lapser				= 1 THEN 'C01'
									WHEN HTMID IS NULL AND Homemover			= 1 THEN 'A'
									WHEN HTMID IS NULL AND CompetitorShopper4wk = 1 THEN 'D'
									WHEN HTMID IS NULL AND Student				= 1 THEN 'S'
									WHEN HTMID IS NULL AND SuperSegmentID		IS NOT NULL THEN CONVERT(varchar(5),SuperSegmentID) 					
									ELSE CONVERT(varchar(5),HTMID) END 

		,Gender
		,MinAge
		,MaxAge
		,DriveTimeband
		,CAMEO_CODE_GRP
		,SocialClass
		,MinHeatMapScore
		,MaxHeatMapScore

		
;

--TRUNCATE TABLE warehouse.ExcelQuery.CampaignPlanning_Calculations;

END

