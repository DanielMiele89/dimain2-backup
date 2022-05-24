
/*=================================================================================================
Uploading the Data from Excel
Part 1: Data Upload
Version 1: 
=================================================================================================*/



CREATE PROCEDURE [ExcelQuery].[STOSalesForecast_Upload2]
(                                                      @brandID as INT
                                                      ,@ALeng as INT
													  ,@LLeng INT
													  ,@Cameo1   as            VARCHAR(200)
                                                      ,@Cameo2   as            VARCHAR(200)  
                                                      ,@Cameo3   as            VARCHAR(200)  
                                                      ,@Cameo4   as            VARCHAR(200)  
                                                      ,@Cameo5   as            VARCHAR(200)  
                                                      ,@Cameo6   as            VARCHAR(200)  
                                                      ,@Cameo7   as            VARCHAR(200)  
                                                      ,@Cameo8   as            VARCHAR(200)  
                                                      ,@Cameo9   as            VARCHAR(200)  
                                                      ,@Cameo10   as            VARCHAR(200)  
                                                      ,@Cameo11  as            VARCHAR(200)  
                                                      ,@Cameo12  as            VARCHAR(200)  
													,@Region1 as VARCHAR(50)
													,@Region2 as VARCHAR(50)
													,@Region3 as VARCHAR(50)
													,@Region4 as VARCHAR(50)
													,@Region5 as VARCHAR(50)
													,@Region6 as VARCHAR(50)
													,@Region7 as VARCHAR(50)
													,@Region8 as VARCHAR(50)
													,@Region9 as VARCHAR(50)
													,@Region10 as VARCHAR(50)
													,@Region11 as VARCHAR(50)
													,@Region12 as VARCHAR(50)
													,@Region13 as VARCHAR(50)
													,@Gender1 as VARCHAR(10)
													,@Gender2 as VARCHAR(10)
													,@Gender3 as VARCHAR(10)
													,@Age1 as VARCHAR(50)
													,@Age2 as VARCHAR(50)
													,@Age3 as VARCHAR(50)
													,@Age4 as VARCHAR(50)
													,@Age5 as VARCHAR(50)
													,@Age6 as VARCHAR(50)
													,@Age7 as VARCHAR(50)
													,@Age8 as VARCHAR(50)
													,@Heatmap as int
													,@Segmentname as varchar (200)
													,@Comp1 as INT
													,@Comp2 as INT
													,@Comp3 as INT
													,@Comp4 as INT
													,@Comp5 as INT
													,@Comp6 as INT
													,@Comp7 as INT
													,@Comp8 as INT
													,@Comp9 as INT
													,@Comp10 as INT
													,@Comp11 as INT
													,@Comp12 as INT
													,@Comp13 as INT
													,@Comp14 as INT
													,@Comp15 as INT
												   )

WITH EXECUTE AS OWNER
AS
BEGIN
       SET NOCOUNT ON;

truncate table Warehouse.ExcelQuery.STOSalesForecast_BespokeInputCameo

insert into ExcelQuery.STOSalesForecast_BespokeInputCameo
Values  (@cameo1), (@Cameo2), (@Cameo3), (@Cameo4), (@Cameo5) ,(@Cameo6),(@Cameo7)  ,(@Cameo8),(@Cameo9) ,(@Cameo10),(@Cameo11),(@cameo12)

truncate table Warehouse.ExcelQuery.STOSalesForecast_BespokeInputOther

insert into ExcelQuery.STOSalesForecast_BespokeInputOther
select @brandID
       ,@ALeng
	   ,@LLeng
	   ,@Heatmap
	   ,@Segmentname
truncate table Warehouse.ExcelQuery.STOSalesForecast_BespokeInputRegion



insert into ExcelQuery.STOSalesForecast_BespokeInputRegion
Values  (@Region1), (@Region2), (@Region3), (@Region4), (@Region5) ,(@Region6),(@Region7)  ,(@Region8),(@Region9) ,(@Region10),(@Region11),(@Region12),(@Region13)


truncate table Warehouse.ExcelQuery.STOSalesForecast_BespokeInputAgeGroup

insert into ExcelQuery.STOSalesForecast_BespokeInputAgeGroup
Values  (@Age1), (@Age2), (@Age3), (@Age4), (@Age5) ,(@Age6),(@Age7)  ,(@Age8)

truncate table Warehouse.ExcelQuery.STOSalesForecast_BespokeInputGender

insert into ExcelQuery.STOSalesForecast_BespokeInputGender
Values  (@Gender1), (@Gender2), (@Gender3)

truncate table Warehouse.ExcelQuery.STOSalesForecast_BespokeCompetitors

insert into ExcelQuery.STOSalesForecast_BespokeCompetitors
Values (@Comp1), (@Comp2) , (@Comp3) ,(@Comp4) ,(@Comp5)  ,(@Comp6)  ,(@Comp7) ,(@Comp8) ,(@Comp9) ,(@Comp10),(@Comp11)  ,(@Comp12) ,(@Comp13) ,(@Comp14) ,(@Comp15)

END
;