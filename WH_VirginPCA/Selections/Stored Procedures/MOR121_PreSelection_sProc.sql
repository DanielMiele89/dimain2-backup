
CREATE PROCEDURE [Selections].[MOR121_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('[WH_VirginPCA].[Selections].[MOR121_PreSelection]') IS NOT NULL DROP TABLE [WH_VirginPCA].[Selections].[MOR121_PreSelection]
	SELECT CONVERT(INT, 0) AS FanID
	INTO [WH_VirginPCA].[Selections].[MOR121_PreSelection]
	WHERE 1 = 2

END
