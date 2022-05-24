

/*=================================================================================================
Sales Visualisation Refresh
Version 1: A. Devereux 25/02/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 1 Hour

CREATE PROCEDURE [ExcelQuery].[alan_customer_lifetime_value]	(@brandid int	--start date
															,@Edate date)	--end date
AS
BEGIN
	SET NOCOUNT ON;

Declare		@Today			datetime
			,@time			DATETIME
			,@msg			VARCHAR(2048)
			,@brandNo		int
			,@Months		int	
			,@MonthsSpend	int
			,@RandomSample	int
			,@LapOrAcq		Varchar(1)
			,@Reward		int


Set			@Today			= getdate()
Set			@Months			= 2					-- Select how many month cohorts to use.
Set			@MonthsSpend	= 12				-- For each \month starting from @Edate until @months in the future, collect spending in the next @MonthsSpend.
--Set			@RandomSample   = 1
--Set			@Reward			= 1					-- Is the customer base limited to MyRewards?




IF OBJECT_ID('tempdb..#brandlist') IS NOT NULL DROP TABLE #brandlist

select brandid
into #brandSectorList
from Relational.brand
where brandid=@brandid



--select * from #brandSectorList

---Gets the monthid of the start of the analysis period

declare		@monthid int
set			@monthid	= (select id from Warehouse.APW.ControlDates where StartDate = @Edate)


--------------------------------------------------------------------------------------
-- EXTRACT ACQUIRE/LAPSED LENGTHS FOR BRAND
--------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#masterretailerfile') IS NOT NULL DROP TABLE #masterretailerfile

SELECT		BrandID
			,BrandName
			,[SS_AcquireLength]
			,[SS_LapsersDefinition]
			,[SS_WelcomeEmail]
			,cast(SS_Acq_Split*100 as int) as Acquire_Pct
into		#masterretailerfile
FROM		[Warehouse].[Relational].[MRF_ShopperSegmentDetails] a
inner join	warehouse.Relational.Partner p on a.PartnerID = p.PartnerID
where		@BrandID = p.brandid

--use Warehouse

IF OBJECT_ID('tempdb..#settings') IS NOT NULL DROP TABLE #settings

select distinct		a.BrandName
					,a.BrandID
					,coalesce(mrf.SS_AcquireLength,blk.acquireL,a.AcquireL0) as AcquireL
					,coalesce(mrf.SS_LapsersDefinition,blk.LapserL,a.LapserL0) as LapserL
					,a.sectorID
					,COALESCE(mrf.Acquire_Pct,blk.Acquire_Pct,Acquire_Pct0) as Acquire_Pct
into				#settings
from	(
	select		b.BrandID
				,b.BrandName
				,b.sectorID
				,case when brandname in ('Tesco', 'Asda','Sainsburys','Morrisons') then 3 else lk.acquireL end as AcquireL0
				,case when brandname in ('Tesco', 'Asda','Sainsburys','Morrisons') then 1 else lk.LapserL end as LapserL0
				,lk.Acquire_Pct as Acquire_Pct0
	from		warehouse.relational.brand b  ---- corrected code here LG
	left join	Warehouse.Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk on lk.sectorid=b.sectorID
	where		b.BrandID = @BrandID
		) a
left join		warehouse.Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk on blk.brandid=a.brandID
LEFT JOIN		#masterretailerfile mrf on mrf.BrandID = a.BrandID
where			coalesce(mrf.SS_AcquireLength,blk.acquireL,AcquireL0) is not null


declare		@Lapsed int
Set			@Lapsed = (select LapserL from  #settings) 
--select		@lapsed

declare		@Acquire int
Set			@Acquire = (select AcquireL from #settings)  --- we can get these from a lookup table ROC model
--select		@Acquire

declare		@brandname varchar(max)
Set			@brandname = (select BrandName from #settings)  --- we can get these from a lookup table ROC model


--select * from #settings


----------------------------------------------------------------------------------------
----------  CUSTOMER BASE (MYREWARDS/RBS)
----------------------------------------------------------------------------------------

			
						
if object_id('tempdb..#customerlistmyrewards') is not null drop table #customerlistmyrewards
						SELECT			top 1000000 cl.CINID
						into			#customerlistmyrewards
						from			Relational.customer c
						inner join		Warehouse.Relational.CINList cl on cl.cin = c.SourceUID -- to get CINID
						--where			c.ActivatedDate < @Edate
						--				and c.CurrentlyActive = 1
						order by		newid()



----------------------------------------------------------------------------------------
----------  Combining MyRewards and Control---------------------------------------------
----------------------------------------------------------------------------------------

if object_id('tempdb..#customerListBase') is not null drop table #customerListBase
CREATE TABLE #customerListBase(
			CINID INT
			,RowNo INT Identity
			)
insert into #customerListBase
select * from #customerlistmyrewards


----------------------------------------------------------------------------------------
----------  EXTRACTING SPENDING
----------------------------------------------------------------------------------------

--select dateadd(month,-@Acquire,@Edate), 'Start of transaction period'
--select dateadd(month,@Months+@MonthsSpend,@Edate), 'End of transaction period'

if object_id('tempdb..#brandcc') is not null drop table #brandcc

select		cc.brandid
			,ConsumerCombinationID
into		#brandcc
from		Relational.ConsumerCombination cc
join		#brandSectorList s on s.brandid=cc.brandid

CREATE CLUSTERED INDEX ix_brandID on #brandcc(BrandID)
CREATE NONCLUSTERED INDEX ix_ccID on #brandcc(ConsumerCombinationID)


if object_id('tempdb..#Spend') is not null drop table #Spend
create table #Spend
(
		CINID			int
		,brandid		int
		,Amount			money ---lg amend
		,Trans			int
		,Monthstart			date

)

Declare		@RowNo int, @MaxRowNo int,@Chunksize int

Set			@RowNo = 1
Set			@MaxRowNo = (Select Max(RowNo) From #customerListBase)
Set			@Chunksize = 100000

While @RowNo <= @MaxRowNo
Begin
			SELECT @msg = 'Populate Spend table - '+Cast(@RowNo as varchar)
			EXEC warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT
			insert into #Spend

			select		ct.CINID
						,b.brandid
						,sum(Amount) as Amount
						,count(1) as Trans
						,DATEADD(m, DATEDIFF(m, 0, ct.TranDate), 0) as Monthstart

			from		Relational.ConsumerTransaction ct with (nolock)
						inner join #customerListBase c on c.cinid=ct.cinid
						inner join #brandcc b on b.ConsumerCombinationID=ct.ConsumerCombinationID

			where		ISRefund = 0 and
						c.RowNo Between @RowNo and @RowNo+(@ChunkSize-1) and 
						trandate between (select dateadd(month,-@Acquire,@Edate)) and (select DATEADD(day,-1,dateadd(month,@Months+@MonthsSpend+1,@Edate)))
			group by	ct.CINID, b.brandid
						,DATEADD(m, DATEDIFF(m, 0, ct.TranDate), 0)
	Set @RowNo = @RowNo+@Chunksize
End

CREATE NONCLUSTERED INDEX ix_Month on #Spend(MonthStart)
CREATE NONCLUSTERED INDEX ix_CINID on #Spend(CINID)


--select * from #spend where segment = 'control' and Monthstart = '2015-03-01' 

----------------------------------------------------------------------------------------
----------  FILTERING SPENDING INTO MONTHS BASED ON ACQUIRE/LAPSED CRITERIA
----------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#monthLag') IS NOT NULL DROP TABLE #monthLag

select	s.CINID
		,s.brandid
		,s.MonthStart as monthStart
		,LEAD(MonthStart, 1) OVER (PARTITION BY CINID ORDER BY MonthStart asc) as NextMonth
into #monthlag
FROM #spend s
where brandid=@brandid	

DECLARE		@start	date = (select dateadd(month,-@acquire,@Edate))
			,@end	date = (select dateadd(month,@Months+@MonthsSpend,@Edate))


--select * from #monthLag --- only relates to spenders

IF OBJECT_ID('tempdb..#recursiveLoop') IS NOT NULL DROP TABLE #recursiveLoop

;WITH CTE AS 
(
	SELECT
		0 as ID 
		, 1 as i
		, @start SDate
		, @start Edate
	UNION ALL
	SELECT 
		(ID+1) % (@MonthsSpend + 1)
		, i + 1
		, DATEADD(m, ID/(@MonthsSpend), SDate)
		, DATEADD(m, ID, SDate)
	FROM CTE
	WHERE sDate <= @end
)
SELECT		*
into		#recursiveLoop
FROM		CTE
WHERE		ID <> 0
			and sDate between @Edate and dateadd(month,@months-1,@Edate)
OPTION		(MAXRECURSION 1000)


--select * from #recursiveLoop --- all combo of dates---

IF OBJECT_ID('tempdb..#customerMonth') IS NOT NULL DROP TABLE #customerMonth

select  CINID
		,r.SDate
into #customerMonth
from #customerListBase c
cross join (select distinct sdate from #recursiveLoop) r

--select * from #customerMonth order by cinid  --- only relates to spenders and is for all possible months 


IF OBJECT_ID('tempdb..#MonthDiff') IS NOT NULL DROP TABLE #MonthDiff

select		c.CINID
			,s.brandid
            ,sdate
            ,s.monthStart as lastSpend
			,s.NextMonth
            ,DATEDIFF(month,s.monthStart,sdate) as diff
into #MonthDiff
from #customerMonth c
left join #Monthlag s on s.CINID=c.CINID and (c.SDate>=s.monthStart and c.SDate<isnull(nextMonth,getdate()))


--select * from #MonthDiff where cinid = 358173 order by cinid,sdate,diff --- only relates to spenders


IF OBJECT_ID('tempdb..#CINIDStatus') IS NOT NULL DROP TABLE #CINIDStatus

select		c.CINID
            ,c.sdate
			,c.brandid
            ,(case when c.diff > @Acquire  or c.diff is null then 1 else 0 end) as ACQ
			,(case when c.diff > @Lapsed and c.diff <= @Acquire then 1 else 0 end) as LAP
			,(case when c.diff <= @Lapsed then 1 else 0 end) as EXS
            ,case	when c.diff > @Acquire  or c.diff is null then  'ACQ'
					when c.diff > @Lapsed and c.diff <= @Acquire then 'LAP'
					when c.diff <= @Lapsed then 'EXS' end as Current_Segment


into #CINIDStatus
from #MonthDiff c

CREATE CLUSTERED INDEX ix_CINID on #CINIDStatus(CINID)

--select * from #CINIDStatus where cinid = 358173


IF OBJECT_ID('tempdb..#CINIDStatus2') IS NOT NULL DROP TABLE #CINIDStatus2
select		a.*
			,b.Current_Segment as Previous_Segment
into		#CINIDStatus2
from		#CINIDStatus a 
inner join	#CINIDStatus b on a.SDate = dateadd(month,1,b.sdate) and a.CINID = b.CINID

CREATE CLUSTERED INDEX ix_CINID on #CINIDStatus2(CINID)



IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1
select		c.CINID
			,c.brandid
			,c.SDate
			,rl.Edate
			,Current_Segment
			,Previous_Segment
			,rl.id
into		#temp1
from		#CINIDStatus2 c
inner join	#recursiveLoop rl on c.SDate = rl.SDate
inner join	#Spend s on c.SDate = s.Monthstart and c.CINID = s.CINID
where		s.brandid = @brandid
			--and c.cinid	= 358173
group by	c.CINID
			,c.SDate
			,rl.Edate
			,Current_Segment
			,Previous_Segment
			,rl.id
			,c.brandid

---right to here

--select * from #temp1 where cinid = 358173
--select * from #recursiveloop

--declare @brandid int
--set @brandid = 303

IF OBJECT_ID('tempdb..#brandspend') IS NOT NULL DROP TABLE #brandspend

select		c.CINID
			,c.brandid
			,c.Current_Segment
			,c.Previous_Segment
			,c.ID
			,c.SDate
			,c.Edate
			,isnull(amount,0) as Brand_Spend
			,isnull(trans,0) as Brand_Trans
into		#brandspend
from		#temp1 c
left join
(select		*
from		#Spend s 
where		brandid = @brandid) b on c.CINID = b.CINID and c.Edate = b.Monthstart


IF OBJECT_ID('tempdb..#combined2') IS NOT NULL DROP TABLE #combined2
select	b.*
		,case when Brand_Spend > 0 then 1 else 0 end as Brand_Spender
into	#combined2
from	#brandspend b


--select * from #combined

IF OBJECT_ID('tempdb..#aggregated') IS NOT NULL DROP TABLE #aggregated
select		brandid
			,Previous_Segment
			,ID
			,SDate
			,sum(Brand_Spend) as Brand_Spend
			,sum(Brand_Trans) as Brand_Trans
			,sum(Brand_Spender) as Brand_Spender
into		#aggregated
from		#combined2	
group by	Previous_Segment
			,ID
			,SDate
			,brandid


--select * from #aggregated order by SDate,ID

IF OBJECT_ID('tempdb..#aggregatedappended') IS NOT NULL DROP TABLE #aggregatedappended
select		a.*
			--,case when Brand_Trans > 0 then  1.0*Brand_Spend / Brand_Trans else 0 end as ATV
			--,case when Brand_Spender > 0 then 1.0*Brand_Trans/Brand_Spender else 0 end as ATF
into		#aggregatedappended
from		#aggregated a


--select * from #aggregatedappended order by SDate,ID


----------------------------
----Output------------------
----------------------------

--select		brandid
--			,Previous_Segment
--			,SDate
--			,ID
--			,Brand_Spend
--			,Brand_Spender
--from		#aggregatedappended
--order by previous_segment, sdate, id


select		a.brandid
			,brandname
			,Previous_Segment
			,SDate
			,1.0*sum(case when ID <= 1 then brand_spend else 0 end)/sum(case when ID =1 then Brand_Spender else 0 end) as month_1
			,1.0*sum(case when ID <= 2 then brand_spend else 0 end)/sum(case when ID =1 then Brand_Spender else 0 end) as month_2
			,1.0*sum(case when ID <= 3 then brand_spend else 0 end)/sum(case when ID =1 then Brand_Spender else 0 end) as month_3
			,1.0*sum(case when ID <= 6 then brand_spend else 0 end)/sum(case when ID =1 then Brand_Spender else 0 end) as month_6
			,1.0*sum(case when ID <= 9 then brand_spend else 0 end)/sum(case when ID =1 then Brand_Spender else 0 end) as month_9
			,1.0*sum(case when ID <= 12 then brand_spend else 0 end)/sum(case when ID =1 then Brand_Spender else 0 end) as month_12
from		#aggregatedappended a
join		Relational.brand b on b.BrandID = a.brandid
group by a.brandid, previous_segment, sdate, BrandName
order by previous_segment, sdate



end