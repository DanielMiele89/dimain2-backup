
CREATE PROCEDURE [Selections].[BHO014_PreSelection_sProc]
AS
BEGIN


-------------------------------------------------------------------------------------
----Visa
-------------------------------------------------------------------------------------
IF OBJECT_ID('Sandbox.bastienc.boohoo_Visa') IS NOT NULL DROP TABLE Sandbox.bastienc.boohoo_Visa
SELECT	CINID, FanID, Gender
INTO	Sandbox.bastienc.boohoo_Visa
FROM	[WH_Visa].Derived.Customer  C
JOIN	[WH_Visa].Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and gender = 'F'


	IF OBJECT_ID('[WH_Visa].[Selections].[BHO014_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[BHO014_PreSelection]
	SELECT FanID
	INTO [WH_Visa].[Selections].[BHO014_PreSelection]
	FROM Sandbox.bastienc.boohoo_Visa

END

