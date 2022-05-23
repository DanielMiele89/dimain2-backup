
CREATE PROCEDURE [Reporting].[MonthlyStats_Overview_Fetch] 
(
	@PublisherName VARCHAR(100)
)
AS
BEGIN

	DECLARE @SQL NVARCHAR(MAX) = 'Reporting.MonthlyStats_Overview_Fetch_' + @PublisherName


	DECLARE @KPI Reporting.KPI

	INSERT INTO @KPI
	EXEC sp_executesql @SQL

	SELECT 
		*
	FROM @KPI
END

