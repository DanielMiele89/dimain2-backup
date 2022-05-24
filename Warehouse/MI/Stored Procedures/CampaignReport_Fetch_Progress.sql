
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 04/12/2015
	Description: Check progress of Campaign Calculation process

	======================= Change Log =======================


***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Fetch_Progress]
AS
BEGIN

	declare @remaining float
	declare @total float
	declare @ETA datetime
	DECLARE @totalruntime datetime
	DECLARE @period bit
	DECLARE @CurrCSRef nvarchar(20), @CurrDate nvarchar(11)

    SELECT
	   @remaining = count(1)
    FROM MI.CampaignReportLog
    WHERE ReportDate IS NULL
	   AND IsError = 0
	   AND CAST(CalcDate as DATE) = CAST(GetDate() as DATE)
	   and Status = 'Calculation Starting'

    SELECT
	   @total = count(1)
    FROM MI.CampaignReportLog
    WHERE ReportDate IS NULL
	   AND CAST(CalcDate as DATE) = CAST(GetDate() as DATE)
    
    SELECT top 1 @CurrCSRef = r.ClientServicesRef, @CurrDate = r.StartDate
    FROM MI.Campaign_Log l
    JOIN MI.CampaignReportLog r on r.ClientServicesRef = l.Parameter_ClientServicesRef
	   AND r.StartDate = l.Parameter_StartDate
	   and StoreProcedureName like case ExtendedPeriod when 1 then '%LTE_Calculate%' else '%Results_Calculate%' end
    WHERE CAST(RunStartTime as Date) = CAST(GetDAte() as DATE)
    ORDER BY LogID desc

	SELECT @ETA = --CONVERT(VARCHAR(8), 
	   DATEADD(SECOND, AVG(DATEDIFF(Second, RunStartTime, COALESCE(RunEndTime, RunStartTime_Part3, RunStartTime_Part2, getdate()))), 0)
	   --, 108)
	   , @totalruntime = 
		  DATEADD(SECOND, SUM(DATEDIFF(SECOND, RunStartTime, COALESCE(RunEndTime, CASE WHEN r.ClientServicesRef + cast(r.StartDate as nvarchar) = @CurrCSRef + @CurrDate THEN GETDATE() ELSE RunStartTime_Part4 END, RunStartTime_Part3, RunStartTime_Part2,  ISNULL(RunStartTime_Part1, RunStartTime)))), 0)

	FROM Mi.Campaign_Log l
	JOIN MI.CampaignReportLog r on r.ClientServicesRef = l.Parameter_ClientServicesRef 
	   AND r.StartDate = l.Parameter_StartDate
	   and StoreProcedureName like case ExtendedPeriod when 1 then '%LTE_Calculate%' else '%Results_Calculate%' end
	WHERE StoreProcedureName like '%calculate%' 
	   and cast(RunStartTime as date) = cast(getdate() as date)
	   and iserror = 0
    
	SELECT
	    @total TotalCampaigns,
	    @remaining CampaignsRemaining,
	    100 - ROUND(ISNULL((@remaining/NULLIF(@Total, 0))*100, 100), 2) as [OverallCalc%],
	    (
		    (
			    select cast(count(*) as float)
			    from (values (l.RunStartTime_Part1), (l.RunStartTime_Part2), (l.RunStartTime_Part3), (l.RunStartTime_Part4)) t(Progress)
			    where t.Progress is not null
		    )/4
	    )*100 'Progress %',
	    CONVERT(VARCHAR(8), 
		  DATEADD(SECOND, DATEDIFF(SECOND, RunStartTime, COALESCE(RunEndTime, CASE WHEN r.ClientServicesRef + cast(r.StartDate as nvarchar) = @CurrCSRef + @CurrDate THEN GETDATE() ELSE RunStartTime_Part4 END, RunStartTime_Part3, RunStartTime_Part2,  ISNULL(RunStartTime_Part1, RunStartTime))), 0)
	   , 108) RunTime
	   , CONVERT(VARCHAR(8), @ETA, 108) AS AvgTime
	   , CONVERT(VARCHAR(8), DATEADD(SECOND, DATEDIFF(second, 0, @ETA)*@remaining, 0), 108) AS ETA
	   , CONVERT(VARCHAR(8), @totalruntime, 108) as TotalRunTime
	    , *
    FROM MI.Campaign_Log l
    JOIN MI.CampaignReportLog r on r.ClientServicesRef = l.Parameter_ClientServicesRef 
	   and r.StartDate = l.Parameter_StartDate
	   and StoreProcedureName like case ExtendedPeriod when 1 then '%LTE_Calculate%' else '%Results_Calculate%' end
    WHERE cast(RunStartTime as date) = cast(getdate() as date)
    ORDER BY ID Desc

END
