-- =============================================
-- Author:Dorota
-- Create date:16/09/2015
-- Description: Booking Calendar Population
-- =============================================

CREATE PROCEDURE [ExcelQuery].[BookingCal_Insert_ForecastWave]
(
@ClientServicesRef VARCHAR(40)
,@StartDate DATE
,@EndDate DATE
,@TargetedVolume INT
,@ControlVolume INT
,@CustomerBaseType INT
,@Base INT
,@AvgOfferRate REAL
,@TotalSales MONEY
,@QualyfingSales MONEY
,@TotalIncrementalSales MONEY
,@WeeklySpenders INT
,@TotalSpenders INT
,@QualyfingSpenders INT
,@TotalIncrementalSpenders INT
,@TotalCashback MONEY
,@TotalOverride MONEY
,@QualyfingCashback MONEY
,@QualyfingOverride MONEY
,@LengthWeeks INT
,@ForecastSubmissionDate DATETIME
,@RetailerType VARCHAR(40))

AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Warehouse.ExcelQuery.BookingCal_ForecastWave
	SELECT  @ClientServicesRef 
		  ,@StartDate 
		  ,@EndDate 
		  ,@TargetedVolume 
		  ,@ControlVolume 
		  ,@CustomerBaseType 
		  ,@Base
		  ,@AvgOfferRate
		  ,@TotalSales
		  ,@QualyfingSales
		  ,@TotalIncrementalSales
		  ,@WeeklySpenders
		  ,@TotalSpenders
		  ,@QualyfingSpenders
		  ,@TotalIncrementalSpenders
		  ,@TotalCashback
		  ,@TotalOverride
		  ,@QualyfingCashback
		  ,@QualyfingOverride
		  ,@LengthWeeks
		  ,@ForecastSubmissionDate
		  ,@RetailerType
    WHERE NOT EXISTS (SELECT 1 FROM Warehouse.ExcelQuery.BookingCal_ForecastWave
    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND EndDate=@EndDate)
END
