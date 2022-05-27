
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <24/11/2014>
-- Description:	<RetailerReportMetric_Target_Margin_fetch>
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetric_Target_Margin_fetch] (@DateID int, @PeriodTypeID int, @PartnerID INT = NULL)
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

Update MI.RetailerReportMetric 
set ContractTargetUplift = MRT.Contractual_Sales_Uplift,
RewardTargetUplift= MRT.Target_Sales_Uplift,
ContractROI = MRT.Contractual_ROI,
Margin = MRT.Margin
from MI.RetailerReportMetric RRM
inner join Relational.Master_Retailer_Table MRT
ON MRT.PartnerID = RRM.PartnerID
and RRm.DateID = @DateID and RRm.PeriodTypeID = @PeriodTypeID
WHERE (@PartnerID IS NULL OR rrm.PartnerID = @PartnerID)
END

