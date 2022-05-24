-- =============================================
-- Author:		<Adam Scott>
-- Create date: <16/07/2014>
-- Description:	< monthly Partner trans_fetch>
-- =============================================
CREATE PROCEDURE  [MI].[MonthlyRetailerReportssplitConNONCORE_Load] --30, 3960, 3960
(@MonthID int, @PartnerID int, @CONPartnerID int)
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

--declare @MonthID int, @PartnerID int, @CONPartnerID int
--set @MonthID = 30
--set @PartnerID =3960 
--set @CONPartnerID = 3960

IF Object_id('tempdb..#OutletAttribute') IS NOT NULL 
  DROP TABLE #outletattribute 

SELECT st.id                                                    
	   MonthID, 
       o.outletid, 
       o.partnerid, 
       psp.use_for_report                                       
	   SplitRank, 
       COALESCE(Min(a.use_for_report), psp.deafultstatustypeid) StatusRank, 
       st.startdate, 
       st.enddate 
INTO   #outletattribute 
FROM   warehouse.relational.schememid o 
       INNER JOIN [Warehouse].[MI].[reportsplituseforreport] psp 
               ON psp.partnerid = o.partnerid 
       CROSS JOIN (SELECT * 
                   FROM   relational.schemeuplifttrans_month st 
                   WHERE  st.id =@MonthID) st 
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
                         AND st.id = @MonthID) a 
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


select	max(p.PartnerID) as PartnerID,
		oa.StatusRank,
		oa.SplitRank,
--		case when SUT.isonline = 1 then 2 else 3 end as lableid,
		max(SUTM.ID) as MonthID,
		--Max(CON.PartnerID) as p, 
		Sum(SUT.Amount) as TranAmount,
		Count(*) as TranCount,
		count(DISTINCT SUT.FanID) as CustomerNo
		into #CON
from --SchemeUpliftTrans_TEPM as SUT 
[Warehouse].[Relational].[SchemeUpliftTrans] as SUT
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.Control_Stratified CON 
on CON.fanID = SUT.fanID 
inner join Relational.SchemeUpliftTrans_Month SUTM
	on SUT.addeddate between SUTM.StartDate and SUTM.EndDate and CON.MonthID = SUTM.ID 
inner join #OutletAttribute OA
	on OA.OutletID = SUT.OutletID and (OA.EndDate is null or OA.EndDate >= SUTM.EndDate) and (OA.StartDate <= SUTM.EndDate)
and p.PartnerID = OA.PartnerID 
Where	CON.MonthID = @MonthID and p.PartnerID = @PartnerID  and CON.PartnerID = @CONPartnerID and SUT.IsRetailReport = 1 and 
		SUT.Amount > 0
group by oa.StatusRank,
		oa.SplitRank,
		p.PartnerID,
		SUTM.ID

UPDATE   [Warehouse].[MI].[RetailerReportSplitMonthly]
SET [ControlCardholderSales] = CON.TranAmount,
	[ControlTrans] = CON.TranCount,
	[ControlSpender] =  CON.CustomerNo

FROM [Warehouse].[MI].[RetailerReportSplitMonthly] SM
	inner join #CON CON on 
	SM.PartnerID = con.partnerid 
	and SM.Monthid = con.Monthid
	and SM.[Cumulative] = 0  
	And SM.[Split_Use_For_Report] = con.SplitRank
	and SM.[Status_Use_For_Report] = con.StatusRank


END