
-- =============================================
-- Author:		JEA
-- Create date: 23/07/2015
-- Description:	
-- =============================================
CREATE PROCEDURE [RewardBI].[RBSMIPortal_CustomerSegment_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @NULLDATE DATE

	SET @NULLDATE = DATEADD(YEAR, 10, GETDATE())

    SELECT d.ID
		, d.FanID
		, d.CustomerSegment
		, CAST(CASE WHEN RTRIM(LTRIM(d.CustomerSegment)) = 'V' THEN 1 ELSE 0 END AS bit) AS IsVSegment
		, d.StartDate
		, ISNULL(d.EndDate, @NULLDATE) AS EndDate
	FROM Relational.Customer_RBSGSegments d
	INNER JOIN Relational.Customer cu ON d.FanID = cu.FanID

END

