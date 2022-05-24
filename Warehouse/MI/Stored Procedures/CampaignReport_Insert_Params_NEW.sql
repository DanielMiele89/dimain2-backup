
/**********************************************************************

    Author:		 Hayden Reid
    Create date: 13/08/2015
    Description: Insert params for Calculate stored procedures

    Depending on if the extended period is required or not, selects the campaigns that
    are ready to report on and inserts into the CampaignReportLog table to be picked up
    by the SSIS process

    ======================= Change Log =======================

    18/08/2015 
	   Due to the CampaignReportLog being historically accurate, the logic to
	   decide which campaigns to choose has been updated to check if the campaign is in the
	   CampaignReportLog and the EndDate has been reached (-2 weeks)

	   The second insert checks if the campaign is in the CampaignReportLog where it was not
	   in the extended period and there does not exist a record for the campaign in the 
	   extended period

    10/08/2016
	   New requirements require that the process is able to calculate campaigns where the end date
	   of the offer is not the sole determining factor on whether the campaign should be calculated

	   In this new model, Offers will be set up once with members moving between offers at the end of
	   each wave.

	   The procedure changes are as follows:
		  - First query in each IF clause, does not include any campaigns that are in [****].[*****] 
		  - The second query, adds campaigns that are in [****].[*****] and have passed the relevant date
		  

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Insert_Params_NEW](
	@Extended bit = 0
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @Extended = 0
	BEGIN
		INSERT INTO MI.CampaignReportLog
		(ClientServicesRef, StartDate, Status, ExtendedPeriod)

		SELECT 
			ClientServicesRef, 
			StartDate,
			'Calculation Starting',
			@Extended
		FROM Warehouse.MI.CampaignDetailsWave w
		WHERE MaxEnddate<=GETDATE()-13
			AND NOT EXISTS 
			(
				SELECT 1 FROM Warehouse.MI.CampaignReportLog wk
				WHERE wk.ClientServicesRef=w.ClientServicesRef
				AND wk.StartDate=w.StartDate and wk.ExtendedPeriod = 0
			)
			AND NOT EXISTS
			(
				SELECT 1 FROM Warehouse.MI.SomeTable os
				WHERE os.ClientServicesRef = w.ClientServicesRef
			)
			AND CampaignType NOT LIKE '%Base%'
		ORDER BY StartDate DESC, ClientServicesRef

		INSERT INTO MI.CampaignReportLog
		(ClientServicesRef, StartDate, Status, ExtendedPeriod)

		SELECT
			 ClientServicesRef,
			 StartDate,
			 'Calculation Starting',
			 @Extended
		FROM Warehouse.MI.SomeTable os
		WHERE EndDate <= GETDATE() -13
			 AND NOT EXISTS
			 (
				SELECT 1 FROM Warehouse.MI.CampaignReportLog wk
				WHERE wk.ClientServicesRef = os.ClientServicesRef
				    and wk.StartDate = os.StartDate and wk.ExtendedPeriod = 0
			 )

	END
	IF @Extended = 1
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
			AND NOT EXISTS
			(
				SELECT 1 FROM Warehouse.MI.SomeTable os
				WHERE os.ClientServicesRef = w.ClientServicesRef
			)
			AND CampaignType NOT LIKE '%Base%'
		ORDER BY StartDate DESC, MaxEnddate DESC, ClientServicesRef

		INSERT INTO MI.CampaignReportLog
		(ClientServicesRef, StartDate, Status, ExtendedPeriod)

		SELECT
			ClientServicesRef,
			StartDate,
			'Calculation Starting',
			@Extended
	     FROM Warehouse.MI.SomeTable os
		WHERE EndDate <= GETDATE()-13-6*7
			AND NOT EXISTS
			(
				SELECT 1 FROM Warehouse.MI.CampaignReportLog wk
				WHERE wk.ClientServicesRef = os.ClientServicesRef
				AND wk.StartDate = os.StartDate and wk.ExtendedPeriod = 1
			)
			AND EXISTS(
				SELECT 1 FROM Warehouse.MI.CampaignReportLog wk
				WHERE wk.ClientServicesRef = os.ClientServicesRef
				    AND wk.StartDate = os.StartDate and wk.ExtendedPeriod = 0
			)

	END


END

