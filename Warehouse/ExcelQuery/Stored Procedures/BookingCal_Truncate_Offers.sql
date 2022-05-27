-- =============================================
-- Author:Dorota
-- Create date:16/09/2015
-- Description: Booking Calendar Population
-- =============================================

CREATE PROCEDURE [ExcelQuery].[BookingCal_Truncate_Offers]
AS
BEGIN
	SET NOCOUNT ON;
	DELETE FROM Warehouse.ExcelQuery.BookingCal_Offers	
END
