
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Insert params for Calculate stored procedures

	Extended Period calculations have been discontinued however, for some retailers
	Client Services still require this report.  This is on a request basis and campaigns
	are inserted into MI.CampaignReportLog_Extended.

	This procedure insert any campaigns that are due to be calculated into the log tables
	to be picked up by the calculation process.

	======================= Change Log =======================


***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Insert_ParamsExtended]
    --(@Extended bit = 0)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO MI.CampaignReportLog (ClientServicesRef, StartDate, ExtendedPeriod)

	SELECT
	   w.ClientServicesRef
	   , w.StartDate
	   , 1 as ExtendedPeriod
    FROM MI.CampaignDetailsWave w
    JOIN MI.CampaignReportLog_Extended e on e.ClientServicesRef = w.ClientServicesRef
	   and e.StartDate = w.StartDate
    WHERE MaxEndDate<=GETDATE()-13-6*7
	   AND NOT EXISTS (
		  SELECT 1 FROM MI.CampaignReportLog l
		  WHERE l.ClientServicesRef = w.ClientServicesRef
			 and l.StartDate = w.StartDate and l.ExtendedPeriod = 1
	   )

END





