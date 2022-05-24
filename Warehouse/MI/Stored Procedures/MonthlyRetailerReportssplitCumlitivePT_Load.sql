-- =============================================
-- Author:		<Adam Scott>
-- Create date: <21/05/2014>
-- Description:	<Cumlative monthly Partner trans_fetch>
-- =============================================
CREATE PROCEDURE  [MI].[MonthlyRetailerReportssplitCumlitivePT_Load] 
(@MonthID int, @PartnerID int)
AS
BEGIN
	SET NOCOUNT ON;

declare @startID int --, @MonthID int, @PartnerID int
--set @MonthID = 30
--set @PartnerID =3960 
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)

IF Object_id('tempdb..#OutletAttribute') IS NOT NULL 
  DROP TABLE #outletattribute 

SELECT st.id                                                    MonthID, 
       o.outletid, 
       o.partnerid, 
       psp.use_for_report                                       SplitRank, 
       COALESCE(Min(a.use_for_report), psp.deafultstatustypeid) StatusRank, 
       st.startdate, 
       st.enddate 
INTO   #outletattribute 
FROM   warehouse.relational.schememid o 
       INNER JOIN [Warehouse].[MI].[reportsplituseforreport] psp 
               ON psp.partnerid = o.partnerid 
       CROSS JOIN (SELECT * 
                   FROM   relational.schemeuplifttrans_month st 
                   WHERE  st.id BETWEEN @startID AND @MonthID) st 
       LEFT JOIN (SELECT DISTINCT st.*, 
                                  s.outletid, 
                                  s.statustypeid, 
                                  s.partnerid, 
                                  pst.use_for_report, 
                                  pst.splitid 
                  FROM   [Warehouse].[MI].[reportmid] s 
                         INNER JOIN relational.schemeuplifttrans_month st WITH ( 
                                    nolock) 
                                 ON st.enddate BETWEEN s.startdate AND 
                                                       COALESCE(s.enddate, 
                                                       st.enddate) 
                         INNER JOIN 
                         [Warehouse].[MI].[reportstatustypeuseforreport] pst 
                                 ON s.splitid = pst.splitid 
                                    AND s.statustypeid = pst.statustypeid 
                                    AND s.partnerid = pst.partnerid 
                                    AND s.splitid = pst.splitid 
                  WHERE  pst.use_for_report BETWEEN 1 AND 6 
						and PST.PartnerID = @PartnerID
                         AND st.id BETWEEN @startID AND @MonthID) a 
              ON a.outletid = o.outletid 
                 AND a.partnerid = o.partnerid 
				 And o.PartnerID = @PartnerID
				 AND a.id = st.id 
                 AND a.splitid = psp.splitid 
WHERE  psp.use_for_report BETWEEN 1 AND 2  And o.PartnerID = @PartnerID
GROUP  BY st.id, 
          o.outletid, 
          psp.use_for_report, 
          psp.deafultstatustypeid, 
          o.partnerid, 
          st.startdate, 
          st.enddate 

IF Object_id('tempdb.. #PTCUML') IS NOT NULL 
  DROP TABLE  #PTCUML 
select	max(pt.PartnerID) as PartnerID,
		oa.StatusRank,
				oa.SplitRank,

		@MonthID as MonthID,
		--max(SUTM.ID) as MonthID,
		Sum(TransactionAmount)  as TranAmount,
		Count(*) as TranCount,
		Sum(CASE WHEN EligibleForCashBack = 1 THEN CommissionChargable ELSE 0 END) AS Commission,
		count(DISTINCT PT.FanID) as CustomerNo
		into #PTCUML
from warehouse.relational.PartnerTrans as pt
inner join MI.SchemeMarginsAndTargets SMT
	on PT.PartnerID = SMT.PartnerID
inner join warehouse.relational.Partner as p
	on pt.PartnerID = p.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
	on pt.addeddate between SUTM.StartDate  and  SUTM.EndDate  
inner join MI.[StagingCustomer_Cuml] ST
	on ST.[FanID] = PT.Fanid and SMT.PartnerID = ST.PartnerID 
inner join #OutletAttribute OA
	on OA.OutletID = PT.OutletID and (OA.EndDate is null or OA.EndDate >= SUTM.EndDate) and (OA.StartDate <= SUTM.EndDate)
and p.PartnerID = OA.PartnerID 

Where	pt.[EligibleForCashBack] = 1 and		
		TransactionAmount > 0 and 
		SUTM.ID between @startID and @MonthID and 
		SMT.PartnerID = @PartnerID and
		st.[LabelID] = 4 and
		St.monthid = @MonthID and 
		Pt.PartnerID is not null and	pt.matchid not in (145665307,
		145665308,
		145665309,
		145665310,
		145665311,
		145665312,
		145665313,
		145665314,
		145665315)
		group by Oa.StatusRank,
				oa.SplitRank,
	--Case when pt.PartnerID =3960 then case when OA.StatusTypeID =1 then 1 else 2 end else  OA.StatusTypeID end,
		pt.PartnerID 

UPDATE   [Warehouse].[MI].[RetailerReportSplitMonthly]
SET [PostActivatedSales] = PT.TranAmount,
	[PostActivatedTrans] = PT.TranCount,
	[PostActivatedSpender] =  PT.CustomerNo,
	[ActivatedCommission]  = PT.Commission

FROM [Warehouse].[MI].[RetailerReportSplitMonthly] SM
	inner join #PTCUML PT on 
	SM.PartnerID = PT.partnerid 
	and SM.Monthid = PT.Monthid
	and SM.[Cumulative] = 1  
	And SM.[Split_Use_For_Report] = PT.SplitRank
	and SM.[Status_Use_For_Report] = PT.StatusRank

--select * from #PTCUML


END