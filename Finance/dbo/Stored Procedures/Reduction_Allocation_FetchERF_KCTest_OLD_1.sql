
create PROCEDURE [dbo].[Reduction_Allocation_FetchERF_KCTest_OLD] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT ID AS ReductionID
		, FanID
		, ReductionDate
		, ReductionValue
		, BankID
		, IsRedemption
	FROM RBSMIPortal.Reduction_Balance_ERF_KCTest
	WHERE IsRedemption = 1 OR ReductionValue > 0
	ORDER BY FanID, ReductionDate

END

