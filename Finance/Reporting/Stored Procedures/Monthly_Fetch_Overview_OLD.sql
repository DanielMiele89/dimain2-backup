
CREATE PROCEDURE [Reporting].[Monthly_Fetch_Overview_OLD]
(
	@PublisherName VARCHAR(100)
)
AS
BEGIN

	DECLARE @SQL VARCHAR(MAX) = 'Reporting.Monthly_Fetch_Overview_' + @PublisherName + '_OLD'


	DECLARE @KPI Reporting.KPI

	INSERT INTO @KPI
	EXEC (@SQL)

	SELECT 
		*
	FROM @KPI
END

