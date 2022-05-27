
-- =============================================
-- Author:		JEA
-- Create date: 31/03/2015
-- Description:	<loads MI.Staging_Customer_Temp>
-- =============================================
CREATE PROCEDURE [MI].[MRR_Staging_Customers_NonCore_Fetch_Part2] 
	(
		@DateID INT
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
		, ecr.CustType AS CustType_ECR
	FROM MI.MRR_Staging_NonCoreCustomers_Stage1 c WITH (NOLOCK)
	LEFT OUTER JOIN Stratification.ExistingCustomers_Rolling_Compressed ecr WITH (NOLOCK)
		ON ecr.FanID=c.FanID
		AND ecr.PartnerID=c.PartnerID 
		AND @DateID BETWEEN ecr.MinMonthID AND ecr.MaxMonthID
		AND ecr.ClientServicesref = c.ClientServicesref 

END
