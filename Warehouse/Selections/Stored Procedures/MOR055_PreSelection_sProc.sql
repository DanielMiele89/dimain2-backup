-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-03-06>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR055_PreSelection_sProc]ASBEGIN
--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	 cl.CINID			-- keep CINID and FANID
		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements

Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl 
					on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					--and fanid not in (select fanid from [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304]) --NOT A MORE CARDHOLDER--
					and cu.sourceuid 
						NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					and cu.PostalSector 
						in ('BH23 4','BH23 1','BH23 8','BH23 5','SO45 1','SO42 7','SO41 5','SO41 0','SO41 6','BH25 7','BH25 6','BH25 5','BH24 4','SO41 8','SO41 3','SO41 9','BH23 3','BH6 4','BH23 9','BH23 7','KA20 3','KA21 5','KA22 8','KA22 7','KA21 6','KA20 4','KA13 7','KA13 6','KA3 3','HR1 4','HR2 6','HR8 2','GL18 2','HR8 1','WR6 6','HR7 4','WR6 5','HR1 1','HR4 9','HR2 7','HR4 0','HR1 2','HR1 3','WR15 8','HR1 9','CM3 4','CM2 7','CM4 9','CM5 9','CM15 0','CM4 0','CM2 8','CM2 5','CM2 6','CM3 3','CM2 9','CM1 3','CM1 4','CM5 0','CM17 0','CM1 2','CM1 7','CM1 6','CM1 1','CM2 0','CM1 9','CO14 8','CO13 9','CO16 8','CO16 7','CO15 5','CO13 0','CO15 4','CO15 3','CO15 1','CO15 6','CO15 9','CO12 3','CO16 9','CO15 2','CO7 8','CO7 0','CO7 7','CO11 2','CO16 0','CO12 4','CO12 5','CO5 8','CO7 9','CO5 7','CO4 3','CO5 0','CO5 9','CO2 0','CO2 9','CO2 8','CO1 2','CO2 7','CO3 0','CO6 3','CO3 8','CO3 9','CO3 4','CO4 5','CO1 1','CO4 0','CO1 9','CO3 3','CO6 4','CO4 9','CM77 8','CO6 1','CO8 5','CO6 2','CO9 1','CO9 2','SA16 0','SA14 6','SA14 7','SA17 4','SA15 5','SA17 5','SA33 5','SA32 8','SA18 3','SA19 6','SA31 2','SA31 3','SA31 1','SA70 7','SA70 8','SA69 9','SA62 4','SA68 0','SA67 7','SA33 4','SA34 0','SA67 8','SA61 1','SA61 2','SY8 2','SY8 3','DY14 0','DY14 8','WV16 6','SY7 0','SY7 8','SY7 9','SY9 5','SY15 6','SY16 1','SY17 5','SY16 4','SY16 2','SY16 3','GU34 3','GU8 5','GU8 6','GU7 2','GU7 1','GU7 3','GU10 2','GU35 8','GU35 9','GU35 0','GU10 4','GU10 3')
				group by CL.CINID, cu.FanID
			) CL

IF OBJECT_ID('Sandbox.SamW.MorrisonsOnlineStorePick_180220') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsOnlineStorePick_180220
SELECT *
INTO Sandbox.SamW.MorrisonsOnlineStorePick_180220
FROM #segmentAssignment t
WHERE 
NOT EXISTS (SELECT 1
			FROM Sandbox.SamW.MorrisonsLowATV LATV
			WHERE
			LATV.CINID = t.CINID)
AND NOT EXISTS (SELECT 1
			FROM Sandbox.SamW.MorrisonsMediumATV MATV
			WHERE
			MATV.CINID = t.CINID)
AND NOT EXISTS (SELECT 1
			FROM Sandbox.SamW.MorrisonsHighATV HATV
			WHERE
			HATV.CINID = t.CINID)
AND NOT EXISTS (SELECT 1
			FROM Sandbox.SamW.FamiliesMorrisonsLowATV FLATV
			WHERE
			FLATV.CINID = t.CINID)
AND NOT EXISTS (SELECT 1
			FROM Sandbox.SamW.FamiliesMorrisonsMediumATV FMATV
			WHERE
			FMATV.CINID = t.CINID)
AND NOT EXISTS (SELECT 1
			FROM Sandbox.SamW.FamiliesMorrisonsHighATV FHATV
			WHERE
			FHATV.CINID = t.CINID)


--CREATE CLUSTERED INDEX ix_1 ON Sandbox.SamW.MorrisonsLowATV(CINID)
--CREATE CLUSTERED INDEX ix_2 ON Sandbox.SamW.MorrisonsMediumATV(CINID)
--CREATE CLUSTERED INDEX ix_3 ON Sandbox.SamW.MorrisonsHighATV(CINID)
--CREATE CLUSTERED INDEX ix_4 ON Sandbox.SamW.FamiliesMorrisonsLowATV(CINID)
--CREATE CLUSTERED INDEX ix_5 ON Sandbox.SamW.FamiliesMorrisonsMediumATV(CINID)
--CREATE CLUSTERED INDEX ix_6 ON Sandbox.SamW.FamiliesMorrisonsHighATV(CINID)
--CREATE CLUSTERED INDEX ix_7 ON #SegmentAssignment(CINID)
If Object_ID('Warehouse.Selections.MOR055_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR055_PreSelectionSelect FanIDInto Warehouse.Selections.MOR055_PreSelectionFROM  Sandbox.SamW.MorrisonsOnlineStorePick_180220END