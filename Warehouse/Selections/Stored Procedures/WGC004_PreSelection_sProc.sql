-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure [Selections].[WGC004_PreSelection_sProc]
AS
BEGIN
 SET ANSI_WARNINGS OFF;

--select *
--from warehouse.relational.brand
--where
--Brandname like '%wyevale%'


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select br.BrandID
  ,br.BrandName
  ,cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.Brand br
Join Warehouse.Relational.ConsumerCombination cc
 on br.BrandID = cc.BrandID
Where br.BrandID in (504)
Order By br.BrandName



CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)


Declare @MainBrand smallint = 504  -- Main Brand 

--  Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment

select 
   cl.*
 , MainBrand_spender_1y
 , MainBrand_spender_2y
 , MainBrand_spender_5y
 , MainBrand_spender_ever
Into  #segmentAssignment
from 
 ( select   CL.CINID
    , cu.FanID
    , AgeCurrent
    , ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
    , cu.Region
  from warehouse.Relational.Customer cu
  INNER JOIN  warehouse.Relational.CINList cl 
   on cu.SourceUID = cl.CIN
  LEFT OUTER JOIN Warehouse.Relational.CAMEO cam  WITH (NOLOCK)
   ON cu.PostCode = cam.Postcode
  LEFT OUTER JOIN Warehouse.Relational.CAMEO_CODE_GROUP camg  WITH (NOLOCK)
   ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
  where cu.CurrentlyActive = 1
   and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
   --and cu.PostalSector in (select distinct dtm.fromsector 
   -- from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
   -- where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
   --            from  warehouse.relational.outlet
   --            WHERE  partnerid = 4265)--adjust to outlet)
   --            AND dtm.DriveTimeMins <= 20)
  --group by CL.CINID, cu.FanID
    ) CL

left Join 
 ( Select ct.CINID
    , max(case when TranDate  > dateadd(year,-1,getdate())
      then 1 else 0 end) as MainBrand_spender_1y

    , max(case when TranDate  > dateadd(year,-2,getdate())
       then 1 else 0 end) as MainBrand_spender_2y
          
    , max(case when TranDate  > dateadd(year,-5,getdate())
       then 1 else 0 end) as MainBrand_spender_5y

    , 1 as MainBrand_spender_ever
        
  From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
  Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
  Where  0 < ct.Amount
     --and TranDate  > dateadd(year,-1,getdate())
  group by ct.CINID ) b
 on cl.CINID = b.CINID

where CAMEO_CODE_GRP in ('01-Business Elite','02-Prosperous Professionals','03-Flourishing Society','04-Content Communities',
         '05-White Collar Neighbourhoods','06-Enterprising Mainstream')
  and AgeCurrent between 35 and 80 
  and region <> 'SCOTLAND'
  and (MainBrand_spender_1y = 0 or MainBrand_spender_1y is null)


If object_id('Warehouse.Selections.WGC004_PreSelection') is not null drop table Warehouse.Selections.WGC004_PreSelection
Select FanID
Into Warehouse.Selections.WGC004_PreSelection
From #segmentAssignment

END