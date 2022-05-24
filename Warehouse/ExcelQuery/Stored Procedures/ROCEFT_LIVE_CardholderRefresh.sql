
-- =============================================
-- Author:		Shaun Hide
-- Create date: 01/02/2019
-- Description:	Refresh all the Cardholder Count as needed
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_LIVE_CardholderRefresh]
	(
		@BrandList VARCHAR(500)
	)    
AS
BEGIN
	SET NOCOUNT ON;

	-- Cardholder Table Refresh
	EXEC [ExcelQuery].[ROCEFT_LIVE_Cardholder_Calculate]

	-- ETL Process to port to RewardBI
	EXEC ExcelQuery.ROCForecastingTool_ETL_StartJob 
END