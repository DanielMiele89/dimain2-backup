-- =============================================
-- Author:		JEA
-- Create date: 31/03/2015
-- Description:	<Loads MI.Staging_Customer_TempCUMLandNonCore>
-- =============================================
CREATE PROCEDURE [MI].[MRR_Staging_Customers_NonCoreCuml_Fetch_Part1]
	(
		@DateID INT
		, @PartnerID INT = NULL
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @EndDate DATE, @EndDatePlusOne DATE, @MaxEndDate DATE

	SET @MaxEndDate = DATEADD(YEAR, 1, GETDATE())

	SET @EndDate = (SELECT MAX(EndDate) FROM Relational.SchemeUpliftTrans_Month WHERE id=@DateID)

	SET @EndDatePlusOne = DATEADD(DAY, 1, @EndDate)

	SELECT DISTINCT c.FanID
		, 1 AS ProgramID
		, wcd.PartnerID
		, CAST(wcd.ClientServicesRef AS nvarchar(30)) as ClientServicesRef
		, wcd.Cumlitivetype AS CumulativeTypeID
		, 1 AS PeriodTypeID
		, @DateID AS DateID
		, c.StartDate
		, COALESCE(NULLIF(c.EndDate, @MaxEndDate), @EndDate) AS EndDate
	FROM 
		MI.CAPCustomers c
	INNER JOIN Stratification.BaseOfferMembers_NonCore_Compressed B ON c.FanID = b.FanID
	INNER JOIN (SELECT Partnerid, Cumlitivetype, ClientServicesref, StartDate, Dateid, StartMonthID 
				FROM mi.WorkingCumlDates
				WHERE ClientServicesref != '0'
				AND (@PartnerID IS NULL OR Partnerid = @PartnerID)) wcd ON c.EndDate >= wcd.StartDate
													AND wcd.Partnerid = b.PartnerID and wcd.ClientServicesref = b.ClientServicesRef
													AND b.MaxMonthID >= wcd.StartMonthID
	WHERE b.MinMonthID <= @DateID

END