
CREATE PROCEDURE [Selections].[MOR157_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB_VM') IS NOT NULL DROP TABLE #FB_VM
SELECT	CINID,FanID
INTO	#FB_VM
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		AccountType IS NOT NULL
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 
--AND		FANID NOT IN (SELECT FANID FROM [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--
CREATE CLUSTERED INDEX ix_CINID on #FB_VM(CINID)


IF OBJECT_ID('tempdb..#CC_VM') IS NOT NULL DROP TABLE #CC_VM
SELECT  ConsumerCombinationID	,BrandID
INTO	#CC_vm
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	BrandID IN     (292,21,379,425,2541,5,254,485)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254, Waitrose 485


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
		,COUNT(1) as Transactions
INTO	#Trans_vm
FROM	#FB_VM F
JOIN	WH_Virgin.trans.consumertransaction CT ON F.CINID = CT.CINID
JOIN	#CC_vm C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE())
		AND Amount > 0
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans_vm(CINID)


IF OBJECT_ID('Sandbox.rukank.VM_Morrisons_LoW_SoW_06052022') IS NOT NULL DROP TABLE Sandbox.rukank.VM_Morrisons_LoW_SoW_06052022		
SELECT	CINID
INTO	Sandbox.rukank.VM_Morrisons_LoW_SoW_06052022
FROM	#Trans_vm
WHERE	BrandShopper = 1
		AND SoW < 0.30
		AND Transactions >= 6



	IF OBJECT_ID('[WH_Virgin].[Selections].[MOR157_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[MOR157_PreSelection]
	SELECT FanID
	INTO [WH_Virgin].[Selections].[MOR157_PreSelection]
	FROM #FB_VM fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.rukank.VM_Morrisons_LoW_SoW_06052022  st
					WHERE fb.CINID = st.CINID)


INSERT Into [WH_Virgin].[Selections].[MOR157_PreSelection]
Select FanID
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
WHERE PartnerID = 4263
AND EndDate IS NULL
AND ShopperSegmentTypeID IN (7, 8)
AND EXISTS (    SELECT 1
                FROM #FB_VM fb
               -- INNER JOIN sandbox.xxxxxxxxxxx.Acquire & Lapsed sb
                 where fb.FANID = sg.Fanid
			   )

END
