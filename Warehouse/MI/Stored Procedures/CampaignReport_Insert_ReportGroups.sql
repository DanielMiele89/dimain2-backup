

/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Insert Reports missing reports that need to be created and flag reports that may have been updated

	======================= Logic ======================= 

	Insert report groups that are not in the log table but are in the final table with an 
	inserted date > the creation of the latest report to capture calculations outside of normal process

	Insert reports groups that are in log table but have an inserted date > its report date.  This indicates 
	that a change was made and needs to be discussed with the analyst repsonsible	

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Insert_ReportGroups](
	@Extended bit = 0
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @LTE varchar(3)

SELECT @LTE = CASE @Extended WHEN 0 THEN '' ELSE 'LTE' END
/*
EXEC ('
	INSERT INTO MI.CampaignReportLog
	(ClientServicesRef, StartDate, Status, ExtendedPeriod)

	SELECT 
		w.ClientServicesRef, 
		w.StartDate,
		''Calculation Manual'',
		@Extended
	FROM Warehouse.MI.CampaignInternalResults'+@LTE+'FinalWave w
	LEFT JOIN MI.CampaignReportLog r on r.ClientServicesRef = w.ClientServicesRef and r.StartDate = w.StartDate
	WHERE Inserted > (SELECT max(reportdate) FROM mi.CampaignReportLog)
	and r.ClientServicesRef is null
	ORDER BY StartDate DESC, ClientServicesRef


	INSERT INTO MI.CampaignReportLog
	(ClientServicesRef, StartDate, Status, ExtendedPeriod, IsError)
	
	SELECT 
		w.ClientServicesRef, 
		w.StartDate,
		w.InsertedBy + '' recalculated results'',
		@Extended,
		1
	FROM Warehouse.MI.CampaignInternalResults'+@LTE+'FinalWave w
	JOIN MI.CampaignReportLog r on r.ClientServicesRef = w.ClientServicesRef 
		AND r.StartDate = w.StartDate
	WHERE Inserted > (SELECT max(reportdate) FROM mi.CampaignReportLog x WHERE x.ClientServicesRef = w.ClientServicesRef and x.StartDate = w.StartDate)
	ORDER BY StartDate DESC, ClientServicesRef
')
*/
END