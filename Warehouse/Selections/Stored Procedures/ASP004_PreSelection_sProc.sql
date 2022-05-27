﻿-- =============================================

declare @forecastdate date = getdate()
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

If Object_ID('Warehouse.Selections.ASP004_PreSelection') Is Not Null Drop Table Warehouse.Selections.ASP004_PreSelection