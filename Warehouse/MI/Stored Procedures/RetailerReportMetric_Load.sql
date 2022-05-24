
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <04/11/2014>
-- Description:	<Loads RetailerReportMetric >
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetric_Load] (@DateID int, @PartnerID INT = NULL)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
--	declare @DateID as int
--set @DateID = 33

insert into [MI].[RetailerReportMetric]
      ([ProgramID]
      ,[PartnerGroupID]
      ,[PartnerID]
      ,[ClientServiceRef]
      ,[PaymentTypeID]
      ,[ChannelID]
      ,[CustomerAttributeID]
      ,[Mid_SplitID]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,[DateID]
      ,[CurrencyID]
      ,[CurrencyAdj]
      ,[Cardholders]
      ,[Sales]
      ,[Transactions]
      ,[Spenders]
      ,[Commission]
      )


  SELECT DISTINCT
      [Programid]
      ,[PartnerGroupID]
      ,[PartnerID]
      ,[ClientServiceRef]
      ,[PaymentTypeID]
      ,[ChannelID]
      ,[CustomerAttributeID]
      ,[Mid_SplitID]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,[DateID]
	  ,0 as [CurrencyID]
      ,0 as [CurrencyAdj]
	  ,[Cardholders]
      ,[INSchemeSales] as [Sales]
      ,[INSchemeTransactions] as [UpliftTransactions]
      ,[INSchemeSpenders] as [Spenders]
      ,[Commission]
FROM [MI].[INSchemeSalesWorking]
where DateID = @DateID and Cardholders>0
AND (@PartnerID IS NULL OR PartnerID = @PartnerID)


--ALTER TABLE Warehouse_Dev.MI.RetailerReportMetric ALTER COLUMN FinancialROI money NULL
END