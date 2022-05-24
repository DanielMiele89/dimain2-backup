-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-04-20>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.LW048_PreSelection_sProcASBEGIN--Laithwaites & Competitors--
SELECT BrandID,
		BrandName

FROM	Relational.Brand

WHERE	BrandName LIKE '%Laith%'
OR		BrandName LIKE '%Majestic%'
OR		BrandName LIKE '%Naked%Wines%'
OR		BrandName LIKE '%Oddbins%'
OR		BrandName LIKE '%Virgin%Wines%'
OR		BrandName LIKE '%Berry%'


--Consumer Combinations for ATG & Competitors--
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID

INTO	#CC

FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID

WHERE	br.BrandID in (246, --Laithwaites--
					 1048 , 1626, 313, 480, 1712) --Competitors--

ORDER BY br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)


DECLARE @MainBrand SMALLINT = 246	 -- Main Brand	

--Segment Assignment--
If Object_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		MainBrand_Spender,
		Comp_Spender

INTO #SegmentAssignment

FROM (SELECT CL.CINID,
				cu.FanID
	
		FROM warehouse.Relational.Customer cu
		JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN

		WHERE cu.CurrentlyActive = 1
		AND cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )

		GROUP BY CL.CINID, cu.FanID) CL

LEFT JOIN (SELECT ct.CINID,
				 SUM(ct.Amount) as Sales,

				 MAX(CASE WHEN cc.brandid = @MainBrand AND DATEADD(WEEK,-56,GETDATE()) <= TranDate AND TranDate < GETDATE()
 						THEN 1 ELSE 0 END) AS MainBrand_Spender,

				 MAX(CASE WHEN cc.brandid <> @MainBrand AND DATEADD(WEEK,-56,GETDATE()) <= TranDate AND TranDate < GETDATE()
 						THEN 1 ELSE 0 END) AS Comp_Spender
						 
			FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
			Where	0 < ct.Amount
			and		TranDate > dateadd(WEEK,-56,getdate())

			GROUP BY ct.CINID) b on cl.CINID = b.CINID



SELECT MainBrand_Spender,
		Comp_Spender,
		COUNT(1)

FROM #SegmentAssignment

GROUP BY MainBrand_Spender,
		 Comp_Spender


IF OBJECT_ID('Sandbox.SamW.Laithwaites_CompSteal_280519') IS NOT NULL DROP TABLE Sandbox.SamW.Laithwaites_CompSteal_280519
SELECT CINID,
		FanID

INTO Sandbox.SamW.Laithwaites_CompSteal_280519

FROM #SegmentAssignment

WHERE Comp_Spender = 1If Object_ID('Warehouse.Selections.LW048_PreSelection') Is Not Null Drop Table Warehouse.Selections.LW048_PreSelectionSelect FanIDInto Warehouse.Selections.LW048_PreSelectionFROM  SANDBOX.SAMW.LAITHWAITES_COMPSTEAL_280519END