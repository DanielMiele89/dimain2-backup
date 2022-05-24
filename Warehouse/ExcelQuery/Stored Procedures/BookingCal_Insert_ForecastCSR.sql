-- =============================================
-- Author:Dorota
-- Create date:16/09/2015
-- Description: Booking Calendar Population
-- =============================================

CREATE PROCEDURE [ExcelQuery].[BookingCal_Insert_ForecastCSR]
(
@ClientServicesRef VARCHAR(40)
,@TargetedVolume INT
,@AvgOfferRate REAL
,@TotalSales MONEY
,@TotalIncrementalSales MONEY
,@TotalCashback MONEY
,@TotalOverride MONEY
,@QualyfingSales MONEY
,@QualyfingIncrementalSales MONEY
,@QualyfingCashback MONEY
,@QualyfingOverride MONEY
,@TotalSpenders INT
,@QualyfingSpenders INT
,@LengthWeeks INT
,@ForecastSubmissionDate DATETIME)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Warehouse.ExcelQuery.BookingCal_ForecastCSR
	SELECT  @ClientServicesRef 
		  ,@TargetedVolume 
		  ,@AvgOfferRate 
		  ,@TotalSales
		  ,@TotalIncrementalSales
		  ,@TotalCashback
		  ,@TotalOverride
		  ,@QualyfingSales
		  ,@QualyfingIncrementalSales
		  ,@QualyfingCashback
		  ,@QualyfingOverride
		  ,@TotalSpenders
		  ,@QualyfingSpenders
		  ,@LengthWeeks
		  ,@ForecastSubmissionDate
    WHERE NOT EXISTS (SELECT 1 FROM Warehouse.ExcelQuery.BookingCal_ForecastCSR
    WHERE ClientServicesRef=@ClientServicesRef)
END