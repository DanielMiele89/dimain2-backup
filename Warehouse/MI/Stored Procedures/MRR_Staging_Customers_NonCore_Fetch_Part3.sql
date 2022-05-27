
-- =============================================
-- Author:		JEA
-- Create date: 31/03/2015
-- Description:	<loads MI.Staging_Customer_Temp>
-- =============================================
CREATE PROCEDURE [MI].[MRR_Staging_Customers_NonCore_Fetch_Part3] 
	(
		@DateID INT
		, @PartnerID INT = NULL
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.FanID
		, c.ProgramID
		, c.PartnerID
		, c.ClientServicesRef
		, c.CumulativeTypeID
		, c.PeriodTypeID
		, c.DateID
		, c.StartDate
		, c.EndDate
		, c.CustType_ECR
		, ecy.CustType AS CustType_ECY
	FROM MI.MRR_Staging_NonCoreCustomers_Stage2 c WITH (NOLOCK)
	LEFT JOIN Stratification.ExistingCustomers_YTD ecy WITH (NOLOCK)
		ON ecy.FanID=c.FanID 
		AND ecy.PartnerID=c.PartnerID 
		AND @DateID BETWEEN ecy.MinMonthID AND ecy.MaxMonthID
		AND ecy.ClientServicesref = c.ClientServicesref 

END
