-- =============================================
-- Author:		<Adam Scott>
-- Create date: <04/04/2014>
-- Description:	<Caps Incremental Spenders>
-- =============================================
CREATE PROCEDURE [MI].[IncrementalSpendersCap] 
	-- Add the parameters for the stored procedure here
	(
		@monthid Int
	)	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

select PartnerID, sum(IncrementalSpenders) IncrementalSpenders
into #inccap
from mi.RetailerReportMonthly 
where IncrementalSpenders> 0 and LabelID = 1 and monthid between 20 and @monthid
group by PartnerID


update mi.RetailerReportMonthly
set IncrementalSpenders = ic.IncrementalSpenders
from #inccap ic
inner join mi.RetailerReportMonthly r on ic.PartnerID = r.PartnerID and r.LabelID = 4 and r.monthid = @monthid and r.IncrementalSpenders > ic.IncrementalSpenders  



drop table  #inccap



END
