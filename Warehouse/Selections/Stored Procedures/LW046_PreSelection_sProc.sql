-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-02-05>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.LW046_PreSelection_sProcASBEGIN
select * from Warehouse.Relational.Brand where 
brandname like '%sund%'


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (246) --L 246, STWC 2648
Order By br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

-- Engagement Stats
declare @Today date = getdate()
declare @6MonthsAgo date = dateadd(month, -6, @Today)

if OBJECT_ID('tempdb..#Engaged') is not null drop table #Engaged
select distinct c.fanid
into #Engaged
from warehouse.relational.customer c
left join (
 select fanid, 1 as LoggedIn, count(1) as weblogins
 from warehouse.Relational.WebLogins
 where
 trackdate between @6MonthsAgo and @Today
 group by 
 fanid ) wl on wl.fanid = c.FanID
left join (
 select fanid, 1 as Opener, count(1) as EmailOpens
 from warehouse.Relational.EmailEvent ee
 inner join warehouse.relational.emailcampaign ec on ec.campaignkey = ee.CampaignKey
 where
 EventDate between @6MonthsAgo and @Today
 and EmailEventCodeID in (1301, 605)
 and ec.campaignname like '%Newsletter%'
 group by 
 fanid ) eo on eo.fanid = c.FanID
where
eo.FanID is not null or wl.fanid is not null


--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	 cl.CINID			-- keep CINID and FANID
		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		, case when trans = 1 then 1 else 0 end as Shopped_Once
Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					--and cu.PostalSector in (select distinct dtm.fromsector 
					--	from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						--where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						--									 from warehouse.relational.outlet
						--									 WHERE 	partnerid = 4265)--adjust to outlet)
						--									 AND dtm.DriveTimeMins <= 20)
				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		ct.CINID
							
							, count(1) as trans 

									
								
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate > dateadd(month,-12,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID

if OBJECT_ID('tempdb..#Seg_asign_w_Eng') is not null drop table #Seg_asign_w_Eng
select		 s.CINID
			, s.FanID
			, s.Shopped_Once
			, case when e.FanID IS not null then 1 else 0 end as Engaged
into		#Seg_asign_w_Eng
from		#segmentAssignment s
left join	#Engaged e
	on	s.FanID = e.FanID


if OBJECT_ID('tempdb..#Final') is not null drop table #Final
select	 CINID
		, fanid
		, Engaged
		, NTILE(2) over (order by engaged) as [Ntile]
into	#Final
from	#Seg_asign_w_Eng
where Shopped_Once = 1

select COUNT(1)
		, Engaged
		, Ntile
from #Final
group by Ntile
		, Engaged

IF OBJECT_ID('sandbox.Conal.Laithwaites_AB_Test_10pct') IS NOT NULL DROP TABLE sandbox.Conal.Laithwaites_AB_Test_10pct

select	 CINID
		, fanid
into	sandbox.Conal.Laithwaites_AB_Test_10pct
from	#Final
where	Ntile = 2

IF OBJECT_ID('sandbox.Conal.Laithwaites_AB_Test_5pct') IS NOT NULL DROP TABLE sandbox.Conal.Laithwaites_AB_Test_5pct

select	 CINID
		, fanid
into	sandbox.Conal.Laithwaites_AB_Test_5pct
from	#Final
where	Ntile = 1
If Object_ID('Warehouse.Selections.LW046_PreSelection') Is Not Null Drop Table Warehouse.Selections.LW046_PreSelectionSelect FanIDInto Warehouse.Selections.LW046_PreSelectionFROM SANDBOX.CONAL.LAITHWAITES_AB_TEST_5PCTEND