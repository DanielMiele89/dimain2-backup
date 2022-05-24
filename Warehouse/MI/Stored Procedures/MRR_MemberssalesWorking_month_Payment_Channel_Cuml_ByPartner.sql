

-- =============================================
-- Author:		<Adam Scott>
-- Create date: <23/10/2014>
-- Description:	<Populates MI.MemberssalesWorking with monthly data, online offline and payment totals>
CREATE PROCEDURE [MI].[MRR_MemberssalesWorking_month_Payment_Channel_Cuml_ByPartner] (@DateID int, @partnerid int )
	-- Add the parameters for the stored procedure here


AS
BEGIN

SELECT DISTINCT 1 as Programid
	  ,0 as PartnerGroupID 
	  ,pt.[PartnerID]
	  ,pt.ClientServiceRef as ClientServiceRef
	  ,CASE WHEN GROUPING(pt.PaymentTypeID)=1 THEN 0 ELSE pt.PaymentTypeID END as PaymentTypeID
	  ,CASE WHEN GROUPING(pt.ChannelID)=1 THEN 0 ELSE pt.ChannelID END as ChannelID
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_0)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_0,-1) END as CustomerAttributeID_0
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_0BP)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_0BP,-1) END as CustomerAttributeID_0BP
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_1)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_1,-1) END as CustomerAttributeID_1
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_1BP)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_1BP,-1) END as CustomerAttributeID_1BP
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_2)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_2,-1) END as CustomerAttributeID_2
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_2BP)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_2BP,-1) END as CustomerAttributeID_2BP
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_3)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_3,-1) END as CustomerAttributeID_3
	  ,CASE WHEN GROUPING(pt.Mid_SplitID)=1 THEN 0 ELSE pt.Mid_SplitID END as Mid_SplitID
	  ,pt.CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,pt.DateID as DateID 
      ,SUM(pt.MemberSales) as MembersSales
	  ,SUM(PT.MemberTransactions) as MembersTransactions
      ,COUNT(DISTINCT PT.[FanID]) as MembersSpenders
	  ,0 as Cardholders	 
INTO #ActiveSales
FROM MI.MRR_MemberSales_Working  PT
GROUP BY pt.[PartnerID], pt.DateID,pt.ClientServiceRef,pt.CumulativeTypeID,
GROUPING SETS( 
(pt.PaymentTypeID,pt.ChannelID),
(pt.PaymentTypeID,pt.Mid_SplitID),
(pt.PaymentTypeID,pt.CustomerAttributeID_0),
(pt.PaymentTypeID,pt.CustomerAttributeID_0BP),
(pt.PaymentTypeID,pt.CustomerAttributeID_1),
(pt.PaymentTypeID,pt.CustomerAttributeID_1BP),
(pt.PaymentTypeID,pt.CustomerAttributeID_2),
(pt.PaymentTypeID,pt.CustomerAttributeID_2BP),
(pt.PaymentTypeID,pt.CustomerAttributeID_3),
(pt.PaymentTypeID),
(pt.ChannelID),
(pt.Mid_SplitID),
(pt.CustomerAttributeID_0),
(pt.CustomerAttributeID_0BP),
(pt.CustomerAttributeID_1),
(pt.CustomerAttributeID_1BP),
(pt.CustomerAttributeID_2),
(pt.CustomerAttributeID_2BP),
(pt.CustomerAttributeID_3),
())

SELECT DISTINCT 1 as Programid
	  ,0 as PartnerGroupID 
	  ,pt.[PartnerID]
	  ,pt.ClientServiceRef as ClientServiceRef
	  ,CASE WHEN GROUPING(pt.PaymentTypeID)=1 THEN 0 ELSE pt.PaymentTypeID END as PaymentTypeID
	  ,CASE WHEN GROUPING(pt.ChannelID)=1 THEN 0 ELSE pt.ChannelID END as ChannelID
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_0)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_0,-1) END as CustomerAttributeID_0
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_0BP)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_0BP,-1) END as CustomerAttributeID_0BP
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_1)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_1,-1) END as CustomerAttributeID_1
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_1BP)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_1BP,-1) END as CustomerAttributeID_1BP
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_2)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_2,-1) END as CustomerAttributeID_2
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_2BP)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_2BP,-1) END as CustomerAttributeID_2BP
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_3)=1 THEN 0 ELSE COALESCE(pt.CustomerAttributeID_3,-1) END as CustomerAttributeID_3
	  ,CASE WHEN GROUPING(pt.Mid_SplitID)=1 THEN 0 ELSE pt.Mid_SplitID END as Mid_SplitID
	  ,pt.CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,pt.DateID as DateID
	  ,SUM(pt.MemberSales) as MembersSales 
	  ,SUM(PT.MemberTransactions) as MembersTransactions
      ,COUNT(DISTINCT PT.[FanID]) as MembersSpenders
	  ,0 as Cardholders	 
INTO #PostSales
FROM MI.MRR_MemberSales_Working  PT
WHERE IsPost = 1
GROUP BY pt.[PartnerID], pt.DateID,pt.ClientServiceRef,pt.CumulativeTypeID,
GROUPING SETS( 
(pt.PaymentTypeID,pt.ChannelID),
(pt.PaymentTypeID,pt.Mid_SplitID),
(pt.PaymentTypeID,pt.CustomerAttributeID_0),
(pt.PaymentTypeID,pt.CustomerAttributeID_0BP),
(pt.PaymentTypeID,pt.CustomerAttributeID_1),
(pt.PaymentTypeID,pt.CustomerAttributeID_1BP),
(pt.PaymentTypeID,pt.CustomerAttributeID_2),
(pt.PaymentTypeID,pt.CustomerAttributeID_2BP),
(pt.PaymentTypeID,pt.CustomerAttributeID_3),
(pt.PaymentTypeID),
(pt.ChannelID),
(pt.Mid_SplitID),
(pt.CustomerAttributeID_0),
(pt.CustomerAttributeID_0BP),
(pt.CustomerAttributeID_1),
(pt.CustomerAttributeID_1BP),
(pt.CustomerAttributeID_2),
(pt.CustomerAttributeID_2BP),
(pt.CustomerAttributeID_3),
())

INSERT INTO MI.MemberssalesWorking
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
	  ,ISNULL(ps.MembersSales,0) AS [MembersPostActivationSales]
      ,ISNULL(ps.MembersTransactions,0) AS [MembersPostActivationTransactions]
      ,ISNULL(Ps.MembersSpenders,0) AS [MembersPostActivationSpenders]      
FROM MI.WorkingCumlDates w 
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
--and w.ClientServicesRef='0'
--and (MRT.core is null or MRT.core = 'y') 


delete from  MI.MemberssalesWorking
where CustomerAttributeID between 1 and 4 and CumulativeTypeID>0

delete from  MI.MemberssalesWorking
where CustomerAttributeID between 1001 and 1004 and CumulativeTypeID=2

delete from  MI.MemberssalesWorking
where CustomerAttributeID between 2001 and 2004 and CumulativeTypeID=1

DROP TABLE #PostSales
DROP TABLE #ActiveSales

END