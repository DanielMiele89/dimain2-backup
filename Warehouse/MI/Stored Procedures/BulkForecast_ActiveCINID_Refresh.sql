/**********************************************************************

	Author:		 Hayden Reid
	Create date: 30/11/2015
	Description: Gets list of Active Customer CINIDS to use in SSIS Data Flow

	======================= Change Log =======================

***********************************************************************/
CREATE PROCEDURE [MI].[BulkForecast_ActiveCINID_Refresh] 
	
AS
BEGIN
    IF OBJECT_ID('MI.BulkForecast_ActiveCINID') IS NOT NULL DROP TABLE MI.BulkForecast_ActiveCINID
    CREATE TABLE MI.BulkForecast_ActiveCINID
    (
	  CINID int not null
	  CONSTRAINT [PK_BulkForecast_ActiveCINID] PRIMARY KEY CLUSTERED
	   (
		  CINID ASC
	   )
    )

    SELECT DISTINCT
	   cl.CINID
    FROM Relational.Customer c
    JOIN Relational.CINLIst cl on cl.CIN = c.SourceUID
    LEFT JOIN MI.CINDuplicate cd on cd.CIN = c.SourceUID
    WHERE c.CurrentlyActive = 1 and cd.CIN is null
END

