

-- ******************************************************************************
-- Author: Suraj Chahal
-- Create date: 30/09/2015
-- Description: Runs Daily and Updates Relational.BookingCal tables
--		with latest data in ExcelQuery
-- ******************************************************************************
CREATE PROCEDURE [Staging].[BookingCal_Execute_UpdateScripts]
									
AS
BEGIN
	SET NOCOUNT ON;

EXEC Warehouse.Staging.BookingCal_Update_CustomerSelection
EXEC Warehouse.Staging.BookingCal_Update_ForecastCSR
EXEC Warehouse.Staging.BookingCal_Update_ForecastWave
EXEC Warehouse.Staging.BookingCal_Update_OfferDetails
EXEC Warehouse.Staging.BookingCal_Update_OfferApprovalDates
EXEC Warehouse.Staging.BookingCal_Update_OfferMarketingSettings

END