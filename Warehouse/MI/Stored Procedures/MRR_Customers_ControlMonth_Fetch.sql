

-- =============================================
-- Author:		JEA
-- Create date: 31/03/2015
-- Description:	<loads MI.Staging_Control_Temp>
-- =============================================
CREATE PROCEDURE [MI].[MRR_Customers_ControlMonth_Fetch]
	(
		@DateID INT
		, @PartnerID INT = NULL
	)
AS
BEGIN 

	SET NOCOUNT ON;
    
	SELECT c.FanID
		, 1 AS ProgramID
		, c.PartnerID
		, c.ClientServicesRef
		, mt.CumulativeTypeID
		, 1 AS PeriodTypeID
		, @DateID AS DateID
		, CASE WHEN ecy.CustType='E' THEN 1003 WHEN ecy.CustType='L' THEN 1002 WHEN mt.CumulativeTypeID IN (0,1) THEN 1001 END AS CustomerAttributeID_1
		, CASE WHEN c.PartnerID=3960 /*BP*/ AND  ecy.CustType IN ('E' ,'L') THEN 1004 END AS CustomerAttributeID_1BP
		, CASE WHEN ec.CustType='E' THEN 2003 WHEN ec.CustType='L' THEN 2002 WHEN mt.CumulativeTypeID IN (0,2) THEN 2001 END AS CustomerAttributeID_2
		, CASE WHEN c.PartnerID=3960 /*BP*/ AND  ec.CustType IN ('E' ,'L') THEN 2004 END AS CustomerAttributeID_2BP
	FROM (
			SELECT c.FanID, c.PartnerID, c.ClientServicesRef
			FROM Relational.Control_Stratified_Compressed c
			INNER JOIN (SELECT PartnerID
							, ClientServicesref 
						FROM MI.WorkingCumlDates 
						WHERE Cumlitivetype = 2
						) wcd
							ON c.PartnerID = wcd.Partnerid
							AND c.ClientServicesRef = wcd.ClientServicesref
			WHERE @DateID BETWEEN c.MinMonthID AND C.MaxMonthID

			UNION ALL

			SELECT c.FanID, wcd.Partnerid, wcd.ClientServicesRef
			FROM Relational.Control_Stratified_Compressed c
			CROSS JOIN (SELECT w.PartnerID
								, w.ClientServicesref 
						FROM MI.WorkingCumlDates w
						LEFT OUTER JOIN Relational.Control_Stratified_Compressed c
							ON w.Partnerid = c.PartnerID
							AND w.ClientServicesref = c.ClientServicesRef
						WHERE w.Cumlitivetype = 2 
							AND c.PartnerID IS NULL
						) wcd
			WHERE @DateID BETWEEN c.MinMonthID AND C.MaxMonthID
				AND c.PartnerID = 0
				AND c.ClientServicesRef = '0'
			) c
	CROSS JOIN Warehouse.MI.RetailerMetricCumulativeType mt
	LEFT OUTER JOIN Stratification.ExistingCustomers_YTD ecy
		ON ecy.FanID=c.FanID 
		AND ecy.PartnerID=c.PartnerID 
		AND @DateID BETWEEN ecy.MinMonthID AND ecy.MaxMonthID
		AND ecy.ClientServicesref = c.ClientServicesref 
		AND mt.CumulativeTypeID IN (0,1)
	LEFT OUTER JOIN Stratification.ExistingCustomers ec
		ON ec.FanID=c.FanID 
		AND ec.PartnerID=c.PartnerID 
		AND @DateID BETWEEN ec.MinMonthID AND ec.MaxMonthID
		AND ec.ClientServicesref = c.ClientServicesref 
		AND mt.CumulativeTypeID IN (0,2)
	WHERE (@PartnerID IS NULL OR c.PartnerID = @PartnerID)

END



