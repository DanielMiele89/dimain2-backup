
-- =============================================
-- Author:		JEA
-- Create date: 31/03/2015
-- Description:	<loads MI.Staging_Customer_Temp>
-- =============================================
CREATE PROCEDURE [MI].[MRR_Staging_Customers_NonCoreMonth_Fetch_Part1] 
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

	SELECT DISTINCT c.FanID
		, 1 AS ProgramID
		, c.PartnerID
		, CAST(c.ClientServicesRef AS NVARCHAR(30)) AS ClientServicesRef
		, 0 AS CumulativeTypeID
		, 1 AS PeriodTypeID
		, @DateID AS DateID
		, cap.StartDate
		, COALESCE(NULLIF(cap.EndDate,@MaxEndDate), @EndDate) AS EndDate
	FROM Stratification.BaseOfferMembers_NonCore_Compressed c WITH (NOLOCK)
	INNER JOIN (SELECT PartnerID, ClientServicesref 
					FROM MI.WorkingCumlDates 
					WHERE Cumlitivetype = 2 AND ClientServicesref != '0'
					AND (@PartnerID IS NULL OR Partnerid = @PartnerID)) wcd ON c.PartnerID = wcd.Partnerid AND C.ClientServicesRef = wcd.ClientServicesref
	INNER JOIN MI.CAPCustomers cap WITH (NOLOCK) ON c.FanID = cap.FanID
	WHERE @DateID BETWEEN c.MinMonthID AND C.MaxMonthID

END