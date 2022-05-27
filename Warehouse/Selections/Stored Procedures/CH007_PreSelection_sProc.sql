-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure [Selections].[CH007_PreSelection_sProc]
AS
BEGIN
 SET ANSI_WARNINGS OFF;

-- INFORMATION:
-- The start of natural sales forecasting is 2017-03-30 so for natural sales we consider people who were active as of this date.


-- Get customers, add columns as needed
IF OBJECT_ID('tempdb..#SelectionBase') IS NOT NULL DROP TABLE #SelectionBase
CREATE TABLE #SelectionBase (fanid INT NOT NULL
     ,cinid INT NOT NULL     
     ,TescoSpend6M int
     ,KeyCompSpend12M int
     ,DiningSpend12M int
     ,CBsegment varchar(30)
     ,FinalCategory varchar(30)
     )


-- Fill table with chunk sizing
DECLARE @MinID INT, @MaxID INT, @Increment INT = 500000, @MaxIDValue INT
SELECT @MaxIDValue = MAX(FanID) FROM warehouse.Relational.Customer
SET @MinID = 1
SET @MaxID = @Increment

WHILE @MinID < @MaxIDValue
BEGIN

 INSERT INTO #SelectionBase
 SELECT      
    c.FanID
    ,cl.cinid
    ,cast(NULL as int) as TescoSpend6M 
    ,cast(NULL as int) as KeyCompSpend12M 
    ,cast(NULL as int) as DiningSpend12M  
    ,cast(NULL as varchar(30)) as CBsegment 
    ,cast(NULL as varchar(30)) as FinalCategory  

 FROM Warehouse.Relational.Customer c  WITH (NOLOCK)
 LEFT OUTER JOIN Warehouse.Relational.CAMEO cam  WITH (NOLOCK)
  ON c.PostCode = cam.Postcode
 LEFT OUTER JOIN Warehouse.Relational.CAMEO_CODE_GROUP camg  WITH (NOLOCK)
  ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
 INNER JOIN warehouse.relational.CINList as cl 
  ON c.SourceUID=cl.CIN
 inner join warehouse.mi.customeractivationperiod cap on cap.fanid = c.fanid
 WHERE 
 c.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
 and c.fanID between @MinID and @MaxID
 and c.ActivatedDate <= getdate()
 and (c.DeactivatedDate is null or c.DeactivatedDate > getdate())


 SET @MinID = @MinID + @Increment
 SET @MaxID = @MaxID + @Increment

END

create clustered index INX on #SelectionBase(CINID)





-- Get Tesco CCs
select *
from warehouse.relational.brand
where
brandname like 'Tesco'
-- 425

select ConsumerCombinationID
into #CC_Tesco
from warehouse.relational.consumercombination cc
where
locationcountry = 'GB'
and brandid in (425)

create clustered index INX on #CC_Tesco(consumercombinationid)



-- Get C&B CCs
select *
from warehouse.relational.brand
where
brandname like '%Chef%'
-- 1950

select ConsumerCombinationID
into #CC_CB
from warehouse.relational.consumercombination cc
where
locationcountry = 'GB'
and brandid in (1950)

create clustered index INX on #CC_CB(consumercombinationid)



-- Get KeyComp CCs
-- M&B brands
SELECT PartnerID, P.Name PartnerName, RO.MerchantID
into #MB
FROM SLC_Report..RetailOutlet RO
INNER JOIN SLC_report..Partner p
       ON p.ID=RO.PartnerID
WHERE RegisteredName LIKE '%Mitch%%But%' AND RO.MerchantID NOT LIKE 'X%'  AND RO.MerchantID NOT LIKE '#%' AND LTRIM(RO.MerchantID)<>''

select ConsumerCombinationID
into #MB_CC
from warehouse.relational.consumercombination cc
inner join #MB mb on mb.MerchantID = cc.MID
where
locationcountry = 'GB'


-- Stonegate brands
select *
from warehouse.relational.brand
where
BrandName like '%Slug and%' or
BrandName like '%Yate%'
-- 934
-- 1089

select ConsumerCombinationID
into #SG_CC
from warehouse.relational.consumercombination cc
where
locationcountry = 'GB'
and brandid in (934, 1089)


-- The rest
select *
from warehouse.relational.brand
where
brandname like '%Beefeater%' or 
--brandname like '%Marston''s%' or // NOTE: Unbranded
brandname like '%Stonehouse%Pizz%' or 
brandname like '%wethers%' 
-- 38
-- 2451
-- 1670


select ConsumerCombinationID
into #Rest_CC
from warehouse.relational.consumercombination cc
where
locationcountry = 'GB'
and brandid in (38, 2451, 1670)


select consumercombinationid
into #CC_KeyComp
from #Rest_CC
union select consumercombinationid from #SG_CC
union select consumercombinationid from #MB_CC

create clustered index INX on #CC_KeyComp(consumercombinationid)




