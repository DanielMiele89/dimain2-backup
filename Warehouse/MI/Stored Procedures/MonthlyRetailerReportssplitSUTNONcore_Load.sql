-- =============================================
-- Author:		<Adam Scott>
-- Create date: <03/07/2014>
-- Description:	< monthly Partner trans_fetch>
-- =============================================
CREATE PROCEDURE  [MI].[MonthlyRetailerReportssplitSUTNONcore_Load] 
(@MonthID int, @PartnerID int)
AS
BEGIN
	SET NOCOUNT ON;

--declare @MonthID int, @PartnerID int
--set @MonthID = 30
--set @PartnerID =3960 

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
		
		--BP.[StatusID],
		max(SUTM.ID) as MonthID,
		Sum(SUT.Amount)  as TranAmount,
		Count(*) as TranCount,
		count(DISTINCT SUT.FanID) as CustomerNo,
		C.ClientServicesRef
		into #sut
from warehouse.relational.[SchemeUpliftTrans] as SUT
inner join [Warehouse].[MI].[StagingCustomer] as c	
	on SUT.FanID = c.FanID
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
on SUT.addeddate between SUTM.StartDate and SUTM.EndDate and c.monthID = SUTM.id 
inner join #OutletAttribute OA
	on OA.OutletID = SUT.OutletID and (OA.EndDate is null or OA.EndDate >= SUTM.EndDate) and (OA.StartDate <= SUTM.EndDate)
and p.PartnerID = OA.PartnerID 

	
Where	SUT.IsRetailReport = 1 and
		SUT.Amount > 0 and 
		c.Labelid = 101 and
		SUTM.ID = @MonthID 
		and p.PartnerID = OA.PartnerID 
		and P.PartnerID = @PartnerID
		and C.ClientServicesRef is not null
group by oa.StatusRank,
		oa.SplitRank,
		p.PartnerID,
		SUTM.ID,
		C.ClientServicesRef


UPDATE   [Warehouse].[MI].[RetailerReportSplitMonthly]
SET [ActivatedSales] = SUT.TranAmount,
	[ActivatedTrans] = SUT.TranCount,
	[ActivatedSpender] =  SUT.CustomerNo

FROM [Warehouse].[MI].[RetailerReportSplitMonthly] SM
	inner join #SUT SUT on 
	SM.PartnerID = SUT.partnerid 
	and SM.Monthid = SUT.Monthid
	and SM.[Cumulative] = 0 
	And SM.[Split_Use_For_Report] = SUT.SplitRank
	and SM.[Status_Use_For_Report] = SUT.StatusRank
	and SM.ClientServicesRef = SUT.ClientServicesRef

--select * from #PTCUML


END