
CREATE PROCEDURE [Reporting].[MonthlyStats_CashbackOverview_Fetch]
(
	@PublisherName VARCHAR(100)
)
AS
BEGIN

	DECLARE @SQL VARCHAR(MAX) = 'Reporting.MonthlyStats_CashbackOverview_Fetch_' + @PublisherName

	DECLARE @CB Reporting.CB

	INSERT INTO @CB
	EXEC (@SQL)

	SELECT 
		*
	FROM @CB
END