-- Get Dining CCs
select brandid, brandname
into #Dining
from warehouse.relational.brand
where
brandname in 
('Table Table',
'Miller & Carter', 
'Nandos', 
'Frankie & Bennys',
'TGI Fridays', 
'Pizza Hut', 
'Pizza Express', 
'Chiquito', 
'Wagamama', 
'Bella Italia', 
'Five Guys', 
'Prezzo', 
'Zizzi', 
'Deliveroo',
'Cosmo',
'Las Iguanas',
'McDonalds',
'KFC',
'Burger King', 
'Just Eat', 
'Pizza Hut') 
order by  2


select ConsumerCombinationID
into #CC_Dining
from warehouse.relational.consumercombination cc
inner join #Dining d on d.brandid = cc.brandid
where
locationcountry = 'GB'

create clustered index INX on #CC_Dining(consumercombinationid)




declare @Today date = getdate()
declare @Yearago date = dateadd(year, -1, @Today)
declare @6monthsago date = dateadd(month, -6, @Today)
declare @3monthsago date = dateadd(month, -3, @Today)


-- Get ALS
IF OBJECT_ID('tempdb..#Sales_CB') IS NOT NULL DROP TABLE #Sales_CB
select ct.cinid, max(ct.trandate) as MaxDate
into #Sales_CB
from #CC_CB cc
inner join warehouse.relational.Consumertransaction_MyRewards ct on ct.consumercombinationid = cc.ConsumerCombinationID
inner join #SelectionBase c on c.cinid = ct.cinid
where
ct.trandate between @Yearago and @Today
group by 
ct.cinid



update t
set CBsegment = case 
    when cb.cinid is null then 'Acquisition'
    when cb.MaxDate >= @3monthsago then 'Shopper'
    else 'Lapsed' end 

from #SelectionBase t
left join #Sales_CB cb on cb.cinid = t.cinid




-- Get Tesco txs
IF OBJECT_ID('tempdb..#Sales_Tesco') IS NOT NULL DROP TABLE #Sales_Tesco
select ct.cinid, count(1) as Txs
into #Sales_Tesco
from #CC_Tesco cc
inner join warehouse.relational.Consumertransaction_MyRewards ct on ct.consumercombinationid = cc.ConsumerCombinationID
inner join #SelectionBase c on c.cinid = ct.cinid
where
ct.trandate between @6monthsago and @Today
group by 
ct.cinid


update t
set TescoSpend6M = case when tes.Txs is null then 0 else tes.Txs end
from #SelectionBase t
left join #Sales_Tesco tes on tes.cinid = t.cinid




-- Get KeyComp txs
IF OBJECT_ID('tempdb..#Sales_KeyComp') IS NOT NULL DROP TABLE #Sales_KeyComp
select ct.cinid, count(1) as Txs
into #Sales_KeyComp
from #CC_KeyComp cc
inner join warehouse.relational.Consumertransaction_MyRewards ct on ct.consumercombinationid = cc.ConsumerCombinationID
inner join #SelectionBase c on c.cinid = ct.cinid
where
ct.trandate between @Yearago and @Today
group by 
ct.cinid


update t
set KeyCompSpend12M = case when tes.Txs is null then 0 else tes.Txs end
from #SelectionBase t
left join #Sales_KeyComp tes on tes.cinid = t.cinid




-- Get dining txs
IF OBJECT_ID('tempdb..#Sales_Dining') IS NOT NULL DROP TABLE #Sales_Dining
select ct.cinid, count(1) as Txs
into #Sales_Dining
from #CC_Dining cc
inner join warehouse.relational.Consumertransaction_MyRewards ct on ct.consumercombinationid = cc.ConsumerCombinationID
inner join #SelectionBase c on c.cinid = ct.cinid
where
ct.trandate between @Yearago and @Today
group by 
ct.cinid


update t
set DiningSpend12M = case when tes.Txs is null then 0 else tes.Txs end
from #SelectionBase t
left join #Sales_Dining tes on tes.cinid = t.cinid





-- Categorisation
update t
set FinalCategory =    case 
      when CBsegment = 'Shopper' and TescoSpend6M >= 12 then 'ShopperTesco'
      when CBsegment = 'Shopper' then 'ShopperRemainder'

      when CBsegment = 'Lapsed' and TescoSpend6M >= 12  then 'LapsedTesco'
      when CBsegment = 'Lapsed' then 'LapsedRemainder'

      when CBsegment = 'Acquisition' and KeyCompSpend12M >= 2  then 'AcquisitionKeyComp'
      when CBsegment = 'Acquisition' and DiningSpend12M >= 2  then 'AcquisitionDining'
      when CBsegment = 'Acquisition' then 'AcquisitionRemainder'
      else 'Error' end

from #SelectionBase t



If object_id('Warehouse.Selections.CH_PreSelection') is not null
drop table Warehouse.Selections.CH_PreSelection
Select FanID
	 , FinalCategory
Into Warehouse.Selections.CH_PreSelection
From #SelectionBase

If object_id('Warehouse.Selections.CH007_PreSelection') is not null
drop table Warehouse.Selections.CH007_PreSelection
Select FanID
Into Warehouse.Selections.CH007_PreSelection
From Warehouse.Selections.CH_PreSelection
where FinalCategory in ('AcquisitionDining')

END
