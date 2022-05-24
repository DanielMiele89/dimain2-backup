
CREATE PROCEDURE [Selections].[MOR157_PreSelection_sProc]
AS
BEGIN


IF OBJECT_ID('tempdb..#FB_Bc') IS NOT NULL DROP TABLE #FB_Bc
SELECT	CINID,FanID
INTO	#FB_bc
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 
AND		FANID NOT IN (SELECT FANID FROM warehouse.InsightArchive.[MorrisonsReward_MatchedCustomers_20190304])		--NOT A MORECARD OWNER--
CREATE CLUSTERED INDEX ix_CINID on #FB_bc(CINID)


IF OBJECT_ID('tempdb..#CC_Bc') IS NOT NULL DROP TABLE #CC_Bc
SELECT ConsumerCombinationID, BrandID
INTO	#CC_Bc
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	BrandID IN     (292,21,379,425,2541,5,254,485)		-- Morrisons 292, Asda 21, Sainsburys 379, Tesco 425, Amazon Fresh 2541, Aldi 5, Lidl 254, Waitrose 485


IF OBJECT_ID('tempdb..#Trans_bc') IS NOT NULL DROP TABLE #Trans_bc
SELECT	F.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
		,MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
		,COUNT(1) as Transactions
INTO	#Trans_bc
FROM	#FB_bc F
JOIN	WH_Visa.Trans.Consumertransaction CT ON F.CINID = CT.CINID
JOIN	#CC_Bc C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE()) 		AND Amount > 0
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans_bc(CINID)


IF OBJECT_ID('Sandbox.rukank.Barclays_Morrisons_LoW_SoW_06052022') IS NOT NULL DROP TABLE Sandbox.rukank.Barclays_Morrisons_LoW_SoW_06052022		
SELECT	CINID
INTO	Sandbox.rukank.Barclays_Morrisons_LoW_SoW_06052022
FROM	#Trans_bc
WHERE	BrandShopper = 1
		AND SoW < 0.30
		AND Transactions >= 6



	IF OBJECT_ID('[WH_Visa].[Selections].[MOR157_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[MOR157_PreSelection]
	SELECT FanID
	INTO [WH_Visa].[Selections].[MOR157_PreSelection]
	FROM #FB_bc fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.rukank.Barclays_Morrisons_LoW_SoW_06052022  st
					WHERE fb.CINID = st.CINID)

	
INSERT Into [WH_Visa].[Selections].[MOR157_PreSelection]
Select FanID
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
WHERE PartnerID = 4263
AND EndDate IS NULL
AND ShopperSegmentTypeID IN (7, 8)
AND EXISTS (    SELECT 1
                FROM #FB_bc fb
               -- INNER JOIN sandbox.xxxxxxxxxxx.Acquire & Lapsed sb
                 where fb.FANID = sg.Fanid
			   )
END
