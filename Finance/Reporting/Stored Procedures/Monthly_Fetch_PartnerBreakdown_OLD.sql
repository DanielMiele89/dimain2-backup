
CREATE PROCEDURE [Reporting].[Monthly_Fetch_PartnerBreakdown_OLD]
(
	@PublisherName VARCHAR(100)
)
AS
BEGIN

	DECLARE @SQL VARCHAR(MAX) = 'Reporting.Monthly_Fetch_PartnerBreakdown_' + @PublisherName + '_OLD'


	DECLARE @OutputTable Reporting.PartnerBreakdown

	INSERT INTO @OutputTable
	EXEC (@SQL)

	SELECT 
		*
	FROM @OutputTable
END

