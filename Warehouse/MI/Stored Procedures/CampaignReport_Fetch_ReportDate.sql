
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 04/12/2015
	Description: Gets the date a report is due for a chosen campaign

	======================= Change Log =======================


***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Fetch_ReportDate]
(
    @ClientServicesRef nvarchar(30),
    @StartDate date = NULL,
    @Extended bit = 0
)
AS
BEGIN

    DECLARE @DateAdd int;

    SET @DateAdd = CASE @Extended WHEN 0 THEN 21 ELSE 63 END

    SELECT 
	   ClientServicesRef, 
	   StartDate, MaxEndDate,
	   DATEADD(week, datediff(week, 0, maxenddate), @DateAdd) AS ReportDate
    FROM Warehouse.MI.CampaignDetailsWave w
    WHERE (startdate = @StartDate or @StartDate is null) and ClientServicesRef = @ClientServicesRef
	   	AND CampaignType NOT LIKE '%Base%'
    ORDER BY StartDate DESC, ClientServicesRef

END