-- =============================================
-- Author:		<Adam Scott>
-- Create date: <05/01/2015>
-- Description:	<ReportMectricQAStage2>
-- =============================================
CREATE PROCEDURE Mi.ReportMectricQAStage2 @dateid int
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--------------------------------------upliftsales related errors-----------------------------------

SELECT [ID]
      ,[ProgramID]
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
      ,[CurencyID]
      ,[CurencyAdj]
      ,[Cardholders]
      ,[Sales]
      ,[Transactions]
      ,[Spenders]
      ,[Commission]
      ,[UpliftSales]
      ,[UpliftTransactions]
      ,[UpliftSpenders]
      ,[IncrementalSales]
      ,[IncrementalTransactions]
      ,[IncrementalSpenders]
      ,[IncrementalMargin]
      ,[ATVUplift]
      ,[ATFUplift]
      ,[DriverTreeATVIncremental]
      ,[DriverTreeATFIncremental]
      ,[DriverTreeRRIncremental]
      ,[ATV]
      ,[ATF]
      ,[RR]
      ,[CostPerAcquisition]
      ,[TotalSalesROI]
      ,[IncrementalSalesROI]
      ,[FinancialROI]
      ,[SPSUplift]
      ,[Margin]
      ,[ContractROI]
      ,[ContractTargetUplift]
      ,[RewardTargetUplift]
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where Dateid = @dateid

END
