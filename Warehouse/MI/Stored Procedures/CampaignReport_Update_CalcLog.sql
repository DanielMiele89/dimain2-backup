
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Update CampaignReportLog when a calculation is finished

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Update_CalcLog]
(
	@ClientServicesRef varchar(40),
	@StartDate varchar(40),
	@Extended bit = 0
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE MI.CampaignReportLog
	SET Status = 'Calculation Completed', ReportDate = NULL
	WHERE ClientServicesRef = @ClientServicesRef 
		and StartDate = @StartDate
		and ExtendedPeriod = @Extended
		--and CAST(CalcDate as DATE) = CAST(GETDATE() as DATE)


END
