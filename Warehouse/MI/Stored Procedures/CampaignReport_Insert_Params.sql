
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Insert params for Calculate stored procedures

	Depending on if the extended period is required or not, selects the campaigns that
	are ready to report on and inserts into the CampaignReportLog table to be picked up
	by the SSIS process

	======================= Change Log =======================

	18/08/2015 - Due to the CampaignReportLog being historically accurate, the logic to
	decide which campaigns to choose has been updated to check if the campaign is in the
	CampaignReportLog and the EndDate has been reached (-2 weeks)

	The second insert checks if the campaign is in the CampaignReportLog where it was not
	in the extended period and there does not exist a record for the campaign in the 
	extended period

     26/09/2016 - Extended version has become legacy and removed from the code

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Insert_Params]
    --(@Extended bit = 0)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--IF @Extended = 0
	--BEGIN
		INSERT INTO MI.CampaignReportLog
		(ClientServicesRef, StartDate, Status, ExtendedPeriod)

		SELECT 
			ClientServicesRef, 
			StartDate,
			'Calculation Starting',
			0
		FROM Warehouse.MI.CampaignDetailsWave w
		WHERE MaxEnddate<=GETDATE()-13
			AND NOT EXISTS 
			(
				SELECT 1 FROM Warehouse.MI.CampaignReportLog wk
				WHERE wk.ClientServicesRef=w.ClientServicesRef
				AND wk.StartDate=w.StartDate and wk.ExtendedPeriod = 0
			)
			AND CampaignType NOT LIKE '%Base%'
		ORDER BY StartDate DESC, ClientServicesRef
	--END
/*	IF @Extended = 1
	BEGIN

		INSERT INTO MI.CampaignReportLog
		(ClientServicesRef, StartDate, Status, ExtendedPeriod)

		SELECT 
			ClientServicesRef, 
			StartDate, 
			'Calculation Starting',
			@Extended
		FROM Warehouse.MI.CampaignDetailsWave w
		WHERE MaxEnddate<=GETDATE()-13-6*7
		 -- MaxEnddate<=dateadd(day,-13-6*7, '2015-12-08')
			AND NOT EXISTS 
			(
				SELECT 1 FROM Warehouse.MI.CampaignReportLog wk
				WHERE wk.ClientServicesRef=w.ClientServicesRef
				AND wk.StartDate=w.StartDate and wk.ExtendedPeriod = 1
			)
			AND EXISTS 
			(
				SELECT 1 FROM Warehouse.MI.CampaignReportLog wk
				WHERE wk.ClientServicesRef=w.ClientServicesRef
				AND wk.StartDate=w.StartDate and wk.ExtendedPeriod = 0
			)
			AND CampaignType NOT LIKE '%Base%'
		ORDER BY StartDate DESC, MaxEnddate DESC, ClientServicesRef

	END
*/

END