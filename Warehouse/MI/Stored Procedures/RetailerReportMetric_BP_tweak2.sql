
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <24/11/2014>
-- Description:	<BP tweak 2>
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetric_BP_tweak2] (@Dateid int)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select sum(Commission) as Commission, 
	0 as PaymentTypeID,
	CustomerAttributeID, 
	Mid_SplitID, PeriodTypeID, 
	CumulativeTypeID, 
	ChannelID,
	[ProgramID],
	PartnerGroupID,
	ClientServiceRef
INTO #BP2 from MI.RetailerReportMetric
where PartnerID = 3960 and DateID =@Dateid and PaymentTypeID in (1,2)-- and ChannelID = 0 
group by CustomerAttributeID, Mid_SplitID,PeriodTypeID, CumulativeTypeID, ChannelID, [ProgramID],
	PartnerGroupID,
	ClientServiceRef

UPDate MI.RetailerReportMetric
set Commission = Bp.Commission
from MI.RetailerReportMetric RRM
inner join #BP2 BP on BP.PaymentTypeID = RRM.PaymentTypeID
and BP.CustomerAttributeID = RRM.CustomerAttributeID 
and BP.ChannelID = RRM.ChannelID 
And BP.Mid_SplitID = RRM.Mid_SplitID
--and RRM.PeriodTypeID = @PeriodTypeID 
and BP.CumulativeTypeID = RRM.CumulativeTypeID 
and RRM.PartnerID = 3960
and RRM.DateID =@dateid
and RRM.ProgramID =BP.ProgramID
and RRM.PartnerGroupID = BP.PartnerGroupID
and RRM.ClientServiceRef = BP.ClientServiceRef
drop table #BP2


END