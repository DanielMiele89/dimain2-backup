/**********************************************************************

	Author:		 Hayden Reid
	Create date: 30/11/2015
	Description: Insert ComsumerCombinations to be processed for selected brands 
	in the _Options table

	======================= Change Log =======================

***********************************************************************/
CREATE PROCEDURE [MI].[BulkForecast_ConsumerCombination_Refresh] 
	
AS
BEGIN
    -- Get list of ConsumerCombinations for Brands
    IF OBJECT_ID('MI.BulkForecast_BrandCC') IS NOT NULL DROP TABLE MI.BulkForecast_BrandCC
    CREATE TABLE MI.BulkForecast_BrandCC
    (
	  ConsumerCombinationID int not null,
	  BrandID int not null, 
	  CONSTRAINT [PK_BulkForecast_BrandCC] PRIMARY KEY CLUSTERED
	   (
		  ConsumerCombinationID ASC
	   )
    )

    INSERT INTO MI.BulkForecast_BrandCC
    SELECT DISTINCT
	   cc.ConsumerCombinationID
	   , cc.BrandID
    FROM Relational.ConsumerCombination cc with (nolock)
    JOIN MI.BulkForecast_Options hc on hc.brandID = cc.BrandID

    CREATE NONCLUSTERED INDEX [IX_NCL_BrandCC_BrandID] ON MI.BulkForecast_BrandCC ( BrandID )


    -- Get list of ConsumerCombinations for Competitors
    IF OBJECT_ID('MI.BulkForecast_CompetitorCC') IS NOT NULL DROP TABLE MI.BulkForecast_CompetitorCC
    CREATE TABLE MI.BulkForecast_CompetitorCC
    (
	  ConsumerCombinationID int not null,
	  CompetitorBrandID int not null, 
	  Brand int not null,
	  CONSTRAINT [PK_BulkForecast_CompetitorCC] PRIMARY KEY CLUSTERED
	   (
		  ConsumerCombinationID ASC
	   )
    )
    INSERT INTO MI.BulkForecast_CompetitorCC
    SELECT DISTINCT
	   cc.ConsumerCombinationID
	   , hc.BrandID
	   , cc.BrandID
    FROM Relational.ConsumerCombination cc with (nolock)
    JOIN MI.BulkForecast_Options hc on hc.competitorID = cc.BrandID

    CREATE NONCLUSTERED INDEX [IX_NCL_CompetitorCC_BrandID] ON MI.BulkForecast_CompetitorCC ( BrandID )


    -- Get list of ConsumerCombinations for Sectors
    IF OBJECT_ID('MI.BulkForecast_SectorCC') IS NOT NULL DROP TABLE MI.BulkForecast_SectorCC
    CREATE TABLE MI.BulkForecast_SectorCC
    (
	  ConsumerCombinationID int not null,
	  BrandID int not null, 
	  SectorID int not null,
	  CONSTRAINT [PK_BulkForecast_SectorCC] PRIMARY KEY CLUSTERED
	   (
		  ConsumerCombinationID ASC
	   )
    )
    INSERT INTO MI.BulkForecast_SectorCC
    SELECT DISTINCT
	   cc.ConsumerCombinationID
	   , hc.BrandID
	   , b.SectorID
    FROM Relational.ConsumerCombination cc with (nolock)
    JOIN Relational.brand b on b.BrandID = cc.BrandID
    JOIN MI.BulkForecast_Options hc on hc.sectorID = b.SectorID

    CREATE NONCLUSTERED INDEX [IX_NCL_SectorCC_BrandID] ON MI.BulkForecast_SectorCC ( BrandID )

END