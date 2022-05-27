
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Update CampaignReportLog when a calculation is finished

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Update_CalcLog_NEW]
(
	@ClientServicesRef varchar(40),
	@StartDate varchar(40),
	@CalcStartDate date,
	@isIncomplete bit = 0,
	@Extended bit = 0
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	IF @isIncomplete = 0
	    UPDATE MI.CampaignReportLog
	    SET Status = 'Calculation Completed', ReportDate = NULL
	    WHERE ClientServicesRef = @ClientServicesRef 
		    and StartDate = @CalcStartDate
		    and ExtendedPeriod = @Extended
		    --and CAST(CalcDate as DATE) = CAST(GETDATE() as DATE)
    ELSE IF @isIncomplete = 1
	   UPDATE MI.CampaignReportLog_Incomplete
	   SET Status = 'Calculation Completed'
	   WHERE ClientServicesRef = @ClientServicesRef
		  and StartDate = @StartDate
		  and CalcStartDate = @CalcStartDate


END
