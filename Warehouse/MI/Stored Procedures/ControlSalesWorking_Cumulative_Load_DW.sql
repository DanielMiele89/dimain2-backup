
--USE Warehouse_Dev
--GO
--/****** Object:  StoredProcedure MI.ControlSalesWorking_load_month_Payment_Channel    Script Date: 03/11/2014 16:57:57 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO truncate table MI.ControlSalesWorking
-- =============================================
-- Author:		Dorota
-- Create date:     03/12/2014
-- Description:	Control Sales Monthly
-- =============================================
CREATE PROCEDURE [MI].[ControlSalesWorking_Cumulative_Load_DW] (@DateID int, @Partnerid int, @ControlPartnerid int)

AS
BEGIN
	SET NOCOUNT ON;

SELECT *
into #Staging_Control_Temp
FROM Mi.Staging_Control_Temp
 WHERE PartnerID=@Partnerid
 AND DateID=@DateID

CREATE CLUSTERED INDEX IND ON #Staging_Control_Temp(FanID, CumulativeTypeID)
CREATE INDEX IND2 ON #Staging_Control_Temp(PartnerID, ClientServicesRef)


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
      ,SUM([Amount]) as ControlSales
	 ,Count(*) as ControlTransactions
      ,Count(distinct PT.[FanID]) as ControlSpenders
	  ,0 as Cardholders	 
into #Sales
FROM [Relational].[SchemeUpliftTrans]  PT
inner join #Staging_Control_Temp c on
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

SELECT  p.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,p.PaymentID as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,@DateID as DateID 
      ,COUNT(DISTINCT CON.FanID) as ControlCardHolders
INTO #Customers	
FROM  #Staging_Control_Temp CON 
CROSS JOIN MI.RetailerMetricPaymentypes p
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=0
WHERE CON.DateID = @DateID AND CON.Partnerid = @PartnerID
and p.PaymentID<>2 and p.ProgramID=1 and con.CumulativeTypeID<>0
GROUP BY isnull(CON.ClientServicesRef,'0'),p.PaymentID,con.CumulativeTypeID, p.ProgramID,CON.PartnerID, ca.CustomerAttributeID
UNION ALL
SELECT  p.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,p.PaymentID as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,@DateID as DateID 
      ,COUNT(DISTINCT CON.FanID) as ControlCardHolders
FROM  #Staging_Control_Temp CON 
CROSS JOIN MI.RetailerMetricPaymentypes p
CROSS JOIN MI.RetailerMetricCumulativeType c 
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_0
WHERE CON.DateID = @DateID AND CON.Partnerid = @PartnerID
and p.PaymentID<>2 and p.ProgramID=1 and con.CumulativeTypeID<>0
GROUP BY isnull(CON.ClientServicesRef,'0'),p.PaymentID,con.CumulativeTypeID, p.ProgramID,CON.PartnerID,ca.CustomerAttributeID 
UNION ALL
SELECT  p.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,p.PaymentID as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,@DateID as DateID 
      ,COUNT(DISTINCT CON.FanID) as ControlCardHolders
FROM  #Staging_Control_Temp CON 
CROSS JOIN MI.RetailerMetricPaymentypes p
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_0BP
WHERE CON.DateID = @DateID AND CON.Partnerid = @PartnerID
and p.PaymentID<>2 and p.ProgramID=1 and con.CumulativeTypeID<>0
GROUP BY isnull(CON.ClientServicesRef,'0'),p.PaymentID,con.CumulativeTypeID, p.ProgramID,CON.PartnerID,ca.CustomerAttributeID 
UNION ALL
SELECT  p.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,p.PaymentID as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,@DateID as DateID 
      ,COUNT(DISTINCT CON.FanID) as ControlCardHolders
FROM  #Staging_Control_Temp CON 
CROSS JOIN MI.RetailerMetricPaymentypes p
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_1
WHERE CON.DateID = @DateID AND CON.Partnerid = @PartnerID
and p.PaymentID<>2 and p.ProgramID=1 and con.CumulativeTypeID<>0
GROUP BY isnull(CON.ClientServicesRef,'0'),p.PaymentID,con.CumulativeTypeID, p.ProgramID,CON.PartnerID,ca.CustomerAttributeID 
UNION ALL
SELECT  p.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,p.PaymentID as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,@DateID as DateID 
      ,COUNT(DISTINCT CON.FanID) as ControlCardHolders
FROM  #Staging_Control_Temp CON 
CROSS JOIN MI.RetailerMetricPaymentypes p
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_1BP
WHERE CON.DateID = @DateID AND CON.Partnerid = @PartnerID
and p.PaymentID<>2 and p.ProgramID=1 and con.CumulativeTypeID<>0
GROUP BY isnull(CON.ClientServicesRef,'0'),p.PaymentID,con.CumulativeTypeID, p.ProgramID,CON.PartnerID,ca.CustomerAttributeID 
UNION ALL
SELECT  p.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,p.PaymentID as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,@DateID as DateID 
      ,COUNT(DISTINCT CON.FanID) as ControlCardHolders
FROM  #Staging_Control_Temp CON 
CROSS JOIN MI.RetailerMetricPaymentypes p
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_2
WHERE CON.DateID = @DateID AND CON.Partnerid = @PartnerID
and p.PaymentID<>2 and p.ProgramID=1 and con.CumulativeTypeID<>0
GROUP BY isnull(CON.ClientServicesRef,'0'),p.PaymentID,con.CumulativeTypeID, p.ProgramID,CON.PartnerID,ca.CustomerAttributeID 
UNION ALL
SELECT  p.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,p.PaymentID as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,@DateID as DateID 
      ,COUNT(DISTINCT CON.FanID) as ControlCardHolders
FROM  #Staging_Control_Temp CON 
CROSS JOIN MI.RetailerMetricPaymentypes p
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_2BP
WHERE CON.DateID = @DateID AND CON.Partnerid = @PartnerID
and p.PaymentID<>2 and p.ProgramID=1 and con.CumulativeTypeID<>0
GROUP BY isnull(CON.ClientServicesRef,'0'),p.PaymentID,con.CumulativeTypeID, p.ProgramID,CON.PartnerID,ca.CustomerAttributeID 
UNION ALL
SELECT  p.ProgramID as Programid
	  ,0 as PartnerGroupID 
	  ,CON.PartnerID
	  ,isnull(CON.ClientServicesRef,'0') as ClientServiceRef
	  ,p.PaymentID as PaymentTypeID
	  ,ca.CustomerAttributeID
	  ,con.CumulativeTypeID as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,@DateID as DateID 
      ,COUNT(DISTINCT CON.FanID) as ControlCardHolders
FROM  #Staging_Control_Temp CON 
CROSS JOIN MI.RetailerMetricPaymentypes p
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ca.CustomerAttributeID=CON.CustomerAttributeID_3
WHERE CON.DateID = @DateID AND CON.Partnerid = @PartnerID
and p.PaymentID<>2 and p.ProgramID=1 and con.CumulativeTypeID<>0
GROUP BY isnull(CON.ClientServicesRef,'0'),p.PaymentID,con.CumulativeTypeID, p.ProgramID,CON.PartnerID,ca.CustomerAttributeID 

INSERT INTO MI.ControlSalesWorking
SELECT DISTINCT c.Programid
	 ,c.PartnerGroupID
	 ,c.PartnerID
	 ,c.ClientServiceRef
	 ,c.PaymentTypeID
	 ,ch.ChannelID
	 ,c.CustomerAttributeID
	 ,m.Mid_SplitID
	 ,c.CumulativeTypeID
	 ,c.PeriodTypeID
	 ,c.DateID
	 ,ISNULL(s.Controlsales,0) Controlsales
	 ,ISNULL(s.ControlTransactions,0) ControlTransactions
	 ,ISNULL(s.ControlSpenders,0) ControlSpenders
	 ,c.ControlCardHolders
	 ,adj.AdjFactorSPC
      ,adj.AdjFactorTPC
      ,adj.AdjFactorRR
FROM #Customers c
INNER JOIN MI.RetailerMetricPaymentypes p ON p.PaymentID=c.PaymentTypeID and p.ProgramID=c.ProgramID
INNER JOIN MI.RetailerMetricChanneltypes ch ON ch.ProgramID=c.ProgramID
INNER JOIN (SELECT Mid_SplitID, PartnerID FROM Warehouse.MI.RetailerReportMID_Split
UNION SELECT 0 Mid_SplitID, @Partnerid PartnerID) m ON m.PartnerID=c.PartnerID
LEFT JOIN MI.RetailAdjustmentFactor adj  ON adj.Programid=c.Programid
			    AND adj.PartnerGroupID=c.PartnerGroupID
			    AND adj.PartnerID=c.PartnerID
			    AND adj.ClientServicesRef=c.ClientServiceRef
			    AND adj.PaymentTypeID=c.PaymentTypeID
			    AND adj.ChannelID=ch.ChannelID
			    AND adj.CustomerAttributeID=c.CustomerAttributeID
			    AND adj.Mid_SplitID=m.Mid_SplitID
			    AND adj.CumulativeTypeID=c.CumulativeTypeID
			    AND adj.PeriodTypeID=c.PeriodTypeID
			    AND adj.DateID=c.DateID 
LEFT JOIN #Sales s ON s.Programid=c.Programid
			    AND s.PartnerGroupID=c.PartnerGroupID
			    AND s.PartnerID=c.PartnerID
			    AND s.ClientServiceRef=c.ClientServiceRef
			    AND s.PaymentTypeID=c.PaymentTypeID
			    AND s.ChannelID=ch.ChannelID
			    AND CASE WHEN s.CustomerAttributeID_0<>0 THEN s.CustomerAttributeID_0
			    WHEN s.CustomerAttributeID_0BP<>0 THEN s.CustomerAttributeID_0BP
			    WHEN s.CustomerAttributeID_1<>0 THEN s.CustomerAttributeID_1
			    WHEN s.CustomerAttributeID_1BP<>0 THEN s.CustomerAttributeID_1BP
			    WHEN s.CustomerAttributeID_2<>0 THEN s.CustomerAttributeID_2
			    WHEN s.CustomerAttributeID_2BP<>0 THEN s.CustomerAttributeID_2BP
			    ELSE s.CustomerAttributeID_3 END	=c.CustomerAttributeID
			    AND s.Mid_SplitID=m.Mid_SplitID
			    AND s.CumulativeTypeID=c.CumulativeTypeID
			    AND s.PeriodTypeID=c.PeriodTypeID
			    AND s.DateID=c.DateID
WHERE (CASE WHEN ch.ChannelID=0 THEN 0 ELSE 1 END)+ (CASE WHEN m.Mid_SplitID=0 THEN 0 ELSE 1 END)+ 
(CASE WHEN c.[CustomerAttributeID]=0 THEN 0 ELSE 1 END)<=1 

delete from  MI.ControlSalesWorking
where CustomerAttributeID between 1001 and 1004 and CumulativeTypeID=2

delete from  MI.ControlSalesWorking
where CustomerAttributeID between 1 and 4 and CumulativeTypeID>0

delete from  MI.ControlSalesWorking
where CustomerAttributeID between 1001 and 1004 and CumulativeTypeID=2

delete from  MI.ControlSalesWorking WHERE ControlCardholders=0

DROP TABLE #Sales
DROP TABLE #Customers
DROP TABLE #Staging_Control_Temp

END