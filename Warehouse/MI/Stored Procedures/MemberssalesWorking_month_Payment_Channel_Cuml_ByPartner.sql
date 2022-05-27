

-- =============================================
-- Author:		<Adam Scott>
-- Create date: <23/10/2014>
-- Description:	<Populates MI.MemberssalesWorking with monthly data, online offline and payment totals>
CREATE PROCEDURE [MI].[MemberssalesWorking_month_Payment_Channel_Cuml_ByPartner] (@DateID int, @partnerid int )
	-- Add the parameters for the stored procedure here


AS
BEGIN

Select * 
into #Staging_Customer_TempCUMLandNonCore
from Mi.Staging_Customer_TempCUMLandNonCore
WHERE DateID = @DateID 
and PartnerID=@partnerid
and ClientServicesRef='0'

CREATE CLUSTERED INDEX IND ON #Staging_Customer_TempCUMLandNonCore(FanID, CumulativeTypeID)
CREATE INDEX IND2 ON #Staging_Customer_TempCUMLandNonCore(PartnerID, ClientServicesRef)


SELECT DISTINCT 1 as Programid
	  ,0 as PartnerGroupID 
	  ,pt.[PartnerID]
	  ,c.ClientServicesRef as ClientServiceRef
	  ,CASE WHEN GROUPING(RMP.PaymentID)=1 THEN 0 ELSE RMP.PaymentID END as PaymentTypeID
	  ,CASE WHEN GROUPING(Case when PT.isonline = 1 then 2 else 1 end)=1 THEN 0 ELSE Case when PT.isonline = 1 then 2 else 1 end END as ChannelID
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_0)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_0,-1) END as CustomerAttributeID_0
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_0BP)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_0BP,-1) END as CustomerAttributeID_0BP
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_1)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_1,-1) END as CustomerAttributeID_1
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_1BP)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_1BP,-1) END as CustomerAttributeID_1BP
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_2)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_2,-1) END as CustomerAttributeID_2
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_2BP)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_2BP,-1) END as CustomerAttributeID_2BP
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_3)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_3,-1) END as CustomerAttributeID_3
	  ,CASE WHEN GROUPING(OA.Mid_SplitID)=1 THEN 0 ELSE OA.Mid_SplitID END as Mid_SplitID
	  ,c.CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,C.DateID as DateID 
      ,SUM([Amount]) as MembersSales
	 ,Count(*) as MembersTransactions
      ,Count(distinct PT.[FanID]) as MembersSpenders
	  ,0 as Cardholders	 
into #ActiveSales
FROM [Relational].[SchemeUpliftTrans]  PT
inner join #Staging_Customer_TempCUMLandNonCore c on
		C.FanID = PT.FanID ANd pt.PartnerID=c.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
		on c.DateID = SUTM.id 
--Left Join Relational.Master_Retailer_Table MRT 
--		on MRT.PartnerID = PT.PartnerID
inner join MI.WorkingCumlDates CD 
		on CD.PartnerID = PT.PartnerID and CD.ClientServicesRef = C.ClientServicesRef and C.CumulativeTypeID = CD.Cumlitivetype
--Inner JOIN MI.WorkingofferDates WO 
--		ON WO.Partnerid = pt.PartnerID and WO.ClientServicesref = c.ClientServicesRef
left Join MI.OutletAttribute OA 
		on OA.OutletID = PT.OutletID AND PT.AddedDate between OA.StartDate and OA.EndDate
left join MI.RetailerMetricPaymentypes RMP 
		on PT.PaymentTypeID = RMP.PaymentID and C.ProgramID = RMP.ProgramID 
where  pt.IsRetailReport = 1 and
		PT.Amount > 0 and 
		C.DateID = @DateID 
		and c.PartnerID=@partnerid
		--c.PaymentRegisteredWithid = 0 and
		--(MRT.core is null or MRT.core = 'y') and 
		--PT.TransactionDate Between Wo.StartDate and WO.EndDate
		and pt.addeddate between CD.StartDate and SUTM.EndDate 
Group BY pt.[PartnerID], C.DateID,c.ClientServicesRef,c.CumulativeTypeID,
GROUPING SETS( 
(RMP.PaymentID,Case when pT.isonline = 1 then 2 else 1 end),
(RMP.PaymentID,OA.Mid_SplitID),
(RMP.PaymentID,c.CustomerAttributeID_0),
(RMP.PaymentID,c.CustomerAttributeID_0BP),
(RMP.PaymentID,c.CustomerAttributeID_1),
(RMP.PaymentID,c.CustomerAttributeID_1BP),
(RMP.PaymentID,c.CustomerAttributeID_2),
(RMP.PaymentID,c.CustomerAttributeID_2BP),
(RMP.PaymentID,c.CustomerAttributeID_3),
(RMP.PaymentID),
(Case when pT.isonline = 1 then 2 else 1 end),
(OA.Mid_SplitID),
(c.CustomerAttributeID_0),
(c.CustomerAttributeID_0BP),
(c.CustomerAttributeID_1),
(c.CustomerAttributeID_1BP),
(c.CustomerAttributeID_2),
(c.CustomerAttributeID_2BP),
(c.CustomerAttributeID_3),
())

