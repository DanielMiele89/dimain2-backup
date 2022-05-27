
CREATE VIEW WHB.LatestSourceCheckpoint
AS
	SELECT 
		*
	FROM
	(
		SELECT
			*
			, ROW_NUMBER() OVER (PARTITION BY SourceTypeID ORDER BY InsertedDateTime DESC) rw
		FROM WHB.SourceCheckpoint
		WHERE Archived = 0
	) x
	WHERE rw = 1
