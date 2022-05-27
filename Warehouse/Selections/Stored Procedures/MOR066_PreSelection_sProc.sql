-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-08-21>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[MOR066_PreSelection_sProc]ASBEGIN
    
--CONSUMER COMBINATION IDs--
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select    br.BrandID
        ,br.BrandName
        ,cc.ConsumerCombinationID
Into    #CC
From    Warehouse.Relational.Brand br
Join    Warehouse.Relational.ConsumerCombination cc
    on    br.BrandID = cc.BrandID
Where    br.BrandID in (    292,                        -- Morrisons
                        425,21,379,                    -- Mainstream - Asda, Sainsburys, Tesco
                        485,275,312,1124,1158,1160,    -- Premium - M&S, Ocado, Waitrose, Planet Organic, Able & Cole, Whole Foods
                        92,399,103,1024,306,1421,    -- Convenience - Co-Op, Costcutter, Nisa, Spar, Londis, Martin Mc Coll
                        5,254,215,2573,102)            -- Discounters - Aldi, Costo, Iceland, Lidl, Jack's
Order By br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)



--FULL BASE--
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT    DISTINCT CINID
        ,FANID


INTO #FB


FROM    Relational.Customer C


JOIN    Relational.CINList CL ON CL.CIN = C.SourceUID


JOIN    Relational.DriveTimeMatrix DTM ON C.PostalSector = DTM.FromSector


WHERE    DTM.ToSector IN ('S44 5','S44 6','NG19 8','NG20 8','NG20 9','S40 1','S44 9','S43 4','S80 4','S43 9')


AND        DTM.DriveTimeMins < = 10



--TRANSACTIONS--
IF OBJECT_ID('tempdb..#SA') IS NOT NULL DROP TABLE #SA
SELECT    DISTINCT f.CINID
        ,FANID
        ,Transactions
        ,SoW_Morrisons
        ,Morrisons_Shopper
INTO #SA


FROM    #FB F


LEFT JOIN (Select        ct.CINID
                              -- Transaction Value Info
                            , sum(case when BrandID = 292 then ct.Amount else 0 end) / cast(sum(ct.Amount) as float) as SoW_Morrisons


                            --, sum(case when BrandID in (379,5,254) then ct.Amount else 0 end) / cast(sum(ct.Amount) as float) as Comp_SoW
                            
                              --Transaction Count Info
                            , count(1) as Transactions
                            , sum(case when BrandID = 292 then 1 else 0 end) as Morrions_Transactions
                                            
                              -- Brand count
                            , count(distinct BrandID) as Number_of_Brands_Shopped_At


                            , max(case when BrandID = 292 
                                    and TranDate >= dateadd(month,-3,getdate())
                                    then 1 else 0 end) as Morrisons_Shopper
                            --, max(case when BrandID = @MainBrand 
                            --        and TranDate >= dateadd(month,-6,getdate()) 
                            --        and TranDate < dateadd(month,-3,getdate())
                            --        then 1 else 0 end) as Morrisons_Lapsed
                                                                                
                From        Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
                Join        #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
                --  CROSS APPLY (
                --       SELECT Excluded = CASE WHEN Amount < 10 AND Brandid <> 292 THEN 1 ELSE 0 END
                --            ) x
                Where        0 < ct.Amount --and x.Excluded = 0 
                            and TranDate  > dateadd(month,-6,getdate())
                group by ct.CINID ) b on b.cinid = f.CINID



IF OBJECT_ID('tempdb..#RetailShoppers') IS NOT NULL DROP TABLE #RetailShoppers
SELECT DISTINCT F.CINID
INTO #RetailShoppers
FROM #FB F
JOIN Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
JOIN Relational.Brand B ON B.BrandID = CC.BrandID
JOIN Relational.BrandSector BS ON BS.SectorID = B.SectorID
JOIN Relational.BrandSectorGroup BSG ON BSG.SectorGroupID = BS.SectorGroupID
WHERE BSG.SectorGroupID = 9
--AND TranDate >= '2019-03-01'



IF OBJECT_ID('Sandbox.SamW.MorrisonsBolsoverShopper040620') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsBolsoverShopper040620
SELECT F.CINID, F.FanID
INTO Sandbox.SamW.MorrisonsBolsoverShopper040620
FROM #FB F
LEFT JOIN #SA S ON F.CINID = S.CINID
LEFT JOIN #RetailShoppers R ON F.CINID = R.CINID
WHERE Morrisons_Shopper = 1
OR CASE WHEN R.CINID IS NOT NULL THEN 1 ELSE 0 END = 1


If Object_ID('Warehouse.Selections.MOR066_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR066_PreSelectionSelect FanIDInto Warehouse.Selections.MOR066_PreSelectionFROM  SANDBOX.SAMW.MorrisonsBolsoverShopper040620END