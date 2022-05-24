
CREATE PROCEDURE [Selections].[PO044_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('[WH_VirginPCA].[Selections].[PO044_PreSelection]') IS NOT NULL DROP TABLE [WH_VirginPCA].[Selections].[PO044_PreSelection]
	SELECT CONVERT(INT, 0) AS FanID
	INTO [WH_VirginPCA].[Selections].[PO044_PreSelection]
	WHERE 1 = 2

END
