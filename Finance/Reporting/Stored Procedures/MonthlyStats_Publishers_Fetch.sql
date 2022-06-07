
CREATE PROCEDURE Reporting.MonthlyStats_Publishers_Fetch
AS
BEGIN

	SELECT
		*
	FROM (
		VALUES
			('Virgin')
			, ('VirginPCA')
			, ('Visa')
	) x(PublisherName)

END