
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 02/09/2015
	Description: Resets Campaign in CampaignReportLog to initial state.  This will
	ensure that it gets picked up by the Calculation
	 
	=========== ONLY TO BE USED FOR AD-HOC RUNS ===========

	Due to how campaigns work in the report log, if this is run on a day other than the
	day the automation process runs, this campaign will be missed when the process is
	triggered this is because it works on CalcDate = GETDATE()

	== IF A CAMPAIGN NEEDS TO BE CALCULATED BY AUTOMATION ==

	The easiest way to achieve this is to delete the campaign from the CampaignReportLog.
	When the automation runs, it will automatically re-insert the missing campaign

	======================= Change Log =======================

	04/12/2015 (HR) - Added stored procedures to also delete campaign results on a reset
	   - Added SELECT statement to return the campaign that was reset

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Reset_Calc]
(
	@ClientServicesRef varchar(50),
	@StartDate date,
	@ExtendedPeriod bit = NULL, -- Optional, if not included will reset both periods
	@Reason varchar(300) = NULL -- Optional, if not included will set as 'Calc Reset'
)
AS
BEGIN

	SET @Reason = ISNULL(@Reason, 'Calc Reset') + ' - ' + USER_NAME()

	UPDATE MI.CampaignReportLog
	SET IsError = 0
		, ErrorDetails = NULL
		, CalcDate = GETDATE()
		, ReportDate = NULL
		, Reason = @Reason
		, SummedCampVal = NULL
		, SummedFinalResults = NULL
		,  Status = 'Calculation Starting'
	WHERE ClientServicesRef = @ClientServicesRef and StartDate = @StartDate and (ExtendedPeriod = @ExtendedPeriod OR @ExtendedPeriod is NULL)

	IF @ExtendedPeriod = 1 EXEC MI.CampaignResultsLTE_Delete @ClientServicesRef, @StartDate
	ELSE EXEC MI.CampaignResults_Delete @ClientServicesRef, @StartDate


	SELECT m.*, InsertedBy FROM MI.CampaignReportLog m
	LEFT JOIN (select DISTINCT InsertedBy, ClientServicesRef, StartDate from MI.CampaignExternalResultsFinalWave) w on w.ClientServicesRef = m.ClientServicesRef and w.StartDate = m.StartDate
	WHERE m.ClientServicesRef = @ClientServicesRef and m.StartDate = @StartDate and (ExtendedPeriod = @ExtendedPeriod OR @ExtendedPeriod is NULL)

END


