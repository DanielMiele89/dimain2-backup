-- =============================================
-- Author:		JEA
-- Create date: 04/10/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[RetailerUpliftStats_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthlyDate DATE

	SET @MonthlyDate = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))

	SELECT a.PartnerID AS RetailerID
		, @MonthlyDate AS MonthDate
		, CAST(NULL AS bit) AS ChannelType
		, Sales - IncSales AS ControlSales
		, Spenders - IncSpenders AS ControlSpenderCount
		, Transactions - IncTrans AS ControlTranCount
		, IncSales AS IncrementalSales
		, IncSpenders AS IncrementalSpenderCount
		, IncTrans AS IncrementalTranCount
	FROM MI.OfferReport_Aggregate a
	LEFT OUTER JOIN APW.PartnerAlternate p ON a.PartnerID = p.PartnerID
	WHERE a.MonthlyDate = @MonthlyDate
	AND a.OfferID IS NULL
	AND a.Channel IS NULL

	UNION ALL

	SELECT a.PartnerID AS RetailerID
		, @MonthlyDate AS MonthDate
		, CAST(0 AS bit) AS ChannelType
		, Sales - IncSales AS ControlSales
		, Spenders - IncSpenders AS ControlSpenderCount
		, Transactions - IncTrans AS ControlTranCount
		, IncSales AS IncrementalSales
		, IncSpenders AS IncrementalSpenderCount
		, IncTrans AS IncrementalTransactionCount
	FROM MI.OfferReport_Aggregate a
	LEFT OUTER JOIN APW.PartnerAlternate p ON a.PartnerID = p.PartnerID
	WHERE a.MonthlyDate = @MonthlyDate
	AND a.Channel = 0
	AND a.OfferID IS NULL

	UNION ALL

	SELECT a.PartnerID AS RetailerID
		, @MonthlyDate AS MonthDate
		, CAST(1 AS bit) AS ChannelType
		, Sales - IncSales AS ControlSales
		, Spenders - IncSpenders AS ControlSpenderCount
		, Transactions - IncTrans AS ControlTranCount
		, IncSales AS IncrementalSales
		, IncSpenders AS IncrementalSpenderCount
		, IncTrans AS IncrementalTransactionCount
	FROM MI.OfferReport_Aggregate a
	LEFT OUTER JOIN APW.PartnerAlternate p ON a.PartnerID = p.PartnerID
	WHERE a.MonthlyDate = @MonthlyDate
	AND a.Channel = 1
	AND a.OfferID IS NULL

END