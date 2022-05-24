
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <22/10/2014>
-- Description:	<loads INSchemeSalesWorking with monthly totals, monthly Payment totals, monthly Channel totals>
-- =============================================
CREATE PROCEDURE [MI].[INSchemeSalesWorking_load_month_Payment_Channel] (@DateID int)

AS

-- rewritten on 06/03/2015 by DW to include N/L/E
BEGIN
	SET NOCOUNT ON;

--Declare @Dateid as int 
--set @Dateid = 37

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
      ,SUM([TransactionAmount]) as INSchemeSales
	  ,Count(*) as INSchemeTransactions
      ,Count(distinct PT.[FanID]) as INSchemeSpenders
	  ,SUM(CommissionChargable) as Commission 
	  ,0 as Cardholders	 
into #Sales	
FROM [Relational].[PartnerTrans] PT
inner join Mi.Staging_Customer_Temp c on
		C.FanID = PT.FanID ANd pt.PartnerID=c.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
		on c.DateID = SUTM.id 
--Left Join Relational.Master_Retailer_Table MRT 
--		on MRT.PartnerID = PT.PartnerID
Inner JOIN MI.WorkingofferDates WO 
		ON WO.Partnerid = pt.PartnerID and WO.ClientServicesref = c.ClientServicesRef
left Join MI.OutletAttribute OA 
		on OA.OutletID = PT.OutletID AND PT.AddedDate between OA.StartDate and OA.EndDate
left join MI.RetailerMetricPaymentypes RMP 
		on PT.PaymentMethodID = RMP.SourcePaymentID and C.ProgramID = RMP.ProgramID 
where  pt.[EligibleForCashBack] = 1 and
		PT.TransactionAmount > 0 and 
		C.CumulativeTypeID = 0 and 
		C.DateID = @DateID and
		--c.PaymentRegisteredWithid = 0 and
		--(MRT.core is null or MRT.core = 'y') and 
		PT.TransactionDate Between Wo.StartDate and WO.EndDate
		and pt.addeddate between SUTM.StartDate and SUTM.EndDate 
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

insert into MI.INSchemeSalesWorking
select DISTINCT p.[Programid]
      ,0 [PartnerGroupID]
      ,w.[PartnerID]
      ,w.[ClientServicesRef] [ClientServiceRef]
      ,p.PaymentID as  [PaymentTypeID]
      ,ch.[ChannelID]
      ,ca.[CustomerAttributeID]
      ,m.[Mid_SplitID]
      ,0 [CumulativeTypeID]
      ,1 [PeriodTypeID]
      ,w.[DateID]
      ,ISNULL(s.[INSchemeSales],0) [INSchemeSales]
      ,ISNULL(s.[INSchemeTransactions],0) [INSchemeTransactions]
      ,ISNULL(s.[INSchemeSpenders],0) [INSchemeSpenders]
      ,ISNULL(s.[Commission],0) [Commission]
      ,ISNULL(s.[Cardholders],0) [Cardholders]
FROM MI.WorkingofferDates w 
--left Join Relational.Master_Retailer_Table MRT 
--		on MRT.PartnerID = w.PartnerID
CROSS JOIN MI.RetailerMetricPaymentypes p 
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON ((ca.CustomerAttributeID BETWEEN 3000 AND 3000+@Dateid)
OR (ca.CustomerAttributeID<3000 AND (w.Partnerid=3960 OR RIGHT(ca.CustomerAttributeID,1)<>4)))
INNER JOIN MI.RetailerMetricChanneltypes ch ON p.ProgramID=ch.ProgramID
INNER JOIN (SELECT DISTINCT Mid_SplitID, PartnerID FROM Warehouse.MI.RetailerReportMID_Split
UNION SELECT DISTINCT 0 Mid_SplitID, PartnerID FROM MI.WorkingofferDates) m ON m.PartnerID=w.PartnerID
LEFT JOIN #Sales s ON s.Programid=p.Programid
			    AND s.PartnerGroupID=0
			    AND s.PartnerID=w.PartnerID
			    AND s.ClientServiceRef=w.ClientServicesRef
			    AND s.PaymentTypeID=p.PaymentID
			    AND s.ChannelID=ch.ChannelID
			    AND CASE WHEN s.CustomerAttributeID_0<>0 THEN CustomerAttributeID_0
			    WHEN s.CustomerAttributeID_0BP<>0 THEN CustomerAttributeID_0BP
			    WHEN s.CustomerAttributeID_1<>0 THEN CustomerAttributeID_1
			    WHEN s.CustomerAttributeID_1BP<>0 THEN CustomerAttributeID_1BP
			    WHEN s.CustomerAttributeID_2<>0 THEN CustomerAttributeID_2
			    WHEN s.CustomerAttributeID_2BP<>0 THEN CustomerAttributeID_2BP
			    ELSE s.CustomerAttributeID_3 END	=ca.CustomerAttributeID
			    AND s.Mid_SplitID=m.Mid_SplitID
			    AND s.CumulativeTypeID=0
			    AND s.PeriodTypeID=1
			    AND s.DateID=w.DateID
WHERE (CASE WHEN ch.ChannelID=0 THEN 0 ELSE 1 END)+ (CASE WHEN m.Mid_SplitID=0 THEN 0 ELSE 1 END)+ 
(CASE WHEN ca.[CustomerAttributeID]=0 THEN 0 ELSE 1 END)<=1 
--and (MRT.core is null or MRT.core = 'y') 

delete from MI.INSchemeSalesWorking 
where CustomerAttributeID between 1 and 4 and CumulativeTypeID>0

delete from  MI.INSchemeSalesWorking
where CustomerAttributeID between 2001 and 2004 and CumulativeTypeID=1

delete from  MI.INSchemeSalesWorking
where CustomerAttributeID between 1001 and 1004 and CumulativeTypeID=2


DROP TABLE #Sales	

END