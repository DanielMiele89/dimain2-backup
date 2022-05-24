
-- =============================================
-- Author:		JEA
-- Create date: 31/03/2015
-- Description:	<loads MI.Staging_Customer_Temp>
-- =============================================
CREATE PROCEDURE [MI].[MRR_Staging_Customers_NonCoreMonth_Fetch_TEST1] 
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
		, CAST(c.ClientServicesRef AS VARCHAR(10)) AS ClientServicesRef
		, 0 AS CumulativeTypeID
		, 1 AS PeriodTypeID
		, @DateID AS DateID
		, cap.StartDate
		, COALESCE(NULLIF(cap.EndDate,@MaxEndDate), @EndDate) AS EndDate
		--, ecr.CustType AS CustType_ECR
		--, ecy.CustType AS CustType_ECY
		--, ec.CustType AS CustType_EC
		--, coh.FirstMonth
	FROM Stratification.BaseOfferMembers_NonCore_Compressed c WITH (NOLOCK)
	INNER JOIN (SELECT PartnerID, ClientServicesref 
					FROM MI.WorkingCumlDates 
					WHERE Cumlitivetype = 2 AND ClientServicesref != '0'
					AND (@PartnerID IS NULL OR Partnerid = @PartnerID)) wcd ON c.PartnerID = wcd.Partnerid AND C.ClientServicesRef = wcd.ClientServicesref
	INNER JOIN MI.CAPCustomers cap WITH (NOLOCK) ON c.FanID = cap.FanID
	--LEFT OUTER JOIN Stratification.ExistingCustomers_Rolling_Compressed ecr WITH (NOLOCK)
	--	ON ecr.FanID=c.FanID
	--	AND ecr.PartnerID=c.PartnerID 
	--	AND @DateID BETWEEN ecr.MinMonthID AND ecr.MaxMonthID
	--	AND ecr.ClientServicesref = c.ClientServicesref 
	--LEFT JOIN Stratification.ExistingCustomers_YTD ecy WITH (NOLOCK)
	--	ON ecy.FanID=c.FanID 
	--	AND ecy.PartnerID=c.PartnerID 
	--	AND @DateID BETWEEN ecy.MinMonthID AND ecy.MaxMonthID
	--	AND ecy.ClientServicesref = c.ClientServicesref 
	--LEFT JOIN Stratification.ExistingCustomers ec WITH (NOLOCK)
	--	ON ec.FanID=c.FanID 
	--	AND ec.PartnerID=c.PartnerID 
	--	AND @DateID BETWEEN ec.MinMonthID AND ec.MaxMonthID
	--	AND ec.ClientServicesref = c.ClientServicesref 
	--LEFT JOIN Stratification.NewSpendersCohort coh WITH (NOLOCK)
	--	ON coh.FanID=c.FanID 
	--	AND coh.PartnerID=c.PartnerID 
	--	AND coh.FirstMonth<=@DateID
	--	AND coh.ClientServicesref = c.ClientServicesref
	WHERE @DateID BETWEEN c.MinMonthID AND C.MaxMonthID

END