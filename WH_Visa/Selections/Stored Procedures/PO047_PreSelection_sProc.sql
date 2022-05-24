
CREATE PROCEDURE [Selections].[PO047_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------------------------
----BARCLAYS
-------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB_bc') IS NOT NULL DROP TABLE #FB_bc
SELECT	CINID, FanID
INTO	#FB_bc
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
CREATE CLUSTERED INDEX ix_CINID on #FB_bc(CINID)


IF OBJECT_ID('tempdb..#CC_bc') IS NOT NULL DROP TABLE #CC_bc	
SELECT ConsumerCombinationID
INTO	#CC_bc
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	BrandID IN (235,295,269,1202)									-- Competitors: Johnson & Johnson, Mothercare, Mamas & Papas, Jojo Maman Bebe
																		-- missing comp: Fisher-Price

IF OBJECT_ID('tempdb..#Trans_bc') IS NOT NULL DROP TABLE #Trans_bc		-- Can we please target people who have spent 3 or more times in the last 12 months at the following brands:
SELECT	F.CINID, COUNT(F.CINID) AS Txn
INTO	#Trans_bc
FROM	WH_Visa.Trans.Consumertransaction CT
JOIN	#FB_bc F ON F.CINID = CT.CINID
JOIN	#CC_bc C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY F.CINID
HAVING	COUNT(F.CINID) >= 3
CREATE CLUSTERED INDEX ix_CINID on #Trans_bc(CINID)


IF OBJECT_ID('tempdb..#CC_bc_Pets') IS NOT NULL DROP TABLE #CC_bc_Pets	--2010
SELECT  ConsumerCombinationID
INTO	#CC_bc_Pets
FROM	WH_Visa.Trans.ConsumerCombination  CC
JOIN	Warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	SectorID = 34													-- PETS SECTOR
CREATE CLUSTERED INDEX ix_CCID on #CC_bc_Pets(ConsumerCombinationID)

--3147
IF OBJECT_ID('tempdb..#Trans_bc_Pets') IS NOT NULL DROP TABLE #Trans_bc_Pets	-- Please target anyone spending regularly in pet focused stores
SELECT	F.CINID, COUNT(F.CINID) AS Txn
INTO	#Trans_bc_Pets
FROM	WH_Visa.Trans.Consumertransaction CT
JOIN	#FB_bc F ON F.CINID = CT.CINID
JOIN	#CC_bc_Pets C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY F.CINID
HAVING	COUNT(F.CINID) >= 6
CREATE CLUSTERED INDEX ix_CINID on #Trans_bc_Pets(CINID)

IF OBJECT_ID('Sandbox.RukanK.BC_PO_Ferries_PetOwner_20122021') IS NOT NULL DROP TABLE Sandbox.RukanK.BC_PO_Ferries_PetOwner_20122021		--3122
SELECT	CINID
INTO	Sandbox.RukanK.BC_PO_Ferries_PetOwner_20122021
FROM	#Trans_bc_Pets
WHERE	CINID  NOT IN (SELECT CINID FROM #Trans_bc)

	IF OBJECT_ID('[WH_Visa].[Selections].[PO047_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[PO047_PreSelection]
	SELECT	fb.FanID
	INTO [WH_Visa].[Selections].[PO047_PreSelection]
	FROM #FB_bc fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.BC_PO_Ferries_PetOwner_20122021 st
					WHERE fb.CINID = st.CINID)

END

