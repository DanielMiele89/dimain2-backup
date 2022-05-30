CREATE PROCEDURE [dbo].[AddUpdateExtendedProp](
	@SchemaName VARCHAR(MAX)
  , @TableName VARCHAR(MAX)
  , @ColumnName VARCHAR(MAX)
  , @PropType VARCHAR(MAX)
  , @PropValue SQL_VARIANT
)
AS
BEGIN

	IF NOT EXISTS
		(
			SELECT
				NULL
			FROM sys.extended_properties
			WHERE [major_id] = OBJECT_ID(@SchemaName + '.' + @TableName)
				AND [name] = @PropType
				AND (
					([minor_id] = 0
						AND @ColumnName IS NULL)
					OR minor_id =
					(
						SELECT
							[column_id]
						FROM sys.columns
						WHERE [name] = @ColumnName
							AND [object_id] = OBJECT_ID(@SchemaName + '.' + @TableName)
					)
				)
		)

		IF @ColumnName IS NULL
			EXEC sp_addextendedproperty @name = @PropType
									  , @value = @PropValue
									  , @level0type = N'SCHEMA'
									  , @level0name = @SchemaName
									  , @level1type = N'TABLE'
									  , @level1name = @TableName

		ELSE
			EXEC sp_addextendedproperty @name = @PropType
									  , @value = @PropValue
									  , @level0type = N'SCHEMA'
									  , @level0name = @SchemaName
									  , @level1type = N'TABLE'
									  , @level1name = @TableName
									  , @level2type = N'COLUMN'
									  , @level2name = @ColumnName


	ELSE
	IF @ColumnName IS NULL
		EXEC sp_updateextendedproperty @name = @PropType
									 , @value = @PropValue
									 , @level0type = N'SCHEMA'
									 , @level0name = @SchemaName
									 , @level1type = N'TABLE'
									 , @level1name = @TableName

	ELSE
		EXEC sp_updateextendedproperty @name = @PropType
									 , @value = @PropValue
									 , @level0type = N'SCHEMA'
									 , @level0name = @SchemaName
									 , @level1type = N'TABLE'
									 , @level1name = @TableName
									 , @level2type = N'COLUMN'
									 , @level2name = @ColumnName


END


