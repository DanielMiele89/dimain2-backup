-- =============================================
-- Author:		AJS
-- Create date: 14/10/2013
-- Description:	Selects next monthID for population of retailer reporting pre-aggregated tables
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportWeekMonthID_FetchNext] 
	(
		@labelID Int
	)	
AS
BEGIN

	SET NOCOUNT ON;
	--select 22 as NextMonthID
    SELECT ISNULL(MAX(MonthID),0) + 1 AS NextMonthID
	FROM MI.RetailerReportweekly where LabelID = @labelID

END