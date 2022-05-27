


/*=================================================================================================
Campaign Planning Procedures
Part 0: Remove all existing forecast data
Version 1: P.Lovell 16/12/2015
=================================================================================================*/


CREATE PROCEDURE [ExcelQuery].[CampaignPlanning_Preparation]
(								@PartnerName			as		VARCHAR(150)
								,@ClientServicesRef		as		VARCHAR(600)  --client services ref
								--,@PartnerID					INT	NOT NULL --partnerid
							
								)

AS
BEGIN
	SET NOCOUNT ON;

Declare @vdate DATE
SET @vdate = Getdate()

UPDATE warehouse.staging.CampaignPlanningTool_CampaignInput
SET Status_EndDate = @vdate

WHERE PartnerName=@PartnerName
  AND ClientServicesRef IN (@ClientServicesRef) 
  AND Status_EndDate IS NULL
;

UPDATE warehouse.staging.CampaignPlanningTool_Campaignsegment
SET  Status_EndDate = @vdate

WHERE ClientServicesRef IN (@ClientServicesRef)
and Status_EndDate IS NULL


UPDATE warehouse.ExcelQuery.CampaignPlanning_Calculations
SET  Status_EndDate = @vdate

WHERE ID IN (select ID from warehouse.staging.CampaignPlanningTool_Campaignsegment where status_enddate = @vdate and ClientServicesRef IN (@ClientServicesRef) )
and Status_EndDate IS NULL


END
;


