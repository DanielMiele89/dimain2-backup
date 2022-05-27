
	CREATE PROCEDURE WHB.TableLoadStatus_Get
	(
		@SourceTypeID INT,
		@isLoaded BIT OUTPUT
	)	
	AS
	BEGIN


		SELECT @isLoaded = isLoaded
		FROM WHB.TableLoadStatus
		WHERE SourceTypeID = @SourceTypeID

		IF @isLoaded IS NULL
		BEGIN
			SET @isLoaded = 0

			INSERT INTO WHB.TableLoadStatus (SourceTypeID, isLoaded)
			SELECT @SourceTypeID, @isLoaded

		END

	END

