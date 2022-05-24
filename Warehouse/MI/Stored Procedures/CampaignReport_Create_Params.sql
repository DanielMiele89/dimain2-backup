
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 08/06/2016
	Description: Inserts new record into CampaignReport Table

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Create_Params]  (
	@ClientServicesRef nvarchar(30)
	, @StartDate date
     , @Extended bit = 0
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO MI.CampaignReportLog (ClientServicesRef, StartDate, ExtendedPeriod)
	SELECT @ClientServicesRef, @StartDate, @Extended
	FROM (
	   VALUES
		  (@ClientServicesRef, @StartDate, @Extended)
	) p(CSRef, StartDate, Extended)
	WHERE NOT EXISTS (
	   SELECT 1 FROM MI.CampaignReportLog m
	   WHERE m.ClientServicesRef = p.CSRef
		  and m.StartDate = p.StartDate
		  and m.ExtendedPeriod = p.Extended
	)

	IF @@ROWCOUNT < 1
	   PRINT CONCAT('This record already exists in the MI.CampaignReportLog table.', CHAR(13) + CHAR(10), 'If you are trying to calculate this record, try running MI.CampaignReport_Reset_Calc ', '''', @ClientServicesRef, '''', ',', '''', @StartDate, '''', ',', @Extended )
    ELSE
	   SELECT * FROM MI.CampaignReportLog 
	   WHERE ClientServicesRef = @ClientServicesRef
		  and StartDate = @StartDate
		  and ExtendedPeriod = @Extended
	   

END