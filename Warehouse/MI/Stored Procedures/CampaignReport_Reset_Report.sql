
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 02/09/2015
	Description: Resets Campaign in CampaignReportLog so that it will be picked up
	by automated report creation process 

	===	Can also be used for Ad-Hoc report generation ===

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Reset_Report]
(
	@ClientServicesRef varchar(50),
	@StartDate date,
	@ExtendedPeriod bit = NULL, -- Optional, if not included will reset both periods
	@Reason varchar(300) = NULL -- Optional, if not included will set as 'Calc Reset'
)
AS
BEGIN
	SET NOCOUNT ON;

	SET @Reason = ISNULL(@Reason, 'Report Reset') + ' - ' + USER_NAME()

	UPDATE MI.CampaignReportLog
	SET IsError = 0
		, ErrorDetails = NULL
		, Status = 'Calculation Completed'
		, ReportDate = NULL
		, Reason = @Reason
		, SummedCampVal = NULL
		, SummedFinalResults = NULL
	WHERE ClientServicesRef = @ClientServicesRef and StartDate = @StartDate and (ExtendedPeriod = @ExtendedPeriod OR @ExtendedPeriod is NULL)

	SELECT * FROM MI.CampaignReportLog WHERE ClientServicesRef = @ClientServicesRef and StartDate = @StartDate and (ExtendedPeriod = @ExtendedPeriod OR @ExtendedPeriod is NULL)

END


