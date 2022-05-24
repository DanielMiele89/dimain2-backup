CREATE PROCEDURE [Selections].[EJ116_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('[WH_VirginPCA].[Selections].[EJ116_PreSelection]') IS NOT NULL DROP TABLE [WH_VirginPCA].[Selections].[EJ116_PreSelection]
SELECT	FanID
INTO [WH_VirginPCA].[Selections].[EJ116_PreSelection]
FROM [WH_VirginPCA].Derived.Customer

END
