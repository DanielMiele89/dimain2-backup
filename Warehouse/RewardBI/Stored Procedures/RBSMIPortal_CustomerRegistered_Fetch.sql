
-- =============================================
-- Author:		JEA
-- Create date: 26/05/2015
-- Description:	
-- =============================================
CREATE PROCEDURE [RewardBI].[RBSMIPortal_CustomerRegistered_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @NULLDATE DATE

	SET @NULLDATE = DATEADD(YEAR, 10, GETDATE())

    SELECT i.ID
		, i.FanID
		, i.Registered
		, i.StartDate
		, ISNULL(i.EndDate, @NULLDATE) AS EndDate
	FROM Relational.Customer_Registered i
	INNER JOIN Relational.Customer cu ON i.FanID = cu.FanID

END

