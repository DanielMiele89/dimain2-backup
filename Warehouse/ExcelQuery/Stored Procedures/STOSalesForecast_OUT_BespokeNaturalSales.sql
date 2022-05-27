
/*=================================================================================================
Uploading the Data from Excel
Part 1: Running Bespoke Natural Sales
Version 1: 
=================================================================================================*/



CREATE PROCEDURE [ExcelQuery].[STOSalesForecast_OUT_BespokeNaturalSales] 
WITH EXECUTE AS OWNER
AS
BEGIN

select distinct * from ExcelQuery.STOSales_BespokeNaturalSales

truncate table ExcelQuery.STOSales_BespokeNaturalSales

END