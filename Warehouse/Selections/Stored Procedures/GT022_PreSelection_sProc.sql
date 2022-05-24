
CREATE PROCEDURE [Selections].[GT022_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('[Warehouse].[Selections].[GT022_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[GT022_PreSelection]
	SELECT CONVERT(INT, 0) AS FanID
	INTO [Warehouse].[Selections].[GT022_PreSelection]
	WHERE 1 = 2

END

