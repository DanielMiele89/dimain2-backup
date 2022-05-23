CREATE PROCEDURE ETL.[SourceType_CheckID_OLD]
(
	@SourceTypeID INT
	, @SourceName VARCHAR(50)
)
AS
BEGIN
	
	IF (
		SELECT
			1
		FROM dbo.SourceType
		WHERE SourceTypeID = @SourceTypeID
			AND SourceName = @SourceName
	) IS NULL
		THROW 51234
			, 'The SourceTypeID is not for this SourceName.  Check the dbo.SourceType table'
			, 1

END
