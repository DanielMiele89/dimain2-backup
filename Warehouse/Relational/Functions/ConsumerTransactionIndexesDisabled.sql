-- =============================================
-- Author:		JEA
-- Create date: 22/06/2017
-- Description:	Checks if any indexes are disabled on Relational.ConsumerTransaction
-- =============================================
CREATE FUNCTION Relational.ConsumerTransactionIndexesDisabled 
()
RETURNS BIT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @IndexesDisabled BIT = 0

	IF EXISTS(SELECT * FROM sys.indexes i 
									INNER JOIN sys.tables t on i.object_id = t.object_id
									INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
									WHERE t.name = 'ConsumerTransaction'
									AND s.name = 'Relational'
									AND i.is_disabled = 1)
	BEGIN
		SET @IndexesDisabled = 1
	END

	RETURN @IndexesDisabled

END