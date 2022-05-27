-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Insert Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Insert_MasterRetailerTable]
(@PartnerID AS INT,	@Tier AS INT, @Margin AS FLOAT, @CS_Lead_ID AS INT, @CS_Support_ID AS INT, @D_I_Lead_ID AS INT,	@D_I_Support_ID AS INT,
@Core AS CHAR(1), @Override_Pct_of_CBP AS FLOAT, @Term AS NVARCHAR(255), @Advertised_Launch_Date AS DATETIME,	@Date_of_Last_Signature AS DATETIME, 
@Last_Date_Notice_Can_Be_Served AS DATETIME, @Next_Termination_Date AS DATETIME, @Exclusivity_Agreed AS NVARCHAR(255), @ROI_Type AS NVARCHAR(255),
@Contractual_ROI AS	NVARCHAR(255), @Contractual_Sales_Uplift AS NVARCHAR(255),	@Target_Sales_Uplift AS NVARCHAR(255), 
@Annual_Num_of_Tactical_WOWs AS INT, @Annual_Num_of_Strategic_WOWs AS INT, @Avg_Offer_Rate AS FLOAT, @Overall_Blended_Rate AS FLOAT, 
@Annual_Insight_Budget AS MONEY, @Reporting_Start_MonthID AS INT)

AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [Warehouse].[Relational].[Master_Retailer_Table] 
	SELECT @PartnerID , @Tier, @Margin, @CS_Lead_ID, @CS_Support_ID, @D_I_Lead_ID,	@D_I_Support_ID,
	   @Core, @Override_Pct_of_CBP, @Term, @Advertised_Launch_Date,	@Date_of_Last_Signature, 
	   @Last_Date_Notice_Can_Be_Served, @Next_Termination_Date, @Exclusivity_Agreed, @ROI_Type,
	   @Contractual_ROI, @Contractual_Sales_Uplift, @Target_Sales_Uplift, 
	   @Annual_Num_of_Tactical_WOWs, @Annual_Num_of_Strategic_WOWs, @Avg_Offer_Rate, @Overall_Blended_Rate, 
	   @Annual_Insight_Budget, @Reporting_Start_MonthID
	WHERE NOT EXISTS (SELECT 1 FROM [Warehouse].[Relational].[Master_Retailer_Table] 
	WHERE PartnerID=@PartnerID)
END
