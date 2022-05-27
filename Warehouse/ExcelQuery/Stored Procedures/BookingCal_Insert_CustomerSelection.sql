-- =============================================
-- Author:Dorota
-- Create date:16/09/2015
-- Description: Booking Calendar Population
-- =============================================

CREATE PROCEDURE [ExcelQuery].[BookingCal_Insert_CustomerSelection]
(
@ClientServicesRef VARCHAR(40)
,@StartDate DATE
,@EndDate DATE
,@SegmentID VARCHAR(6)
,@Gender CHAR(1)
,@MinAge INT
,@MaxAge INT
,@DriveTimeBand VARCHAR(50)
,@CAMEO_CODE_GRP VARCHAR(200)
,@SocialClass NVARCHAR(2)
,@MinHeatMapScore INT
,@MAxHeatMapScore INT
,@BespokeTargeting INT
,@QualifyingMids INT
,@TargetedVolume INT
,@ControlVolume INT
,@TotalSpenders INT
,@QualyfingSpenders INT
,@TotalIncrementalSpednders INT
,@TotalSales MONEY
,@QualifyingSales MONEY
,@IncrementalSales MONEY	
,@ForecastSubmissionDate DATETIME
,@RetailerType VARCHAR(40))

AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Warehouse.ExcelQuery.BookingCal_CustomerSelection
     SELECT   @ClientServicesRef 
		  ,@StartDate 
		  ,@EndDate 
		  ,@SegmentID 
		  ,@Gender 
		  ,@MinAge 
		  ,@MaxAge 
		  ,@DriveTimeBand 
		  ,@CAMEO_CODE_GRP 
		  ,@SocialClass 
		  ,@MinHeatMapScore 
		  ,@MAxHeatMapScore 
		  ,@BespokeTargeting
		  ,@QualifyingMids 
		  ,@TargetedVolume 
		  ,@ControlVolume 
		  ,@TotalSpenders 
		  ,@QualyfingSpenders 
		  ,@TotalIncrementalSpednders 
		  ,@TotalSales 
		  ,@QualifyingSales 
		  ,@IncrementalSales	
		  ,@ForecastSubmissionDate 
		  ,@RetailerType 
    WHERE NOT EXISTS (SELECT 1 FROM Warehouse.ExcelQuery.BookingCal_CustomerSelection
    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND EndDate=@EndDate
    AND COALESCE(SegmentID ,'')=COALESCE(@SegmentID ,''))
END
