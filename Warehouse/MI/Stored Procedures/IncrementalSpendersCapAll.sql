-- =============================================
-- Author:		<Adam Scott>
-- Create date: <04/04/2014>
-- Description:	<Caps Incremental Spenders>
-- =============================================
CREATE PROCEDURE [MI].[IncrementalSpendersCapAll] 
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
--declare @monthid int
--set @monthid =28

select RM.PartnerID, sum(RM.IncrementalSpenders) as IncrementalSpenders, RML.CumulativeLabelID

into #inccap
from mi.RetailerReportMonthly RM 
inner join MI.RetailerReportMonthlyLabels RML on RML.LabelID = RM.LabelID
where RM.IncrementalSpenders> 0 and 
--RML.LabelID > 16 and RML.LabelID <31 and---------------------------------------------*************************Remove After DRY RUN****************----------------------------
RM.monthid between 20 and @monthid
and RML.CumulativeLabelID is not null
group by PartnerID, RML.CumulativeLabelID


update mi.RetailerReportMonthly
set IncrementalSpenders = ic.IncrementalSpenders
--select *
from #inccap ic
inner join mi.RetailerReportMonthly r on ic.PartnerID = r.PartnerID and r.LabelID = IC.CumulativeLabelID and r.monthid = @monthid and r.IncrementalSpenders > ic.IncrementalSpenders  

drop table  #inccap

END