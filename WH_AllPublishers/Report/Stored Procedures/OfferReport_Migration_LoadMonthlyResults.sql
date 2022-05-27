CREATE PROCEDURE [Report].[OfferReport_Migration_LoadMonthlyResults]
AS
BEGIN

	DECLARE @Date DATETIME2(7) = GETDATE()

	INSERT INTO [WH_AllPublishers].[Derived].[OfferReport_Results_Monthly_Archive]
	SELECT	ExposedSales
		,	ControlSales
		,	Cardholders_E
		,	MonthDate
		,	RetailerID
		,	ChannelType
		,	ArchivedDate = @Date
	FROM [WH_AllPublishers].[Derived].[OfferReport_Results_Monthly]

	TRUNCATE TABLE [WH_AllPublishers].[Derived].[OfferReport_Results_Monthly]
	INSERT INTO [WH_AllPublishers].[Derived].[OfferReport_Results_Monthly]
	SELECT	ExposedSales
		,	ControlSales
		,	Cardholders_E
		,	MonthDate
		,	RetailerID
		,	ChannelType
	FROM [lsRewardBI].[AllPublisherWarehouse].[BI].[Migration_OfferReport_Results_Monthly]

END