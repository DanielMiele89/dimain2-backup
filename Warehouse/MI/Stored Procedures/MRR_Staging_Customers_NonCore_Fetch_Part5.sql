
-- =============================================
-- Author:		JEA
-- Create date: 31/03/2015
-- Description:	<loads MI.Staging_Customer_Temp>
-- =============================================
CREATE PROCEDURE [MI].[MRR_Staging_Customers_NonCore_Fetch_Part5] 
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
		, c.CustType_ECY
		, c.CustType_EC
		, coh.FirstMonth
	FROM MI.MRR_Staging_NonCoreCustomers_Stage4 c WITH (NOLOCK)
	LEFT JOIN Stratification.NewSpendersCohort coh WITH (NOLOCK)
		ON coh.FanID=c.FanID 
		AND coh.PartnerID=c.PartnerID 
		AND coh.FirstMonth<=@DateID
		AND coh.ClientServicesref = c.ClientServicesref

END