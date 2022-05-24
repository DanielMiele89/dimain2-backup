
-- =============================================
-- Author:		JEA
-- Create date: 26/05/2015
-- Description:	
-- =============================================
CREATE PROCEDURE [RewardBI].[RBSMIPortal_CustomerSchemeMembership_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @NULLDATE DATE

	SET @NULLDATE = DATEADD(YEAR, 10, GETDATE())

    SELECT i.ID
		, i.FanID
		, i.SchemeMembershipTypeID
		, i.StartDate
		, ISNULL(i.EndDate, @NULLDATE) AS EndDate
	FROM Relational.Customer_SchemeMembership i
	INNER JOIN MI.CustomerActiveStatus cu ON i.FanID = cu.FanID

END