SELECT DISTINCT 1 as Programid
	  ,0 as PartnerGroupID 
	  ,pt.[PartnerID]
	  ,c.ClientServicesRef as ClientServiceRef
	  ,CASE WHEN GROUPING(RMP.PaymentID)=1 THEN 0 ELSE RMP.PaymentID END as PaymentTypeID
	  ,CASE WHEN GROUPING(Case when PT.isonline = 1 then 2 else 1 end)=1 THEN 0 ELSE Case when PT.isonline = 1 then 2 else 1 end END as ChannelID
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_0)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_0,-1) END as CustomerAttributeID_0
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_0BP)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_0BP,-1) END as CustomerAttributeID_0BP
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_1)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_1,-1) END as CustomerAttributeID_1
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_1BP)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_1BP,-1) END as CustomerAttributeID_1BP
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_2)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_2,-1) END as CustomerAttributeID_2
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_2BP)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_2BP,-1) END as CustomerAttributeID_2BP
	  ,CASE WHEN GROUPING(c.CustomerAttributeID_3)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_3,-1) END as CustomerAttributeID_3
	  ,CASE WHEN GROUPING(OA.Mid_SplitID)=1 THEN 0 ELSE OA.Mid_SplitID END as Mid_SplitID
	  ,c.CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,C.DateID as DateID 
 	  ,SUM([Amount]) as MembersPostActivationSales
	  ,Count(*) as MembersPostActivationTransactions
      ,Count(distinct PT.[FanID]) as MembersPostActivationSpenders
--	  ,0 as Cardholders	 
into #PostSales
FROM [Relational].[SchemeUpliftTrans]  PT
inner join #Staging_Customer_TempCUMLandNonCore c on
		C.FanID = PT.FanID ANd pt.PartnerID=c.PartnerID and PT.TranDate between C.StartDate and c.EndDate
inner join Relational.SchemeUpliftTrans_Month SUTM
		on c.DateID = SUTM.id 
--Left Join Relational.Master_Retailer_Table MRT 
--		on MRT.PartnerID = PT.PartnerID
inner join MI.WorkingCumlDates CD 
		on CD.PartnerID = PT.PartnerID and CD.ClientServicesRef = C.ClientServicesRef and C.CumulativeTypeID = CD.Cumlitivetype
Inner JOIN MI.WorkingofferDates WO 
		ON WO.Partnerid = pt.PartnerID and WO.ClientServicesref = c.ClientServicesRef
left Join MI.OutletAttribute OA 
		on OA.OutletID = PT.OutletID AND PT.AddedDate between OA.StartDate and OA.EndDate
left join MI.RetailerMetricPaymentypes RMP 
		on PT.PaymentTypeID = RMP.PaymentID and C.ProgramID = RMP.ProgramID 
where  pt.IsRetailReport = 1 and
		PT.Amount > 0 and 
		C.DateID = @DateID 
		and c.PartnerID=@partnerid
		--c.PaymentRegisteredWithid = 0 and
		--(MRT.core is null or MRT.core = 'y') and 
		and PT.TranDate Between Wo.StartDate and WO.EndDate
		and pt.addeddate between CD.StartDate and SUTM.EndDate 
Group BY pt.[PartnerID], C.DateID,c.ClientServicesRef,c.CumulativeTypeID,
GROUPING SETS( 
(RMP.PaymentID,Case when pT.isonline = 1 then 2 else 1 end),
(RMP.PaymentID,OA.Mid_SplitID),
(RMP.PaymentID,c.CustomerAttributeID_0),
(RMP.PaymentID,c.CustomerAttributeID_0BP),
(RMP.PaymentID,c.CustomerAttributeID_1),
(RMP.PaymentID,c.CustomerAttributeID_1BP),
(RMP.PaymentID,c.CustomerAttributeID_2),
(RMP.PaymentID,c.CustomerAttributeID_2BP),
(RMP.PaymentID,c.CustomerAttributeID_3),
(RMP.PaymentID),
(Case when pT.isonline = 1 then 2 else 1 end),
(OA.Mid_SplitID),
(c.CustomerAttributeID_0),
(c.CustomerAttributeID_0BP),
(c.CustomerAttributeID_1),
(c.CustomerAttributeID_1BP),
(c.CustomerAttributeID_2),
(c.CustomerAttributeID_2BP),
(c.CustomerAttributeID_3),
())

insert into MI.MemberssalesWorking
select DISTINCT p.[Programid]
      ,0 [PartnerGroupID]
      ,w.[PartnerID]
      ,w.[ClientServicesRef] [ClientServiceRef]
      ,p.PaymentID as  [PaymentTypeID]
      ,ch.[ChannelID]
      ,ca.[CustomerAttributeID]
      ,m.[Mid_SplitID]
      ,w.Cumlitivetype [CumulativeTypeID]
      ,1 [PeriodTypeID]
      ,w.[DateID]
      ,ISNULL(s.[MembersSales],0) AS [MembersSales]
      ,ISNULL(s.MembersTransactions,0) AS [MembersTransactions]
      ,ISNULL(s.MembersSpenders,0) AS [MembersSpenders]
	  ,ISNULL(s.[Cardholders],0) AS [Cardholders]
	  ,ISNULL(ps.MembersPostActivationSales,0) AS [MembersPostActivationSales]
      ,ISNULL(ps.MembersPostActivationTransactions,0) AS [MembersPostActivationTransactions]
      ,ISNULL(Ps.MembersPostActivationSpenders,0) AS [MembersPostActivationSpenders]      
