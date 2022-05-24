
/*=================================================================================================
Uploading the Data from Excel
Part 1: Running Bespoke Natural Sales
Version 1: 
=================================================================================================*/



CREATE PROCEDURE [ExcelQuery].[STOSalesForecast_OUT_BespokeNaturalGroupsNames] 
WITH EXECUTE AS OWNER
AS
BEGIN

select distinct customer_type from ExcelQuery.STOSales_BespokeCustomerGroups

truncate table ExcelQuery.STOSales_BespokeCustomerGroups

END
