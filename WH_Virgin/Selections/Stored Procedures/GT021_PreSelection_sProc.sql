
CREATE PROCEDURE [Selections].[GT021_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('[WH_Virgin].[Selections].[GT021_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[GT021_PreSelection]
	SELECT CONVERT(INT, 0) AS FanID
	INTO [WH_Virgin].[Selections].[GT021_PreSelection]
	WHERE 1 = 2

END

