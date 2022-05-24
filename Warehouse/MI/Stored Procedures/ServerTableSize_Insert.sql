-- =============================================
-- Author:		JEA
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.ServerTableSize_Insert 
	(
		@ServerName VARCHAR(50)
		, @DatabaseName VARCHAR(50)
		, @SchemaName VARCHAR(50)
		, @TableName VARCHAR(100)
		, @TableRows VARCHAR(50)
		, @KBReserved VARCHAR(50)
		, @KBData VARCHAR(50)
		, @KBIndexSize VARCHAR(50)
		, @KBUnused VARCHAR(50)
	)
AS
BEGIN

	SET NOCOUNT ON;

    INSERT INTO MI.ServerTableSize(ServerName
		, DatabaseName
		, SchemaName
		, TableName
		, TableRows
		, KBReserved
		, KBData
		, KBIndexSize
		, KBUnused)
	VALUES(
		@ServerName
		, @DatabaseName
		, @SchemaName
		, @TableName
		, MI.SpaceUsedInt(@TableRows)
		, MI.SpaceUsedInt(@KBReserved)
		, MI.SpaceUsedInt(@KBData)
		, MI.SpaceUsedInt(@KBIndexSize)
		, MI.SpaceUsedInt(@KBUnused)
	)
	
END
