/************************************************************************
Author:     Hayden Reid
Date:       2022-02-02
Purpose:    Inserts provided checkpoint value, should be structured in a way that 
			a MIN or MAX will return the expected value i.e. be careful with datatypes like varchar
			
*************************************************************************/
CREATE PROCEDURE WHB.Update_TableCheckpoint (
	@SourceTable VARCHAR(100)
	, @NewCheckpointValue VARCHAR(500)
)
AS
BEGIN
	
	INSERT INTO WHB.TableCheckpoint
	(
		SourceTable, CheckpointValue
	)

	VALUES (@SourceTable, @NewCheckpointValue)

END
IF @@ERROR <> 0 SET NOEXEC ON
