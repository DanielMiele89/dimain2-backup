/***************************************************************************
Author:	Sandbox.Hayden Reid
Date: 17/03/2015
Purpose: Returns results from report table with no missing dates/retailers (OPRBS-37)
***************************************************************************/
CREATE PROCEDURE [Prototype].[ClientMetric_ReportFetch]
AS
BEGIN

    ;WITH Retailers
    AS
    (
	   SELECT DISTINCT Retailer, Forecast
	   FROM (SELECT DISTINCT Retailer from Sandbox.Hayden.ClientMetrics) x
	   CROSS JOIN (Select Distinct forecast from Sandbox.Hayden.ClientMetrics) y
    )
    , Dates
    AS 
    (
	   SELECT DISTINCT [Date]
	   FROM Sandbox.Hayden.ClientMetrics
    )
    , Clubs
    AS
    (
	   SELECT DISTINCT Club
	   FROM Sandbox.Hayden.ClientMetrics
    )
    , Merged
    AS 
    (
	   SELECT *
	   FROM Dates
	   CROSS JOIN Retailers
	   CROSS JOIN Clubs
    )
    , Colours
    AS
    (
	   SELECT * FROM 
	   (
		  VALUES
			 ('MyRewards', '#4b196e')
			 , ('Quidco', '#0ab4f0')
	   ) c(Club, HexCode)
    )
    SELECT DISTINCT
	   m.Retailer
	   , m.[Date]
	   , COALESCE(Value, 0) AS Value
	   , m.Club
	   , COALESCE(m.Forecast, CASE WHEN ( m.Date >= CAST(GETDATE() as DATE) OR MONTH(m.Date) = MONTH(GETDATE()) ) THEN 0 ELSE 1 END ) AS Forecast
	   , co.HexCode
    FROM Merged m
    JOIN Colours co on co.Club = m.Club
    LEFT JOIN Sandbox.Hayden.ClientMetrics c on m.Date = c.Date 
	   and m.Retailer = c.Retailer 
	   and m.Club = c.Club
	   and m.Forecast = c.Forecast
    WHERE ( ( m.Date >= CAST(DATEADD(m, -1, EOMONTH(GETDATE())) as DATE) ) AND (m.Forecast = 1)
	  OR ( ( m.Date < CAST(DATEADD(m, -1, EOMONTH(GETDATE())) as DATE)  ) AND m.Forecast = 0 ) )
    ORDER BY m.Club, m.Retailer,m.date

END



