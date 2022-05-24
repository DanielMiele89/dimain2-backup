/**********************************************************************

	Author:		 Hayden Reid
	Create date: 30/11/2015
	Description: Gets all customers who have not spent in brand to be used
	in SSIS Data Flow

	======================= Change Log =======================

***********************************************************************/
CREATE PROCEDURE [MI].[BulkForecast_NonSpenderCINID_Refresh] 
	
AS
BEGIN

    IF OBJECT_ID('MI.BulkForecast_NonSpenderCINID') IS NOT NULL DROP TABLE MI.BulkForecast_NonSpenderCINID
    CREATE TABLE MI.BulkForecast_NonSpenderCINID
    (
	   ID int IDENTITY(1,1) not null,
	   CINID int not null,
	   BrandID int not null,
	   isLapsed bit not null,
	   SpendThreshold money not null,
	   CONSTRAINT [PK_BulkForecast_NonSpenderCINID] PRIMARY KEY CLUSTERED
	   (
		  ID ASC
	   )
    )
    SELECT c.CINID, x.BrandID, x.isLapsed, x.SpendThreshold
    FROM (
	   SELECT DISTINCT BrandID, hc.isLapsed, SpendThreshold FROM MI.BulkForecast_Options hc
    ) x
    CROSS JOIN MI.BulkForecast_ActiveCINID c
    WHERE NOT EXISTS(
	   SELECT 1 FROM MI.BulkForecast_StagingCINList cl
	   WHERE c.CINID = cl.CINID and x.brandID = cl.BrandID
    )

END



