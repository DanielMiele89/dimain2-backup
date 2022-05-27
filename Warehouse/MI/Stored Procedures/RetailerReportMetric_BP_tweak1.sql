
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <24/11/2014>
-- Description:	<BP tweak 1>
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetric_BP_tweak1] (@Dateid int, @PeriodTypeID int)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select ID,
CAse when IncrementalSales <0 then 0 else (CASE PaymentTypeID when 1 then 0.025 * IncrementalSales when 2 then 0.02 * IncrementalSales else 0 end) end as Commission
INTO #BP 
From MI.RetailerReportMetric
Where PartnerID = 3960 and DateID = @Dateid and PeriodTypeID = @PeriodTypeID

UPDATE MI.RetailerReportMetric
SET Commission = isnull(BP.Commission,0)
from MI.RetailerReportMetric RRM
inner join #BP BP on BP.ID=RRM.ID

drop table #BP


END

