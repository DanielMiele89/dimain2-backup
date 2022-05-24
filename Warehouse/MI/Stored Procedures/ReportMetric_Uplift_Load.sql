
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <13/11/2014>
-- Description:	<Loads uplift for Report mectric>
-- =============================================
CREATE PROCEDURE [MI].[ReportMetric_Uplift_Load] (@DateID INT, @PeriodTypeID int, @PartnerID INT = NULL)
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--declare @DateID INT, @PeriodTypeID int
--set @DateID = 33
--set @PeriodTypeID = 1


    -- Insert statements for procedure here
	-- UpliftSales
Update Mi.RetailerReportMetric
set UpliftSales = aa.UpliftSales
from Mi.RetailerReportMetric RRM inner join (
Select urr.ResultsRowID, sum(urr.Weight*rt.UpliftSales) UpliftSales  from 
MI.Uplift_RetailerReport URR 
inner join MI.Uplift_Results_Table RT on URR.UpliftRowID = Rt.ID
WHERE urr.MetricID=1 and RT.DateID = @DateID and RT.PeriodTypeID = @PeriodTypeID
GROUP BY urr.ResultsRowID)aa on 
aa.ResultsRowID = RRM.ID
WHERE (@PartnerID IS NULL OR RRM.PartnerID = @PartnerID)

	--UpliftSpenders
Update Mi.RetailerReportMetric
set UpliftSpenders = aa.UpliftSpenders
from Mi.RetailerReportMetric RRM inner join ( 
Select urr.ResultsRowID, sum(urr.Weight*rt.UpliftSpenders) UpliftSpenders  from 
MI.Uplift_RetailerReport URR 
inner join MI.Uplift_Results_Table RT on URR.UpliftRowID = Rt.ID
WHERE urr.MetricID=2 and RT.DateID = @DateID and RT.PeriodTypeID = @PeriodTypeID
GROUP BY urr.ResultsRowID)aa on 
aa.ResultsRowID = RRM.ID
WHERE (@PartnerID IS NULL OR RRM.PartnerID = @PartnerID)

	--UpliftTransactions
Update Mi.RetailerReportMetric
set UpliftTransactions = aa.UpliftTransactions
from Mi.RetailerReportMetric RRM inner join ( 
Select urr.ResultsRowID, sum(urr.Weight*rt.UpliftTransactions) UpliftTransactions  from 
MI.Uplift_RetailerReport URR 
inner join MI.Uplift_Results_Table RT on URR.UpliftRowID = Rt.ID
WHERE urr.MetricID=3 and RT.DateID = @DateID and RT.PeriodTypeID = @PeriodTypeID
GROUP BY urr.ResultsRowID)aa on 
aa.ResultsRowID = RRM.ID
WHERE (@PartnerID IS NULL OR RRM.PartnerID = @PartnerID)

END