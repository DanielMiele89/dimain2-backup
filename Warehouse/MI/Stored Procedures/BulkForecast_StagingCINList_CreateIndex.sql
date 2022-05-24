/**********************************************************************

	Author:		 Hayden Reid
	Create date: 30/11/2015
	Description: Creates Index after Table has been inserted into

	======================= Change Log =======================

***********************************************************************/
CREATE PROCEDURE [MI].[BulkForecast_StagingCINList_CreateIndex] 
	
AS
BEGIN

    CREATE NONCLUSTERED INDEX [IX_NCL_CINList_CINID] ON MI.BulkForecast_StagingCINList ( CINID )
    CREATE NONCLUSTERED INDEX [IX_NCL_CINList_BrandID] ON MI.BulkForecast_StagingCINList ( BrandID )

END

