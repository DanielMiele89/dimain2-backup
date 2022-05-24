
-- =============================================
-- Author:		JEA
-- Create date: 26/05/2015
-- Description:	
-- =============================================
CREATE PROCEDURE [RewardBI].[RBSMIPortal_CustomerDDNominee_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @NULLDATE DATE

	SET @NULLDATE = DATEADD(YEAR, 10, GETDATE())

    SELECT d.ID
		, d.FanID
		, CAST(CASE WHEN d.Nominee = 1 THEN 'Nominee' ELSE 'Not Nominee' END AS VARCHAR(50)) AS NomineeStatus
		, d.Nominee AS IsNominee
		, d.StartDate
		, ISNULL(d.EndDate, @NULLDATE) AS EndDate
	FROM Relational.Customer_Loyalty_DD_Nominee d
	INNER JOIN Relational.Customer cu ON d.FanID = cu.FanID

END