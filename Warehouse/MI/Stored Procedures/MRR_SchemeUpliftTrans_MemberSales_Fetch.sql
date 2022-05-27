-- =============================================
-- Author:		JEA
-- Create date: 22/04/2015
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[MRR_SchemeUpliftTrans_MemberSales_Fetch] 
	(
		@DateID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @EndDate DATE

	SELECT @EndDate = EndDate FROM Relational.SchemeUpliftTrans_Month WHERE ID = @DateID

	SELECT pt.FileID
		, pt.RowNum 
		, pt.PartnerID
		, c.ClientServicesRef AS ClientServiceRef
		, RMP.PaymentID AS PaymentTypeID
		, CAST(CASE WHEN PT.isonline = 1 THEN 2 ELSE 1 END AS TINYINT) AS ChannelID
		, COALESCE(c.CustomerAttributeID_0,-1) AS CustomerAttributeID_0
		, COALESCE(c.CustomerAttributeID_0BP,-1) AS CustomerAttributeID_0BP
		, COALESCE(c.CustomerAttributeID_1,-1) AS CustomerAttributeID_1
		, COALESCE(c.CustomerAttributeID_1BP,-1) AS CustomerAttributeID_1BP
		, COALESCE(c.CustomerAttributeID_2,-1) AS CustomerAttributeID_2
		, COALESCE(c.CustomerAttributeID_2BP,-1) AS CustomerAttributeID_2BP
		, COALESCE(c.CustomerAttributeID_3,-1) AS CustomerAttributeID_3
		, OA.Mid_SplitID
		, c.CumulativeTypeID
		, 1 AS PeriodTypeID
		, C.DateID AS DateID 
		, pt.Amount AS MembersSales
		, PT.FanID
		, wo.StartDate as WOStartDate
		, wo.EndDate as WOEndDate
		, pt.TranDate
		, pt.AddedDate
		, CAST(CASE WHEN WO.id IS NULL THEN 0 ELSE 1 END AS BIT) AS InWorkingOfferRange
	FROM Relational.SchemeUpliftTrans PT
	INNER JOIN MI.Staging_Customer_TempCUMLandNonCore c 
			ON C.FanID = PT.FanID AND pt.PartnerID=c.PartnerID 
	INNER JOIN MI.WorkingCumlDates CD 
			on CD.PartnerID = PT.PartnerID and CD.ClientServicesRef = C.ClientServicesRef and C.CumulativeTypeID = CD.Cumlitivetype
	LEFT OUTER JOIN MI.WorkingofferDates WO 
			ON WO.Partnerid = pt.PartnerID and WO.ClientServicesref = c.ClientServicesRef AND pt.TranDate BETWEEN wo.StartDate AND wo.EndDate
	LEFT OUTER JOIN MI.OutletAttribute OA 
			on OA.OutletID = PT.OutletID AND PT.AddedDate BETWEEN OA.StartDate AND OA.EndDate
	LEFT OUTER JOIN MI.RetailerMetricPaymentypes RMP 
			on PT.PaymentTypeID = RMP.PaymentID AND C.ProgramID = RMP.ProgramID 
	WHERE  pt.IsRetailReport = 1 
			AND PT.Amount > 0
			AND C.DateID = @DateID 
			AND pt.addeddate BETWEEN CD.StartDate AND @EndDate

END
