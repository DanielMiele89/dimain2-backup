
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <05/11/2014>
-- Description:	<Inverted Load of MI.Uplift_RetailerReport>
-- =============================================
CREATE PROCEDURE [MI].[Uplift_RetailerReport_Load] (@DateID INT, @PeriodID INT, @PartnerID INT = NULL)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

--declare @DateID as int, @PeriodID int
--set @DateID = 35
--set @PeriodID = 1
INSERT INTO MI.Uplift_RetailerReport(UpliftRowID,ResultsRowID,Weight,MetricID) 
select UpliftRowID,ResultsRowID,Weight,MetricID
FROM (
select  RM.ID as UpliftRowID ,RT.ID as ResultsRowID, NULL as [Weight], UT.MetricID as MetricID 
from MI.Uplift_Results_Table RM
inner join MI.Uplift_RetailerReport_template UT ON 
 RM.[Programid] = UT.[UpliftProgramid]
      and RM.[PartnerGroupID] = UT.[UpliftPartnerGroupID]
      and RM.[PartnerID] = UT.[UpliftPartnerID]
      and RM.[ClientServiceRef] = UT.[UpliftClientServiceRef]
      and RM.[PaymentTypeID] = UT.[UpliftPaymentTypeID]
      and RM.[ChannelID] = UT.[UpliftChannelID] 
      And RM.CustomerAttributeID = UT.[UpliftCustomerAttributeID]
      And RM.[Mid_SplitID] = UT.[UpliftMid_SplitID]
      And RM.[CumulativeTypeID] = UT.[UpliftCumulativeTypeID]
      And RM.[PeriodTypeID] = UT.[UpliftPeriodTypeID]
	  And RM.DateID between UT.DateIDFrom and isnull(UT.DateIDTo,RM.DateID)  -- change it if we add weeks and quarters as period types
inner join MI.RetailerReportMetric RT ON 
	  RT.[Programid] = UT.[ResultsProgramid]
      and RT.[PartnerGroupID] = UT.[ResultsPartnerGroupID]
      and RT.[PartnerID] = UT.[ResultsPartnerID]
      and RT.[ClientServiceRef] = UT.[ResultsClientServiceRef]
      and RT.[PaymentTypeID] = UT.[ResultsPaymentTypeID]
      and RT.[ChannelID] = UT.[ResultsChannelID] 
      And RT.CustomerAttributeID = UT.[ResultsCustomerAttributeID]
      And RT.Mid_SplitID = UT.[ResultsMid_SplitID]
      And RT.[CumulativeTypeID] = UT.[ResultsCumulativeTypeID]
      And RT.[PeriodTypeID] = UT.[ResultsPeriodTypeID]
	  And RM.DateID = RT.DateID 
WHERE RM.DateID = @DateID and RM.PeriodTypeID=@PeriodID
AND (@PartnerID IS NULL OR RT.PartnerID = @PartnerID)
)aa
END