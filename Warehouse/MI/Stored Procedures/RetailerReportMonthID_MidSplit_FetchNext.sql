-- =============================================
-- Author:		AJS
-- Create date: 03/09/2014
-- Description:	Selects next monthID for population of retailer Mid Splits pre-aggregated tables
-- =============================================
create PROCEDURE [MI].[RetailerReportMonthID_MidSplit_FetchNext] 
	(
		@Cumulative Int
	)	
AS
BEGIN

	SET NOCOUNT ON;
 --	select 22 as NextMonthID
    SELECT ISNULL(MAX(MonthID),0) + 1 AS NextMonthID
	FROM [Warehouse].[MI].[RetailerReportSplitMonthly] where [Cumulative] = @Cumulative and ClientServicesRef is null -- and [PartnerID] <> 3960 -- added by AJS on 31-10-2013 to exclude BP

END
