-- =============================================
-- Author:		JEA
-- Create date: 25/03/2015
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [InsightArchive].[TestCustomers_CoreCuml_Fetch] 
	(
		@DateID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @EndDate DATE, @EndDatePlusOne DATE, @MaxEndDate DATE

	SET @MaxEndDate = DATEADD(YEAR, 1, GETDATE())

	SET @EndDate = (SELECT MAX(EndDate) FROM Relational.SchemeUpliftTrans_Month WHERE id=@DateID)

	SET @EndDatePlusOne = DATEADD(DAY, 1, @EndDate)

	SELECT c.FanID
		, 1 AS ProgramID
		, wcd.PartnerID
		, CAST(wcd.ClientServicesRef AS VARCHAR(30)) AS ClientServicesRef
		, wcd.Cumlitivetype AS CumulativeTypeID
		, 1 AS PeriodTypeID
		, @DateID AS DateID
		, c.StartDate
		, COALESCE(NULLIF(c.EndDate, @MaxEndDate), @EndDate) AS EndDate
		,CustomerAttributeID_0=CASE WHEN ecr.CustType='E' THEN 3 WHEN ecr.CustType='L' THEN 2 ELSE 1 END
		,CustomerAttributeID_0BP=CASE WHEN wcd.PartnerID=3960 /*BP*/ AND  ecr.CustType IN ('E' ,'L') THEN 4 END
		,CustomerAttributeID_1=CASE WHEN ecy.CustType='E' THEN 1003 WHEN ecy.CustType='L' THEN 1002 ELSE 1001 END
		,CustomerAttributeID_1BP=CASE WHEN wcd.PartnerID= 3960 /*BP*/ AND  ecy.CustType IN ('E' ,'L') THEN 1004 END
		,CustomerAttributeID_2=CASE WHEN ec.CustType='E' THEN 2003 WHEN ec.CustType='L' THEN 2002 ELSE 2001 END
		,CustomerAttributeID_2BP=CASE WHEN wcd.PartnerID= 3960 /*BP*/ AND  ec.CustType IN ('E' ,'L') THEN 2004 END
		,CustomerAttributeID_3=coh.FirstMonth+3000
	FROM (
			SELECT FanID
					, MIN(ActivationStart) as StartDate
					, MAX(ISNULL(ActivationEnd, @MaxEndDate)) AS EndDate
					FROM MI.CustomerActivationPeriod
					WHERE ActivationStart <= @EndDate
						AND (AddedDate='2014-11-12' OR AddedDate <= @EndDatePlusOne)
					GROUP BY FanID
		) c
	INNER JOIN Relational.Customer z ON c.FanID = z.FanID
	INNER JOIN (SELECT Partnerid, Cumlitivetype, ClientServicesref, StartDate, Dateid, StartMonthID 
				FROM mi.WorkingCumlDates
				WHERE ClientServicesref = '0') wcd ON c.EndDate >= wcd.StartDate
	LEFT OUTER JOIN Stratification.ExistingCustomers_Rolling_Compressed ecr
		ON ecr.FanID=c.FanID
		AND ecr.PartnerID=wcd.PartnerID 
		AND @DateID BETWEEN ecr.MinMonthID AND ecr.MaxMonthID
		AND ecr.ClientServicesref = wcd.ClientServicesref 
	LEFT JOIN Stratification.ExistingCustomers_YTD ecy
		ON ecy.FanID=c.FanID 
		AND ecy.PartnerID=wcd.PartnerID 
		AND @DateID BETWEEN ecy.MinMonthID AND ecy.MaxMonthID
		AND ecy.ClientServicesref = wcd.ClientServicesref 
	LEFT JOIN Stratification.ExistingCustomers ec
		ON ec.FanID=c.FanID 
		AND ec.PartnerID=wcd.PartnerID 
		AND @DateID BETWEEN ec.MinMonthID AND ec.MaxMonthID
		AND ec.ClientServicesref = wcd.ClientServicesref 
	LEFT JOIN Stratification.NewSpendersCohort coh
		ON coh.FanID=c.FanID 
		AND coh.PartnerID=wcd.PartnerID 
		AND coh.FirstMonth<=@DateID
		AND coh.ClientServicesref = wcd.ClientServicesref

END
