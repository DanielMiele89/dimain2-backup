
CREATE PROCEDURE [Selections].[GT021_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('[Warehouse].[Selections].[GT021_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[GT021_PreSelection]
	SELECT CONVERT(INT, 0) AS FanID
	INTO [Warehouse].[Selections].[GT021_PreSelection]
	WHERE 1 = 2

END