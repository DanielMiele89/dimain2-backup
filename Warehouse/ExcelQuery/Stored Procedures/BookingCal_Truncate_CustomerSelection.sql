-- =============================================
-- Author:Dorota
-- Create date:16/09/2015
-- Description: Booking Calendar Population
-- =============================================

CREATE PROCEDURE [ExcelQuery].[BookingCal_Truncate_CustomerSelection]
AS
BEGIN
	SET NOCOUNT ON;
	DELETE FROM Warehouse.ExcelQuery.BookingCal_CustomerSelection	
END