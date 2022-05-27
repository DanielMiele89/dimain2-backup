
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <25/11/2014>
-- Description:	<MI.WorkingofferDates_load>
-- =============================================
CREATE PROCEDURE [MI].[WorkingofferDates_load] (@DateID INT
	, @PartnerID INT = NULL)
	-- Add the parameters for the stored procedure here
WITH EXECUTE AS OWNER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	truncate table MI.WorkingofferDates
    -- Insert statements for procedure here
--declare @dateid int
--set @dateid = 34
Insert into MI.WorkingofferDates (Partnerid, ClientServicesRef, StartDate,Enddate,Dateid) 
Select BO.Partnerid, isnull(Bo.ClientServicesRef,'0') as ClientServicesRef, MIN(i.StartDate) StartDate, 
MAX(isnull(i.Enddate,a.Enddate )) Enddate, @dateid as Dateid
--into #OfferDates
from [Stratification].[ReportingBaseOffer] BO 
Left join Warehouse.Relational.Master_Retailer_Table P on P.PartnerID = BO.PartnerID 
inner join Warehouse.Relational.Ironoffer i on i.IronOfferID=Bo.BaseOfferID
cross join (select enddate from warehouse.relational.schemeuplifttrans_month where id=@DateID) a
Where @DateID >= BO.FirstReportingMonth and (BO.LastReportingMonth >= @DateID or BO.LastReportingMonth is null) 
AND (@PartnerID IS NULL OR BO.PartnerID = @PartnerID)
Group BY BO.Partnerid, isnull(Bo.ClientServicesRef,'0')

END

