-- =============================================
-- Author:		<Adam J Scott>
-- Create date: <12/12/2014>
-- Description:	<Gets next month for reports>
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetric_FetchNextMonth]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    SELECT ISNULL(MAX(DateID),0) + 1 AS NextMonthID
	FROM [MI].[RetailerReportMetric] where PeriodTypeID = 1
END
