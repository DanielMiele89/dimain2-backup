/***************************************************************************
Author:	Hayden Reid
Date: 17/03/2015
Purpose: Cleans up Client Metric tables after SSIS Data Flow (OPRBS-37)
***************************************************************************/
CREATE PROCEDURE [Prototype].[ClientMetric_ReportRefresh]
AS
BEGIN

    DECLARE @StartDate date, @EndDate date

    SET @StartDate = '2015-05-01' -- Beginning of Financial Month

    TRUNCATE TABLE Sandbox.Hayden.ClientMetrics

    INSERT INTO Sandbox.Hayden.ClientMetrics (Retailer, Date, Value, Club, Forecast)

    SELECT Tbl_PartnerName, Dates, SUM(Override), Club, Forecast FROM (
	   SELECT 
		  y.Tbl_PartnerName
		  , CASE WHEN MONTH(DATEADD(DAY, 3, WeekDates + ' 2016')) <> MONTH(WeekDates + ' 2016') 
			 THEN DATEFROMPARTS('2016', MONTH(DATEADD(Month, 1, WeekDates + ' 2016')), '01') 
			 ELSE DATEFROMPARTS('2016', MONTH(WeekDates + '2016'), 01) 
		  END AS Dates
		  , cast(Override as money) as Override
		  , 'MyRewards' as Club
		  , 1 as Forecast
	   from Sandbox.Hayden.CampDashboard x
	   JOIN Sandbox.Hayden.ClientMetricExceptions y on y.PartnerName = x.Retailer or y.Tbl_PartnerName = x.Retailer
    ) x
    GROUP BY Tbl_PartnerName, Dates, Club, Forecast

    UNION ALL

    select 
	   y.Tbl_PartnerName
	   , cast(dateadd(d, substring(dates, PATINDEX('%[^A-Za-z]%', Dates)+1, 99)-2, '1900-01-01') as date) as Date
	   , Value
	   , 'MyRewards'
	   , 0
    from Sandbox.Hayden.FinanceXL x
    JOIN Sandbox.Hayden.ClientMetricExceptions y on y.PartnerName = x.Retailer or y.Tbl_PartnerName = x.Retailer
    where cast(dateadd(d, substring(dates, PATINDEX('%[^A-Za-z]%', Dates)+1, 99)-2, '1900-01-01') as date) >= @StartDate

    UNION ALL

    SELECT
	   Retailer
	   , Date
	   , Value
	   , 'Quidco'
	   , 0
    FROM Sandbox.Hayden.ClientMetrics_QuidcoActuals q
    LEFT JOIN Sandbox.Hayden.ClientMetricExceptions y on y.PartnerName = q.Retailer or y.Tbl_PartnerName = q.Retailer



    --SELECT
	   -- REPLACE(REPLACE(x.PartnerName,' (DGM)', ''),' (TD)', '')
	   -- , DATEFROMPARTS(YEAR(Date), MONTH(Date), '01') as Month
	   -- , CAST(SUM(CONVERT(decimal(10, 2), ISNULL(NetCom,0))) AS nvarchar)
	   -- , 'Quidco'
	   -- , 0
    --FROM SLC_Report.dbo.il_MerchantAdmin_ClubFinancialStats(12,0,@StartDate,'2016-04-30') x 
    --JOIN Sandbox.Hayden.ClientMetricExceptions y on y.PartnerName = x.PartnerName or y.Tbl_PartnerName = x.PartnerName
    --GROUP BY x.PartnerName, DATEFROMPARTS(YEAR(Date), MONTH(Date), '01')


END