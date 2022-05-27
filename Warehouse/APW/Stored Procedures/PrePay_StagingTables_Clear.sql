/******************************************************************************
Author: Ed A
Create date: 23/04/2019
Description:

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [APW].[PrePay_StagingTables_Clear] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE APW.PrePay_Retailer;
	TRUNCATE TABLE APW.PrePay_Partner;
	TRUNCATE TABLE APW.PrePay_RetailerUninvoicedTotal;	
	TRUNCATE TABLE APW.PrePay_MaxRetailerForecastWeighting;
	TRUNCATE TABLE Warehouse.APW.ForecastWeighting_Staging;

END