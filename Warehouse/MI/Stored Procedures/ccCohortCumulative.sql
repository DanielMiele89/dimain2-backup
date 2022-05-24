
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <27/01/2015>
-- Description:	<Cohorts cumlitive Fetch for reports>
-- =============================================
CREATE PROCEDURE [MI].[ccCohortCumulative] (@MonthID int, @PartnerID int)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @6MonthID int--, @MonthID int, @PartnerID int
--set @MonthID  = 36
--set @PartnerID =3960
set @6MonthID = @MonthID -5



SELECT RM.[Cardholders]
      ,RM.[PartnerID]
      ,CA.ReportDescription
      ,RM.CustomerAttributeID as [FirstMonth]
      ,RM.[dateid]
      ,RM.Spenders
      ,RM.[Sales]
      ,RM.[Transactions]
      ,RM.[Commission]
	--  ,SUTM.MonthDesc
	 into #Results
  FROM [MI].[RetailerReportMetric] RM
  inner join MI.RetailerMetricCustomerAttribute CA on RM.CustomerAttributeID = CA.CustomerAttributeID 
  where CumulativeTypeID = 2 and RM.DateID = @MonthID and PartnerID = @PartnerID and RM.CustomerAttributeID between @6MonthID+3000 and @MonthID+3000 and RM.PaymentTypeID = 0
    order by FirstMonth
select  isnull(R.Cardholders,0) AS Cardholders,
isnull(R.PartnerID,@PartnerID) AS PartnerID,
isnull(R.ReportDescription,SUTM.MonthDesc + ' Cohort') AS CohortDesc,
isnull(R.FirstMonth,SUTM.ID) AS FirstMonth,
isnull(R.DateID,@MonthID) AS ReportMonth,
isnull(R.Spenders,0) AS PostActiveSpenders,
isnull(R.Sales,0) AS PostActiveSales,
isnull(R.Transactions,0) AS PostActiveTransactions,
isnull(R.Commission,0) AS Commission,
--isnull(R.ActivatedSales,0) AS ActivatedSales,
--isnull(R.ActivatedTransactions,0) AS ActivatedTransactions,
--isnull(R.ActivatedSpenders,0) AS ActivatedSpenders,
--isnull(R.Cumulative,1) AS Cumulative,
SUTM.MonthDesc AS MonthDesc
from [Relational].[SchemeUpliftTrans_Month] SUTM 
Left join #Results R on R.FirstMonth-3000 = SUTM.ID
where Sutm.id between @6MonthID and @MonthID


drop table #Results
END