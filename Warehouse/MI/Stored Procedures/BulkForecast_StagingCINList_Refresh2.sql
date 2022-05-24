/**********************************************************************

	Author:		 Hayden Reid
	Create date: 30/11/2015
	Description: Gets list of Customer CINIDS that have spent in brand to use in SSIS Data Flow

	======================= Change Log =======================

***********************************************************************/
CREATE PROCEDURE [MI].[BulkForecast_StagingCINList_Refresh2] 
	
AS
BEGIN

    DECLARE @EndLastMonth date = dateadd(month, datediff(month, 0, GETDATE())-1, 0)
    DECLARE @Start12Months date = DATEADD(month, -11, @EndLastMonth)
    DECLARE @Start6Months date = DATEADD(month, -5, @EndLastMonth)
    DECLARE @End6MonthsPrior date = DATEADD(d, -1, @Start6Months)
    
    SET @EndLastMonth = EOMONTH(@EndLastMonth)

    SELECT DISTINCT 
	   c.CINID
	   , cc.BrandID
	   , hc.isLapsed
    FROM Relational.ConsumerTransaction ct with (nolock)
    JOIN MI.BulkForecast_ActiveCINID c on c.CINID = ct.CINID
    JOIN MI.BulkForecast_BrandCC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    JOIN MI.BulkForecast_Options hc on hc.brandID = cc.BrandID and hc.SpendThreshold > ct.Amount
    WHERE @Start6Months <= ct.TranDate and @EndLastMonth >= ct.TranDate
	   AND hc.isLapsed = 1
END