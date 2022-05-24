/**********************************************************************

	Author:		 Hayden Reid
	Create date: 30/11/2015
	Description: Refreshes results table for various forecasting options

	======================= Change Log =======================

***********************************************************************/
CREATE PROCEDURE [MI].[BulkForecast_Results_Refresh] 
	
AS
BEGIN

    DECLARE @TaB int
       
    DECLARE @EndLastMonth date = dateadd(month, datediff(month, 0, GETDATE())-1, 0)
    DECLARE @Start12Months date = DATEADD(month, -11, @EndLastMonth)
    DECLARE @Start6Months date = DATEADD(month, -5, @EndLastMonth)
    DECLARE @End6MonthsPrior date = DATEADD(d, -1, @Start6Months)

    SET @EndLastMonth = EOMONTH(@EndLastMonth)

    SELECT @TaB = count(1) FROM Relational.Customer where CurrentlyActive = 1

    IF OBJECT_ID('MI.BulkForecast_Results') IS NOT NULL DROP TABLE MI.BulkForecast_Results
    CREATE TABLE MI.BulkForecast_Results
    (
	   ID int IDENTITY(1,1) not null,
	   BrandID int not null,
	   CustomerCount int not null,
	   TotalActivatedBase int not null,
	   Split nvarchar(1000) not null,
	   SpendThreshold money not null,
	   CONSTRAINT [PK_BulkForecast_Results] PRIMARY KEY CLUSTERED
	   (
		  ID ASC
	   )
    )

    -- Count customers that have spent with competitor but not with brand
    INSERT INTO MI.BulkForecast_Results (BrandID, CustomerCount, TotalActivatedBase, Split, SpendThreshold)
    SELECT
	   f.BrandID
	   , count(DISTINCT f.CINID) CustomerCount
	   , @TaB as TotalActivatedBase
	   , STUFF(
		  (
			 SELECT ',' + hb.BrandName
			 FROM MI.BulkForecast_Options h
			 JOIN Relational.Brand hb on hb.BrandID = h.competitorID
			 WHERE h.brandID = f.BrandID
			 FOR XML PATH ('')
		  ), 1, 1, ''
	   ) as Split
	   , f.SpendThreshold
    FROM MI.BulkForecast_NonSpenderCINID f
    JOIN MI.BulkForecast_CompetitorCC comp on comp.Brand = f.brandid
    JOIN Relational.ConsumerTransaction ct with (nolock) on comp.ConsumerCombinationID = ct.ConsumerCombinationID and ct.CINID = f.CINID
    WHERE f.isLapsed = 0 and @Start12Months <= ct.TranDate and @EndLastMonth >= ct.TranDate
    GROUP BY f.BrandID, f.SpendThreshold



    -- Count customers that have spent in sector but not in brand
    INSERT INTO MI.BulkForecast_Results (BrandID, CustomerCount, TotalActivatedBase, Split, SpendThreshold)
    SELECT 
	   f.BrandID
	   , count(DISTINCT f.CINID) CustomerCount
	   , @TaB as TotalActivatedBase
	   , bs.SectorName as Split
	   , f.SpendThreshold
    FROM MI.BulkForecast_NonSpenderCINID f
    JOIN MI.BulkForecast_SectorCC sc on sc.BrandID = f.BrandID
    JOIN Relational.ConsumerTransaction ct with (nolock) on sc.ConsumerCombinationID = ct.ConsumerCombinationID and ct.Amount > f.SpendThreshold
    JOIN Relational.BrandSector bs on bs.SectorID = sc.SectorID
    WHERE f.isLapsed = 0 and @Start12Months <= ct.TranDate and @EndLastMonth >= ct.TranDate and ct.Amount > f.SpendThreshold and ct.CINID = f.CINID
    GROUP BY f.BrandID, bs.SectorName, f.SpendThreshold

    -- Count customers that have not spent in 6 months with brand but have in prior 6 months
    INSERT INTO MI.BulkForecast_Results (BrandID, CustomerCount, TotalActivatedBase, Split, SpendThreshold)
    SELECT 
	   f.BrandID
	   , count(DISTINCT f.CINID) CustomerCount
	   , @TaB as TotalActivatedBase
	   , 'Lapsed' as Split
	   , f.SpendThreshold
    FROM MI.BulkForecast_NonSpenderCINID f
    JOIN MI.BulkForecast_Options hc on hc.brandID = f.BrandID
    JOIN Relational.ConsumerTransaction ct with (nolock) on ct.CINID = f.CINID
    WHERE f.isLapsed = 1 and @Start12Months <= ct.TranDate and @End6MonthsPrior >= ct.TranDate
    GROUP BY f.BrandID, f.SpendThreshold


    INSERT INTO MI.BulkForecast_Results (BrandID, CustomerCount, TotalActivatedBase, Split)
    select 405, count(SourceUID), @TaB, 'Number of Students' from relational.Customer c
    join relational.cinList cl on cl.CIN = c.SourceUID
    left join MI.CINDuplicate cd on cd.Cin = c.SourceUID
    join relational.cameo ca on ca.Postcode = c.postcode 
	   and ca.CAMEO_CODE in ('01A', '01B', '01C','02A','04A','05A','06A','07A','08B','08C','09A','09D')
    where AgeCurrentBandNumber = 1
	   and c.CurrentlyActive = 1
	   and cd.Cin is Null


END



