
-- =============================================
-- Author:		JEA
-- Create date: 31/03/2015
-- Description:	<loads MI.Staging_Customer_Temp>
-- =============================================
CREATE PROCEDURE [MI].[MRR_Customers_NonCoreMonth_SingleRetailer_Fetch] 
	(
		@DateID INT
		, @PartnerID INT = NULL
	)
AS
BEGIN

	SET NOCOUNT ON;

    Declare --@DateID as int, 
	@EndDate as Date,-- @partnerID as int,
	@StartDate as Date,
	@CumulativetypeID as int=0,
	@StartDateID int,
	@EndDateID int
	, @EndDatePlusOne DATE
	, @MaxEndDate DATE

	SET @MaxEndDate = DATEADD(YEAR, 1, GETDATE())

	set @StartDate = (select MIN(StartDate) from Relational.SchemeUpliftTrans_Month where id=@DateID)
	Set @EndDate = (select MAX(EndDate) from Relational.SchemeUpliftTrans_Month where id=@DateID)

	SET @EndDatePlusOne = DATEADD(DAY, 1, @EndDate)

	set @StartDateID = (select MIN(ID) from Relational.SchemeUpliftTrans_Month where id= @DateID)
	Set @EndDateID = (select MAX(ID) from Relational.SchemeUpliftTrans_Month where id= @DateID)

	SELECT c.FanID
		, 1 AS ProgramID
		, c.PartnerID
		, CAST(c.ClientServicesRef AS NVARCHAR(30)) AS ClientServicesRef
		, 0 AS CumulativeTypeID
		, 1 AS PeriodTypeID
		, @DateID AS DateID
		, cap.StartDate
		, COALESCE(NULLIF(cap.EndDate,@MaxEndDate), @EndDate) AS EndDate
		,CustomerAttributeID_0=CASE WHEN ecr.CustType='E' THEN 3 WHEN ecr.CustType='L' THEN 2 ELSE 1 END
		,CustomerAttributeID_0BP=CASE WHEN c.PartnerID=3960 /*BP*/ AND  ecr.CustType IN ('E' ,'L') THEN 4 END
		,CustomerAttributeID_1=CASE WHEN ecy.CustType='E' THEN 1003 WHEN ecy.CustType='L' THEN 1002 ELSE 1001 END
		,CustomerAttributeID_1BP=CASE WHEN c.PartnerID= 3960 /*BP*/ AND  ecy.CustType IN ('E' ,'L') THEN 1004 END
		,CustomerAttributeID_2=CASE WHEN ec.CustType='E' THEN 2003 WHEN ec.CustType='L' THEN 2002 ELSE 2001 END
		,CustomerAttributeID_2BP=CASE WHEN c.PartnerID= 3960 /*BP*/ AND  ec.CustType IN ('E' ,'L') THEN 2004 END
		,CustomerAttributeID_3=coh.FirstMonth+3000
	FROM MI.MRR_BaseOfferMembers_NonCore_Compressed c
	INNER JOIN (SELECT PartnerID, ClientServicesref 
					FROM MI.WorkingCumlDates 
					WHERE Cumlitivetype = 2 AND ClientServicesref != '0'
					AND (@PartnerID IS NULL OR Partnerid = @PartnerID)) wcd ON c.PartnerID = wcd.Partnerid AND C.ClientServicesRef = wcd.ClientServicesref
	--INNER JOIN (SELECT FanID
	--				, MIN(ActivationStart) as StartDate
	--				, MAX(ISNULL(ActivationEnd, @MaxEndDate)) AS EndDate
	--				FROM MI.CustomerActivationPeriod
	--				WHERE ActivationStart <= @EndDate
	--					AND (ActivationEnd IS  NULL OR ActivationEnd >= @StartDate)
	--					AND (AddedDate='2014-11-12' OR AddedDate <= @EndDatePlusOne)
	--				GROUP BY FanID) cap ON c.FanID = cap.FanID
	INNER JOIN MI.CAPCustomers cap ON c.FanID = cap.FanID
	LEFT OUTER JOIN Stratification.ExistingCustomers_Rolling_Compressed ecr
		ON ecr.FanID=c.FanID
		AND ecr.PartnerID=c.PartnerID 
		AND @DateID BETWEEN ecr.MinMonthID AND ecr.MaxMonthID
		AND ecr.ClientServicesref = c.ClientServicesref 
	LEFT JOIN Stratification.ExistingCustomers_YTD ecy
		ON ecy.FanID=c.FanID 
		AND ecy.PartnerID=c.PartnerID 
		AND @DateID BETWEEN ecy.MinMonthID AND ecy.MaxMonthID
		AND ecy.ClientServicesref = c.ClientServicesref 
	LEFT JOIN Stratification.ExistingCustomers ec
		ON ec.FanID=c.FanID 
		AND ec.PartnerID=c.PartnerID 
		AND @DateID BETWEEN ec.MinMonthID AND ec.MaxMonthID
		AND ec.ClientServicesref = c.ClientServicesref 
	LEFT JOIN Stratification.NewSpendersCohort coh
		ON coh.FanID=c.FanID 
		AND coh.PartnerID=c.PartnerID 
		AND coh.FirstMonth<=@DateID
		AND coh.ClientServicesref = c.ClientServicesref
	--WHERE @DateID BETWEEN c.MinMonthID AND C.MaxMonthID

END