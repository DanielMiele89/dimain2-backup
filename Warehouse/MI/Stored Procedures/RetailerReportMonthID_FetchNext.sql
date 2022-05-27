-- =============================================
-- Author:		AJS
-- Create date: 14/10/2013
-- Description:	Selects next monthID for population of retailer reporting pre-aggregated tables
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMonthID_FetchNext] 
	(
		@labelID Int
	)	
AS
BEGIN

	SET NOCOUNT ON;
 --	select 22 as NextMonthID
    SELECT ISNULL(MAX(MonthID),0) + 1 AS NextMonthID
	FROM MI.RetailerReportMonthly where LabelID = @labelID-- and [PartnerID] <> 3960 -- added by AJS on 31-10-2013 to exclude BP

END
