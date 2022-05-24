-- =============================================
-- Author:Dorota
-- Create date:16/09/2015
-- Description: Booking Calendar Population
-- =============================================

CREATE PROCEDURE [ExcelQuery].[BookingCal_Insert_Offers]
(
@CalendarYear INT,
@ClientServicesRef VARCHAR(40), 
@CampaignName VARCHAR(100), 
@CampaignType VARCHAR(100), 
@PartnerID INT, 
@BrandID INT,
@MinOfferRate  NUMERIC(7,4),
@MaxOfferRate NUMERIC(7,4),
@MinSS MONEY,
@MaxSS MONEY,
@StartDate DATE,
@Enddate DATE,
@DateForecastExpected DATE,
@DateBriefSubmitted DATE,
@ApprovedByRetailer INT,
@ApprovedByRBSG INT,
@MarketingSupport VARCHAR(100),
@EmailTesting VARCHAR(100),
@ATL INT,
@CurrentDate DATETIME)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Warehouse.ExcelQuery.BookingCal_Offers
	SELECT @CalendarYear,
		  @ClientServicesRef, 
		  @CampaignName, 
		  @CampaignType, 
		  @PartnerID, 
		  @BrandID,
		  @MinOfferRate,
		  @MaxOfferRate,
		  @MinSS,
		  @MaxSS,
		  @StartDate,
		  @Enddate,
		  @DateForecastExpected,
		  @DateBriefSubmitted,
		  @ApprovedByRetailer,
		  @ApprovedByRBSG,
		  @MarketingSupport,
		  @EmailTesting,
		  @ATL,
		  @CurrentDate
END