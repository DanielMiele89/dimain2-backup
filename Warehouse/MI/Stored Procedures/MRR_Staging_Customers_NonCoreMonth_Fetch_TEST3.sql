
-- =============================================
-- Author:		JEA
-- Create date: 31/03/2015
-- Description:	<loads MI.Staging_Customer_Temp>
-- =============================================
CREATE PROCEDURE [MI].[MRR_Staging_Customers_NonCoreMonth_Fetch_TEST3] 
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
		--, ec.CustType AS CustType_EC
		--, coh.FirstMonth
	FROM MI.StagingPrep_2 c WITH (NOLOCK)
	LEFT JOIN Stratification.ExistingCustomers_YTD ecy WITH (NOLOCK)
		ON ecy.FanID=c.FanID 
		AND ecy.PartnerID=c.PartnerID 
		AND @DateID BETWEEN ecy.MinMonthID AND ecy.MaxMonthID
		AND ecy.ClientServicesref = c.ClientServicesref 
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

END