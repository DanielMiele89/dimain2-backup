﻿-- =============================================


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
select ConsumerCombinationID,BrandName, a.BrandID
into #CC 
FROM Relational.ConsumerCombination A
join Relational.Brand b on a.BrandID =b.BrandID
JOIN Relational.BrandSector S ON S.SectorID = B.SectorID
JOIN Relational.BrandSectorGroup SG ON SG.SectorGroupID = S.SectorGroupID
where a.BrandID IN (234,2254,2315,3013)

DECLARE @DATE_24 DATE = dateadd(month,-24,getdate())

IF OBJECT_ID('tempdb..#ct') IS NOT NULL DROP TABLE #ct;
SELECT cinid
into #CT
FROM Relational.ConsumerTransaction_MyRewards CT
JOIN #CC ON #CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE AMOUNT>0
and trandate >= @DATE_24
group by CINID

DECLARE @DATE_3 DATE = dateadd(month,-3,getdate())

IF OBJECT_ID('tempdb..#ct2') IS NOT NULL DROP TABLE #ct2;
select a.CINID, count(*) as transactions
into #ct2
from #ct a
join (select cinid from Relational.ConsumerTransaction_MyRewards where trandate >= @DATE_3) b on a.cinid = b.cinid
group by a.CINID

IF OBJECT_ID('sandbox.vernon.dixons_johnlewsis_2yr') IS NOT NULL DROP TABLE sandbox.vernon.dixons_johnlewsis_2yr;
select top 115000 CINID 
into sandbox.vernon.dixons_johnlewsis_2yr
from #ct2 ct