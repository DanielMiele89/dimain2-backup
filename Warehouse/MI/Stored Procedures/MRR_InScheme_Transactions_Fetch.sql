-- =============================================
-- Author:		JEA
-- Create date: 14/10/2015
-- =============================================
CREATE PROCEDURE [MI].[MRR_InScheme_Transactions_Fetch]
	(
		@DateID INT
		, @partnerid INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthEndDate DATE

	SELECT @MonthEndDate = EndDate
	FROM Relational.SchemeUpliftTrans_Month
	WHERE ID = @DateID

	SELECT pt.[PartnerID]
		,c.ClientServicesRef as ClientServiceRef
		,RMP.PaymentID as PaymentTypeID
		,CAST(CASE WHEN PT.isonline = 1 THEN 2 ELSE 1 END AS TINYINT) as ChannelID
		,COALESCE(c.CustomerAttributeID_0,-1) AS CustomerAttributeID_0
		,COALESCE(c.CustomerAttributeID_0BP,-1) AS CustomerAttributeID_0BP
		,COALESCE(c.CustomerAttributeID_1,-1) AS CustomerAttributeID_1
		,COALESCE(c.CustomerAttributeID_1BP,-1) AS CustomerAttributeID_1BP
		,COALESCE(c.CustomerAttributeID_2,-1) AS CustomerAttributeID_2
		,COALESCE(c.CustomerAttributeID_2BP,-1) AS CustomerAttributeID_2BP
		,COALESCE(c.CustomerAttributeID_3,-1) AS CustomerAttributeID_3
		,OA.Mid_SplitID
		,c.CumulativeTypeID AS CumulativeTypeID
		,1 AS PeriodTypeID
		,C.DateID AS DateID 
		,pt.TransactionAmount AS InSchemeSales
		,CAST(1 AS INT) AS InSchemeTransactions
		,PT.[FanID]
		,PT.CommissionChargable as Commission 
		,0 as Cardholders
	FROM [Relational].[PartnerTrans] PT
	INNER JOIN MI.MRR_Customer_Working c ON C.FanID = PT.FanID AND pt.PartnerID=c.PartnerID
	INNER JOIN MI.WorkingCumlDates CD 
			on CD.PartnerID = PT.PartnerID AND CD.ClientServicesRef = c.ClientServicesRef AND C.CumulativeTypeID = CD.Cumlitivetype and CD.Dateid = c.DateID
	INNER JOIN MI.WorkingofferDates WO 
			ON WO.Partnerid = pt.PartnerID AND WO.ClientServicesref = c.ClientServicesRef AND c.dateid=wo.Dateid
	LEFT OUTER JOIN MI.OutletAttribute OA 
			on OA.OutletID = PT.OutletID AND PT.AddedDate BETWEEN OA.StartDate AND OA.EndDate
	LEFT JOIN MI.RetailerMetricPaymentypes RMP 
			on PT.PaymentMethodID = RMP.SourcePaymentID AND C.ProgramID = RMP.ProgramID 
	WHERE  pt.[EligibleForCashBack] = 1 AND
			PT.TransactionAmount > 0 AND 
			C.DateID = @DateID AND
			PT.TransactionDate BETWEEN Wo.StartDate AND WO.EndDate
			AND pt.addeddate BETWEEN CD.StartDate AND @MonthEndDate 
			AND c.PartnerID=@partnerid

END
