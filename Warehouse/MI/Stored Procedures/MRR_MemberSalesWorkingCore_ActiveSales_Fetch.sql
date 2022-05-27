-- =============================================
-- Author:		JEA
-- Create date: 21/04/2015
-- Description:	Loads active sales for member sales working
-- =============================================
CREATE PROCEDURE MI.MRR_MemberSalesWorkingCore_ActiveSales_Fetch
	(
		@DateID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT DISTINCT 1 AS Programid
		,0 AS PartnerGroupID 
		,pt.PartnerID
		,c.ClientServicesRef as ClientServiceRef
		,CASE WHEN GROUPING(RMP.PaymentID)=1 THEN 0 ELSE RMP.PaymentID END as PaymentTypeID
		,CASE WHEN GROUPING(CASE WHEN PT.isonline = 1 THEN 2 ELSE 1 END)=1 THEN 0 ELSE CASE WHEN PT.isonline = 1 THEN 2 ELSE 1 END END AS ChannelID
		,CASE WHEN GROUPING(c.CustomerAttributeID_0)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_0,-1) END as CustomerAttributeID_0
		,CASE WHEN GROUPING(c.CustomerAttributeID_0BP)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_0BP,-1) END AS CustomerAttributeID_0BP
		,CASE WHEN GROUPING(c.CustomerAttributeID_1)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_1,-1) END AS CustomerAttributeID_1
		,CASE WHEN GROUPING(c.CustomerAttributeID_1BP)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_1BP,-1) END AS CustomerAttributeID_1BP
		,CASE WHEN GROUPING(c.CustomerAttributeID_2)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_2,-1) END AS CustomerAttributeID_2
		,CASE WHEN GROUPING(c.CustomerAttributeID_2BP)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_2BP,-1) END AS CustomerAttributeID_2BP
		,CASE WHEN GROUPING(c.CustomerAttributeID_3)=1 THEN 0 ELSE COALESCE(c.CustomerAttributeID_3,-1) END AS CustomerAttributeID_3
		,CASE WHEN GROUPING(OA.Mid_SplitID)=1 THEN 0 ELSE OA.Mid_SplitID END AS Mid_SplitID
		,c.CumulativeTypeID
		,1 AS PeriodTypeID
		,C.DateID AS DateID 
		,SUM([Amount]) AS MembersSales
		,COUNT(*) AS MembersTransactions
		,COUNT(DISTINCT PT.[FanID]) AS MembersSpenders
		,0 AS Cardholders	 
	FROM [Relational].[SchemeUpliftTrans]  PT
	INNER JOIN Mi.Staging_Customer_TempCUMLandNonCore c ON
			C.FanID = PT.FanID AND pt.PartnerID=c.PartnerID
	INNER JOIN Relational.SchemeUpliftTrans_Month SUTM
			ON c.DateID = SUTM.id 
	INNER JOIN MI.WorkingCumlDates CD 
			ON CD.PartnerID = PT.PartnerID AND CD.ClientServicesRef = C.ClientServicesRef AND C.CumulativeTypeID = CD.Cumlitivetype
	LEFT OUTER JOIN MI.OutletAttribute OA 
			ON OA.OutletID = PT.OutletID AND PT.AddedDate BETWEEN OA.StartDate AND OA.EndDate
	LEFT OUTER JOIN MI.RetailerMetricPaymentypes RMP 
			on PT.PaymentTypeID = RMP.PaymentID AND C.ProgramID = RMP.ProgramID 
	WHERE  pt.IsRetailReport = 1
		AND PT.Amount > 0
		AND C.DateID = @DateID 
		AND pt.addeddate BETWEEN CD.StartDate AND SUTM.EndDate
		AND c.ClientServicesRef = '0'
	GROUP BY pt.[PartnerID], C.DateID,c.ClientServicesRef,c.CumulativeTypeID,
	GROUPING SETS( 
	(RMP.PaymentID,CASE WHEN PT.isonline = 1 THEN 2 ELSE 1 END),
	(RMP.PaymentID,OA.Mid_SplitID),
	(RMP.PaymentID,c.CustomerAttributeID_0),
	(RMP.PaymentID,c.CustomerAttributeID_0BP),
	(RMP.PaymentID,c.CustomerAttributeID_1),
	(RMP.PaymentID,c.CustomerAttributeID_1BP),
	(RMP.PaymentID,c.CustomerAttributeID_2),
	(RMP.PaymentID,c.CustomerAttributeID_2BP),
	(RMP.PaymentID,c.CustomerAttributeID_3),
	(RMP.PaymentID),
	(CASE WHEN pT.isonline = 1 THEN 2 ELSE 1 END),
	(OA.Mid_SplitID),
	(c.CustomerAttributeID_0),
	(c.CustomerAttributeID_0BP),
	(c.CustomerAttributeID_1),
	(c.CustomerAttributeID_1BP),
	(c.CustomerAttributeID_2),
	(c.CustomerAttributeID_2BP),
	(c.CustomerAttributeID_3),
	())

END
