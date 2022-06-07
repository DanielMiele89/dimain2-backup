CREATE PROCEDURE ETL.[TableCheckpointType_Create_OLD]
(
	@TypeName VARCHAR(50)
	, @StoredProcedureName VARCHAR(100)
	, @TypeDescription VARCHAR(100) = NULL
)
AS
BEGIN
	INSERT INTO ETL.TableCheckpointType
	(TypeName, StoredProcedureName, TypeDescription)

	SELECT @TypeName, @StoredProcedureName, @TypeDescription

	SELECT TOP 1 * FROM ETL.TableCheckpointType
	WHERE TypeName = @TypeName
		AND StoredProcedureName = @StoredProcedureName
	ORDER BY CheckpointTypeID DESC

	SELECT * FROM ETL.TableCheckpointType
	WHERE TypeName = @TypeName
		AND StoredProcedureName = @StoredProcedureName
	ORDER BY CheckpointTypeID DESC
END

/****** Object:  StoredProcedure [dbo].[IronOffer_Load]    Script Date: 20/02/2021 16:06:12 ******/
SET ANSI_NULLS ON
