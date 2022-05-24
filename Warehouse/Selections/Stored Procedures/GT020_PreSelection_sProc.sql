
CREATE PROCEDURE [Selections].[GT020_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('[Warehouse].[Selections].[GT020_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[GT020_PreSelection]
	SELECT CONVERT(INT, 0) AS FanID
	INTO [Warehouse].[Selections].[GT020_PreSelection]
	WHERE 1 = 2

END