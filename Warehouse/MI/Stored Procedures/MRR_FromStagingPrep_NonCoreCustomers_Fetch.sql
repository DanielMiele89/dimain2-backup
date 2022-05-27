-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.MRR_FromStagingPrep_NonCoreCustomers_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT c.FanID
		, c.ProgramID
		, c.PartnerID
		, cast(c.ClientServicesRef as nvarchar(30)) AS ClientServicesRef
		, c.CumulativeTypeID
		, c.PeriodTypeID
		, c.DateID
		, c.StartDate
		, c.EndDate
		,CustomerAttributeID_0=CASE WHEN c.CustType_ECR='E' THEN 3 WHEN c.CustType_ECR='L' THEN 2 ELSE 1 END
		,CustomerAttributeID_0BP=CASE WHEN c.PartnerID=3960 /*BP*/ AND  c.CustType_ECR IN ('E' ,'L') THEN 4 END
		,CustomerAttributeID_1=CASE WHEN c.CustType_ECY='E' THEN 1003 WHEN c.CustType_ECY='L' THEN 1002 ELSE 1001 END
		,CustomerAttributeID_1BP=CASE WHEN c.PartnerID= 3960 /*BP*/ AND  c.CustType_ECY IN ('E' ,'L') THEN 1004 END
		,CustomerAttributeID_2=CASE WHEN c.CustType_EC='E' THEN 2003 WHEN c.CustType_EC='L' THEN 2002 ELSE 2001 END
		,CustomerAttributeID_2BP=CASE WHEN c.PartnerID= 3960 /*BP*/ AND  c.CustType_EC IN ('E' ,'L') THEN 2004 END
		,CustomerAttributeID_3=c.FirstMonth+3000
	FROM MI.StagingPrep_5 c

END
