
CREATE PROCEDURE [Selections].[BHO014_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('Sandbox.bastienc.boohoo_Virgin') IS NOT NULL DROP TABLE Sandbox.bastienc.boohoo_Virgin
SELECT	CINID, FanID
INTO	Sandbox.bastienc.boohoo_Virgin
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
and gender = 'F'


	IF OBJECT_ID('[WH_Virgin].[Selections].[BHO014_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[BHO014_PreSelection]
	SELECT [Sandbox].[bastienc].[boohoo_Virgin].[FanID]
	INTO [WH_Virgin].[Selections].[BHO014_PreSelection]
	FROM Sandbox.bastienc.boohoo_Virgin

END