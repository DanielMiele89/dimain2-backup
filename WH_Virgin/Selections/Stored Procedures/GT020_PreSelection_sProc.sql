
CREATE PROCEDURE [Selections].[GT020_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('[WH_Virgin].[Selections].[GT020_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[GT020_PreSelection]
	SELECT CONVERT(INT, 0) AS FanID
	INTO [WH_Virgin].[Selections].[GT020_PreSelection]
	WHERE 1 = 2

END

