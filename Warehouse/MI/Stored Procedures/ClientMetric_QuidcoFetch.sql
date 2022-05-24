/***************************************************************************
Author:	Hayden Reid
Date: 17/03/2015
Purpose: Adds new quidco actual values (OPRBS-37)
***************************************************************************/
CREATE PROCEDURE [MI].[ClientMetric_QuidcoFetch]
AS
BEGIN
    
    DECLARE @EndDate date = EOMONTH(DATEADD(month, -1, GETDATE()))
    DECLARE @StartDate date = DATEADD(day, 1, EOMONTH(DATEADD(month, -2, GETDATE())))

    --select @startdate, @EndDate
    
    INSERT INTO Warehouse.MI.ClientMetric_QuidcoActuals

    SELECT
	    REPLACE(REPLACE(y.Tbl_PartnerName,' (DGM)', ''),' (TD)', '')
	    , DATEFROMPARTS(YEAR(Date), MONTH(Date), '01') as Month
	    , CAST(SUM(CONVERT(decimal(10, 2), ISNULL(NetCom,0))) AS nvarchar)
    FROM SLC_Report.dbo.il_MerchantAdmin_ClubFinancialStats(12,0,@StartDate,@EndDate) x 
    JOIN Warehouse.MI.ClientMetric_Exceptions y on y.PartnerName = x.PartnerName or y.Tbl_PartnerName = x.PartnerName
    WHERE NOT EXISTS (
	   SELECT 1 FROM MI.ClientMetric_QuidcoActuals qa
	   WHERE qa.Retailer = y.Tbl_PartnerName 
		  AND qa.Date = DATEFROMPARTS(Year(Date), MONTH(date), '01')
    )
    GROUP BY y.Tbl_PartnerName, DATEFROMPARTS(YEAR(Date), MONTH(Date), '01')

END