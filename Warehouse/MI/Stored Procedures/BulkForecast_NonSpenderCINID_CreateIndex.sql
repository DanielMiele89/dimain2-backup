/**********************************************************************

	Author:		 Hayden Reid
	Create date: 30/11/2015
	Description: Creates Index for table after SSIS Data Flow insert

	======================= Change Log =======================

***********************************************************************/
CREATE PROCEDURE [MI].[BulkForecast_NonSpenderCINID_CreateIndex] 
	
AS
BEGIN

    CREATE NONCLUSTERED INDEX [IX_NCL_BulkForecast_BrandID] ON MI.BulkForecast_NonSpenderCINID ( BrandID )
    CREATE NONCLUSTERED INDEX [IX_NCL_BulkForecast_CINID] ON MI.BulkForecast_NonSpenderCINID ( CINID )

END