FROM MI.WorkingCumlDates w 
--left Join Relational.Master_Retailer_Table MRT 
--		on MRT.PartnerID = w.PartnerID
CROSS JOIN MI.RetailerMetricPaymentypes p 
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON (ca.CustomerAttributeID BETWEEN 3000 AND 3000+@Dateid)
OR (ca.CustomerAttributeID<3000 AND (w.Partnerid=3960 OR RIGHT(ca.CustomerAttributeID,1)<>4))
INNER JOIN MI.RetailerMetricChanneltypes ch ON p.ProgramID=ch.ProgramID
INNER JOIN (SELECT DISTINCT Mid_SplitID, PartnerID FROM Warehouse.MI.RetailerReportMID_Split
UNION SELECT DISTINCT 0 Mid_SplitID, PartnerID FROM MI.WorkingofferDates) m ON m.PartnerID=w.PartnerID
LEFT JOIN #ActiveSales s ON s.Programid=p.Programid
			    AND s.PartnerGroupID=0
			    AND s.PartnerID=w.PartnerID
			    AND s.ClientServiceRef=w.ClientServicesRef
			    AND s.PaymentTypeID=p.PaymentID
			    AND s.ChannelID=ch.ChannelID
			    AND CASE WHEN s.CustomerAttributeID_0<>0 THEN s.CustomerAttributeID_0
			    WHEN s.CustomerAttributeID_0BP<>0 THEN s.CustomerAttributeID_0BP
			    WHEN s.CustomerAttributeID_1<>0 THEN s.CustomerAttributeID_1
			    WHEN s.CustomerAttributeID_1BP<>0 THEN s.CustomerAttributeID_1BP
			    WHEN s.CustomerAttributeID_2<>0 THEN s.CustomerAttributeID_2
			    WHEN s.CustomerAttributeID_2BP<>0 THEN s.CustomerAttributeID_2BP
			    ELSE s.CustomerAttributeID_3 END	=ca.CustomerAttributeID
			    AND s.Mid_SplitID=m.Mid_SplitID
			    AND s.PeriodTypeID=1
			    AND s.DateID=w.DateID
			    AND s.CumulativeTypeID=w.Cumlitivetype
LEFT JOIN #PostSales ps ON ps.Programid=p.Programid
			    AND ps.PartnerGroupID=0
			    AND ps.PartnerID=w.PartnerID
			    AND ps.ClientServiceRef=w.ClientServicesRef
			    AND ps.PaymentTypeID=p.PaymentID
			    AND ps.ChannelID=ch.ChannelID
			    AND CASE WHEN ps.CustomerAttributeID_0<>0 THEN ps.CustomerAttributeID_0
			    WHEN ps.CustomerAttributeID_0BP<>0 THEN ps.CustomerAttributeID_0BP
			    WHEN ps.CustomerAttributeID_1<>0 THEN ps.CustomerAttributeID_1
			    WHEN ps.CustomerAttributeID_1BP<>0 THEN ps.CustomerAttributeID_1BP
			    WHEN ps.CustomerAttributeID_2<>0 THEN ps.CustomerAttributeID_2
			    WHEN ps.CustomerAttributeID_2BP<>0 THEN ps.CustomerAttributeID_2BP
			    ELSE ps.CustomerAttributeID_3 END	=ca.CustomerAttributeID
			    AND ps.Mid_SplitID=m.Mid_SplitID
			    AND Ps.PeriodTypeID=1
			    AND pS.CumulativeTypeID=w.Cumlitivetype
WHERE  (CASE WHEN ch.ChannelID=0 THEN 0 ELSE 1 END)+ (CASE WHEN m.Mid_SplitID=0 THEN 0 ELSE 1 END)+ 
(CASE WHEN ca.[CustomerAttributeID]=0 THEN 0 ELSE 1 END)<=1 
and w.PartnerID=@partnerid
and w.DateID = @DateID 
and w.ClientServicesRef='0'
--and (MRT.core is null or MRT.core = 'y') 


delete from  MI.MembersSalesWorking
where CustomerAttributeID between 1 and 4 and CumulativeTypeID>0

delete from  MI.MembersSalesWorking
where CustomerAttributeID between 1001 and 1004 and CumulativeTypeID=2

delete from  MI.MembersSalesWorking
where CustomerAttributeID between 2001 and 2004 and CumulativeTypeID=1

DROP TABLE #PostSales
DROP TABLE #ActiveSales
DROP TABLE #Staging_Customer_TempCUMLandNonCore

END
