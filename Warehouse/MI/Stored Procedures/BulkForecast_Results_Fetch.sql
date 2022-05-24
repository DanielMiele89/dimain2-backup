/**********************************************************************

	Author:		 Hayden Reid
	Create date: 30/11/2015
	Description: Fetches Results for BulkForecasting for Direct Marketing

	======================= Change Log =======================

***********************************************************************/
CREATE PROCEDURE [MI].[BulkForecast_Results_Fetch] 
	
AS
BEGIN

    SELECT
	   b.BrandName,
	   CustomerCount,
	   (CAST(CustomerCount as numeric)/cast(TotalActivatedBase as numeric))*100
	   Split	       
    FROM MI.BulkForecast_Results r
    JOIN Relational.Brand b on b.BrandID = r.BrandID

END