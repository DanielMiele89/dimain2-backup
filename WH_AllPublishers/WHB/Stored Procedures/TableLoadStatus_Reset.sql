
	CREATE PROCEDURE WHB.TableLoadStatus_Reset
	(
		@SourceSystemID INT
	)
	AS
	BEGIN

		UPDATE tls
		SET isLoaded = 0
		FROM WHB.TableLoadStatus tls
		JOIN dbo.SourceType st
			ON tls.SourceTypeID = st.SourceTypeID
		WHERE st.SourceSystemID = @SourceSystemID

	END
