
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <25/11/2014>
-- Description:	<WorkingCumlDates_load>
-- =============================================
CREATE PROCEDURE [MI].[WorkingCumlDates_load] (@dateid int
	, @PartnerID INT = NULL)
	-- Add the parameters for the stored procedure here
WITH EXECUTE AS OWNER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
Declare --@DateID as int, 
@startdate as Date,
@StartID as int
--set @DateID = 34

set @startdate = '2013-07-29' -- start of monthid 20 
set @StartID=20
--Set @DateID = @DateID

truncate table MI.WorkingCumlDates 
insert into MI.WorkingCumlDates (Cumlitivetype, Partnerid, ClientServicesRef, StartDate,StartMonthID, Dateid)
Select 1 as Cumlitivetype, BO.Partnerid, isnull(BO.ClientServicesRef,'0') as ClientServicesRef, 
isnull(case when 
(select StartDate from Relational.SchemeUpliftTrans_Month 
where id = MIN(P.Reporting_Start_MonthID)) < min(SUTM.StartDate)  
then MIN(SUTM.StartDate) else 
(select StartDate from Relational.SchemeUpliftTrans_Month where id = isnull(MIN(P.Reporting_Start_MonthID),0)) end,MIN(SUTM.StartDate) )As StartDate,
case when isnull(min(P.Reporting_Start_MonthID),0) <min(SUTM.ID)
then min(SUTM.ID)
else min(P.Reporting_Start_MonthID) end as StartMonthID,
@DateID as Dateid
--into #CumlDates
from [Stratification].[ReportingBaseOffer] BO
Left join Warehouse.Relational.Master_Retailer_Table P on P.PartnerID = BO.PartnerID 
inner join Warehouse.Relational.SchemeUpliftTrans_Month SUTM on BO.FirstReportingMonth = SUTM.ID 
Where @DateID >= BO.FirstReportingMonth and (BO.LastReportingMonth >= @DateID or BO.LastReportingMonth is null) 
AND (@PartnerID IS NULL OR BO.PartnerID = @PartnerID)
Group BY BO.Partnerid, BO.ClientServicesRef
order by PartnerID


insert into MI.WorkingCumlDates (Cumlitivetype, Partnerid, ClientServicesRef, StartDate,StartMonthID, Dateid)
Select 2 as Cumlitivetype, BO.Partnerid, isnull(BO.ClientServicesRef,'0') as ClientServicesRef, 
case when @startdate < MIN(SUTM.StartDate)  then MIN(SUTM.StartDate) else @startdate end As StartDate,
case when @startID < MIN(SUTM.ID)  then MIN(SUTM.ID) else @StartID end As StartMonthID,
@DateID as Dateid
--into #CumlDates
from [Stratification].[ReportingBaseOffer] BO 
Left join Warehouse.Relational.Master_Retailer_Table P on P.PartnerID = BO.PartnerID 
inner join Warehouse.Relational.SchemeUpliftTrans_Month SUTM on BO.FirstReportingMonth = SUTM.ID 
Where @DateID >= BO.FirstReportingMonth and (BO.LastReportingMonth >= @DateID or BO.LastReportingMonth is null) 
AND (@PartnerID IS NULL OR BO.PartnerID = @PartnerID)
Group BY BO.Partnerid, BO.ClientServicesRef
order by PartnerID

END

