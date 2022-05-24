CREATE PROCEDURE [Selections].[EJ116_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('[WH_Visa].[Selections].[EJ116_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[EJ116_PreSelection]
SELECT	FanID
INTO [WH_Visa].[Selections].[EJ116_PreSelection]
FROM [WH_Visa].Derived.Customer

END
