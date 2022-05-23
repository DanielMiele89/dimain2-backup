
CREATE PROCEDURE [Reporting].[Monthly_Fetch_CashbackOverview_OLD]
(
	@PublisherName VARCHAR(100)
)
AS
BEGIN

	DECLARE @SQL VARCHAR(MAX) = 'Reporting.Monthly_Fetch_CashbackOVerview_' + @PublisherName + '_OLD'

	DECLARE @CB Reporting.CB

	INSERT INTO @CB
	EXEC (@SQL)

	SELECT 
		*
	FROM @CB
END
