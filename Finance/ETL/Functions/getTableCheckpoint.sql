CREATE FUNCTION ETL.getTableCheckpoint
(
	@CheckpointTypeID INT
	, @StoredProcedureName VARCHAR(100)
	, @GetCheckpointValueNumber INT
	, @NullReturnValue BIGINT
)
RETURNS BIGINT
AS
BEGIN
	DECLARE @CheckpointValue1 BIGINT
		, @CheckpointValue2 BIGINT
		, @ReturnValue BIGINT
		, @Error INT = 0

	IF (
		SELECT CheckpointTypeID 
		FROM ETL.TableCheckpointType 
		WHERE CheckpointTypeID = @CheckpointTypeID
	) IS NULL
		
		SET @Error = 'The CheckpointTypeID does not exist in ETL.TableCheckpointType' 
	
	ELSE IF (
		SELECT CheckpointTypeID 
		FROM ETL.TableCheckpointType 
		WHERE CheckpointTypeID = @CheckpointTypeID 
			AND StoredProcedureName = @StoredProcedureName
	) IS NULL
		
		SET @Error = 'The CheckpointTypeID is not for this stored procedure' 

	SELECT @CheckpointValue1 = CheckpointValue1
		, @CheckpointValue2 = CheckpointValue2
	FROM ETL.vw_TableCheckpoint_Latest
	WHERE @CheckpointTypeID = @CheckpointTypeID
		AND StoredProcedureName = @StoredProcedureName

	IF (@GetCheckpointValueNumber = 1)
		SET @ReturnValue = @CheckpointValue1
	ELSE IF (@GetCheckpointValueNumber = 2)
		SET @ReturnValue = @CheckpointValue2
	ELSE
		SET @Error = 'The second parameter provided must be 1 OR 2, to represent whether CheckpointValue1 or CheckpointValue2 is required'

	RETURN ISNULL(@ReturnValue, @NullReturnValue)
		
END
