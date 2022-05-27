
	CREATE PROCEDURE WHB.TableLoadStatus_Set
	(
		@SourceTypeID INT
	)
	AS
	BEGIN

		UPDATE WHB.TableLoadStatus
		SET isLoaded = 1
		WHERE SourceTypeID = @SourceTypeID

	END
