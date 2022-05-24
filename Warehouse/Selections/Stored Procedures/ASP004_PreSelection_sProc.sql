-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-11-29>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure [Selections].[ASP004_PreSelection_sProc]ASBEGIN

declare @forecastdate date = getdate()IF OBJECT_ID('tempdb..#Active_competitor_spender') IS NOT NULL DROP TABLE #Active_competitor_spender
select    ctmr.CINID
into    #Active_competitor_spender
from    Warehouse.Relational.ConsumerTransaction_MyRewards ctmr
join    Warehouse.Relational.ConsumerCombination cc
    on    ctmr.ConsumerCombinationID = cc.ConsumerCombinationID
where    BrandID in (1651,2085,2107,1480,2660)
and        TranDate between dateadd(month,-6,@forecastdate) AND @forecastdate

 

IF OBJECT_ID('tempdb..#main_brand_spender') IS NOT NULL DROP TABLE #main_brand_spender
select    ctmr.CINID
into    #main_brand_spender
from    Warehouse.Relational.ConsumerTransaction_MyRewards ctmr
join    Warehouse.Relational.ConsumerCombination cc
    on    ctmr.ConsumerCombinationID = cc.ConsumerCombinationID
where    BrandID = 2653
and        TranDate between dateadd(month,-60,@forecastdate) AND @forecastdate

 


IF OBJECT_ID('tempdb..#Exclusion_Main_brand') IS NOT NULL DROP TABLE #Exclusion_Main_brand
select    CINID
into    #Exclusion_Main_brand
from    #Active_competitor_spender 
where    CINID not in 
    (select cinid from #main_brand_spender)

 


IF OBJECT_ID('sandbox.vernon.aspinal_comp_steal_03122019') IS NOT NULL 
    DROP TABLE sandbox.vernon.aspinal_comp_steal_03122019

 

select   DISTINCT CINID
into sandbox.vernon.aspinal_comp_steal_03122019
from    #Exclusion_Main_brand

If Object_ID('Warehouse.Selections.ASP004_PreSelection') Is Not Null Drop Table Warehouse.Selections.ASP004_PreSelectionSelect DISTINCT FanIDInto Warehouse.Selections.ASP004_PreSelectionFrom sandbox.vernon.aspinal_comp_steal_03122019 ctINNER JOIN [Relational].[CINList] cl	ON ct.CINID = cl.CINIDINNER JOIN [Relational].[Customer] cu	ON cl.CIN = cu.SourceUIDEND