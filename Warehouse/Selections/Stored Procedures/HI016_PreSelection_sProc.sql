
CREATE PROCEDURE [Selections].[HI016_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
		,AgeCurrent
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
--and AgeCurrent >= 55


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID,BrandName, A.BrandID, BS.SectorName
INTO #CC
FROM Relational.ConsumerCombination A
JOIN Relational.Brand b on a.BrandID =b.BrandID
JOIN Relational.BrandSector BS ON BS.SectorID = B.SectorID
WHERE B.SectorID = 48 -- HOTEL SECTOR

IF OBJECT_ID('Sandbox.SamH.IHG_WeekdayHotel_16032022') IS NOT NULL DROP TABLE Sandbox.SamH.IHG_WeekdayHotel_16032022
SELECT distinct 
		ct.CINID
INTO Sandbox.SamH.IHG_WeekdayHotel_16032022
FROM #CC CCs
INNER JOIN Relational.ConsumerTransaction_MyRewards ct
	ON CCs.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE TranDate >= DATEADD(MONTH,-12, GETDATE())
	AND Amount > 0	-- To ignore Returns
	and datepart(weekday, ct.TranDate) in (1,2,3,4)
GROUP BY BrandName,ct.CINID

	IF OBJECT_ID('[Warehouse].[Selections].[HI016_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[HI016_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[HI016_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.SamH.IHG_WeekdayHotel_16032022  st
					WHERE fb.CINID = st.CINID)

END
