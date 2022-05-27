

CREATE PROC [WHB].[Warehouse_Earnings_DisableIndexes]
AS
BEGIN

	DECLARE @sql AS VARCHAR(MAX)='';

	SELECT @sql = @sql + 
	'ALTER INDEX ' + i.name + ' ON  ' +SCHEMA_NAME(o.schema_id) + '.' + o.name + ' DISABLE;' +CHAR(13)+CHAR(10)
	FROM 
		sys.indexes i
	JOIN 
		sys.objects o
		ON i.object_id = o.object_id
	WHERE i.type_desc = 'NONCLUSTERED'
	  AND o.name = 'Earnings'
	  AND o.schema_id = SCHEMA_ID('dbo')
	  ;

	EXEC (@sql);

	ALTER TABLE dbo.Earnings NOCHECK CONSTRAINT ALL;


END
