-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-06-14>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.WGC012_PreSelection_sProcASBEGINSELECT * FROM Warehouse.Relational.Brand
WHERE
BrandName LIKE '%Wyev%'
ORDER BY 2

SELECT * FROM Warehouse.Relational.Partner
WHERE
PartnerName LIKE '%Wyev%'


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID,
		MID

INTO	#CC

FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc on br.BrandID = cc.BrandID

WHERE	br.BrandID IN (504)

ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #CC(ConsumerCombinationID)


--60 stores to remain open--
IF OBJECT_ID('tempdb..#CCMID') IS NOT NULL DROP TABLE #CCMID
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID,
		MID

INTO	#CCMID

FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc on br.BrandID = cc.BrandID

WHERE	
MID IN ('1011601', '5000509', '1011599', '1011643', '1011708', '1011706', '1011609', '1011674', '1011628', '1011711', '1011677', '1011638', '1011598', '1011704', '1011671', '1011603', '1011630', '2203015', '1011610', '1011653', '1011647', '1011605', '1011604', '2204342', '1011613', '1011664', '1011616', '1011729', '1013581', '1011690', '1011615', '1011620', '1011730', '2204341', '1011662', '1011692', '1096666', '1011731', '1011693', '1011649', '1011645', '1011651', '1011679', '1011716', '1011715', '1011636', '1011621', '1011696', '1011697', '1011698', '1011736', '1011625', '1011738', '1011629', '1011650', '1011718', '1011701', '7004110'
)
AND br.BrandID IN (504)

ORDER BY br.BrandName

CREATE CLUSTERED INDEX ix_ComboID2 ON #CCMID(ConsumerCombinationID)

select distinct mid from #CCMID

--Segment Assignment--
If Object_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		MainBrand_Lapsed_CH,
		MainBrand_ShopperExc12_CH,
		MainBrand_Shopper_CH,

		MainBrand_Lapsed_NS,
		MainBrand_ShopperExc12_NS,
		MainBrand_Shopper_NS

INTO #SegmentAssignment

FROM	(SELECT CL.CINID,
				 cu.FanID
	
		FROM warehouse.Relational.Customer cu
		JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN

		WHERE cu.CurrentlyActive = 1
		AND cu.sourceuid NOT IN (SELECT DISTINCT sourceuid FROM Warehouse.Staging.Customer_DuplicateSourceUID )
		AND cu.PostalSector IN (SELECT DISTINCT dtm.fromsector 
								 FROM Warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
								 WHERE dtm.tosector IN (SELECT DISTINCT PostalSector
														FROM Warehouse.relational.outlet
														WHERE partnerid = 4205)--adjust to outlet)
														AND dtm.DriveTimeMins <= 25)
	
		GROUP BY CL.CINID, cu.FanID) cl

LEFT JOIN (SELECT ct.CINID,
				 SUM(ct.Amount) as Sales,

				 MAX(CASE WHEN DATEADD(MONTH,-60,GETDATE()) <= TranDate AND TranDate < DATEADD(MONTH,-24,GETDATE())
 						THEN 1 ELSE 0 END) AS MainBrand_Lapsed_CH,

				 MAX(CASE WHEN DATEADD(MONTH,-24,GETDATE()) <= TranDate AND TranDate < DATEADD(MONTH,-12,GETDATE())
 						THEN 1 ELSE 0 END) AS MainBrand_ShopperExc12_CH,

				 MAX(CASE WHEN DATEADD(MONTH,-12,GETDATE()) <= TranDate AND TranDate < GETDATE()
 						THEN 1 ELSE 0 END) AS MainBrand_Shopper_CH,

				 MAX(CASE WHEN DATEADD(MONTH,-72,GETDATE()) <= TranDate AND TranDate < DATEADD(MONTH,-36,GETDATE())
 						THEN 1 ELSE 0 END) AS MainBrand_Lapsed_NS,

				 MAX(CASE WHEN DATEADD(MONTH,-36,GETDATE()) <= TranDate AND TranDate < DATEADD(MONTH,-24,GETDATE())
 						THEN 1 ELSE 0 END) AS MainBrand_ShopperExc12_NS,

				 MAX(CASE WHEN DATEADD(MONTH,-24,GETDATE()) <= TranDate AND TranDate < DATEADD(MONTH,-12,GETDATE())
 						THEN 1 ELSE 0 END) AS MainBrand_Shopper_NS

			FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			JOIN #CCMID cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
			WHERE 0 < ct.Amount
		 AND TranDate > DATEADD(MONTH,-72,GETDATE())

			GROUP BY ct.CINID) b on cl.CINID = b.CINID

SELECT COUNT(CINID), COUNT(DISTINCT CINID)
FROM #SegmentAssignment

SELECT TOP 100 *
FROM #SegmentAssignment

SELECT MainBrand_Lapsed_CH,
		MainBrand_ShopperExc12_CH,
		MainBrand_Shopper_CH,
		COUNT(1)

FROM #SegmentAssignment
	
GROUP BY MainBrand_Lapsed_CH,
		 MainBrand_ShopperExc12_CH,
		 MainBrand_Shopper_CH


IF OBJECT_ID('Sandbox.Tasfia.Wyevale_Remaining60Stores_CH_250419') IS NOT NULL DROP TABLE Sandbox.Tasfia.Wyevale_Remaining60Stores_CH_250419
SELECT CINID,
		FanID

INTO Sandbox.Tasfia.Wyevale_Remaining60Stores_CH_250419

FROM #SegmentAssignment

WHERE (MainBrand_Shopper_CH = 0 OR MainBrand_Shopper_CH IS NULL)If Object_ID('Warehouse.Selections.WGC012_PreSelection') Is Not Null Drop Table Warehouse.Selections.WGC012_PreSelectionSelect FanIDInto Warehouse.Selections.WGC012_PreSelectionFrom Sandbox.Tasfia.Wyevale_Remaining60Stores_CH_250419END