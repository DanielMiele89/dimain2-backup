
CREATE PROCEDURE [Reporting].[MonthlyStats_PartnerBreakdown_Fetch]
(
	@PublisherName VARCHAR(100)
)
AS
BEGIN

	DECLARE @SQL VARCHAR(MAX) = 'Reporting.MonthlyStats_PartnerBreakdown_Fetch_' + @PublisherName


	DECLARE @OutputTable Reporting.PartnerBreakdown

	INSERT INTO @OutputTable
	EXEC (@SQL)

	SELECT 
		*
	FROM @OutputTable
END

