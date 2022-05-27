-- =============================================
-- Author:		JEA
-- Create date: 01/10/2015
-- Description:	Returns anomalous cases in the slowly changing dimensions
-- =============================================
CREATE PROCEDURE [RewardBI].[RBSMIPortal_CustomerSCD_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @NullDate DATE = DATEADD(YEAR, 10, GETDATE())

    SELECT CAST('Relational.Customer_SchemeMembership' AS VARCHAR(100)) AS TableName, CAST('EndDate before StartDate' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.Customer_SchemeMembership A
	WHERE ISNULL(EndDate, @NullDate) < StartDate

	UNION ALL

	SELECT CAST('Relational.Customer_SchemeMembership' AS VARCHAR(100)) AS TableName, CAST('Overlap' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.Customer_SchemeMembership A
	INNER JOIN Relational.Customer_SchemeMembership B ON a.ID != b.ID 
					AND A.FanID = b.FanID
					AND A.StartDate < ISNULL(b.EndDate, @NullDate)
					AND ISNULL(A.EndDate, @NullDate)>= b.StartDate

	UNION ALL

	SELECT CAST('Relational.Customer_RBSGSegments' AS VARCHAR(100)) AS TableName, CAST('EndDate before StartDate' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.Customer_RBSGSegments A
	WHERE ISNULL(EndDate, @NullDate) < StartDate

	UNION ALL

	SELECT CAST('Relational.Customer_RBSGSegments' AS VARCHAR(100)) AS TableName, CAST('Overlap' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.Customer_RBSGSegments A
	INNER JOIN Relational.Customer_RBSGSegments B ON a.ID != b.ID 
					AND A.FanID = b.FanID
					AND A.StartDate < ISNULL(b.EndDate, @NullDate)
					AND ISNULL(A.EndDate, @NullDate)>= b.StartDate

	UNION ALL

	SELECT CAST('Relational.Customer_Loyalty_DD_Nominee' AS VARCHAR(100)) AS TableName, CAST('EndDate before StartDate' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.Customer_Loyalty_DD_Nominee A
	WHERE ISNULL(EndDate, @NullDate) < StartDate

	UNION ALL

	SELECT CAST('Relational.Customer_Loyalty_DD_Nominee' AS VARCHAR(100)) AS TableName, CAST('Overlap' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.Customer_Loyalty_DD_Nominee A
	INNER JOIN Relational.Customer_Loyalty_DD_Nominee B ON a.ID != b.ID 
					AND A.FanID = b.FanID
					AND A.StartDate < ISNULL(b.EndDate, @NullDate)
					AND ISNULL(A.EndDate, @NullDate)>= b.StartDate

	UNION ALL

	SELECT CAST('Relational.Customer_MarketableByEmailStatus_MI' AS VARCHAR(100)) AS TableName, CAST('EndDate before StartDate' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.Customer_MarketableByEmailStatus_MI A
	WHERE ISNULL(EndDate, @NullDate) < StartDate

	UNION ALL

	SELECT CAST('Relational.Customer_MarketableByEmailStatus_MI' AS VARCHAR(100)) AS TableName, CAST('Overlap' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.Customer_MarketableByEmailStatus_MI A
	INNER JOIN Relational.Customer_MarketableByEmailStatus_MI B ON a.ID != b.ID 
					AND A.FanID = b.FanID
					AND A.StartDate < ISNULL(b.EndDate, @NullDate)
					AND ISNULL(A.EndDate, @NullDate)>= b.StartDate

	UNION ALL

	SELECT CAST('Relational.Customer_Registered' AS VARCHAR(100)) AS TableName, CAST('EndDate before StartDate' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.Customer_Registered A
	WHERE ISNULL(EndDate, @NullDate) < StartDate

	UNION ALL

	SELECT CAST('Relational.Customer_Registered' AS VARCHAR(100)) AS TableName, CAST('Overlap' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.Customer_Registered A
	INNER JOIN Relational.Customer_Registered B ON a.ID != b.ID 
					AND A.FanID = b.FanID
					AND A.StartDate < ISNULL(b.EndDate, @NullDate)
					AND ISNULL(A.EndDate, @NullDate)>= b.StartDate

	UNION ALL

	SELECT CAST('Relational.MIDTrackingGAS' AS VARCHAR(100)) AS TableName, CAST('EndDate before StartDate' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.MIDTrackingGAS A
	WHERE ISNULL(EndDate, @NullDate) < StartDate

	UNION ALL

	SELECT CAST('Relational.MIDTrackingGAS' AS VARCHAR(100)) AS TableName, CAST('Overlap' AS VARCHAR(50)) AS IssueName, COUNT(*) AS Frequency
	FROM Relational.MIDTrackingGAS A
	INNER JOIN Relational.MIDTrackingGAS B ON A.ID != B.ID
					AND a.RetailOutletID = B.RetailOutletID
					AND A.PartnerID = B.PartnerID
					AND ISNULL(A.MID_Join, '') = ISNULL(B.MID_Join, '')
					AND A.StartDate < ISNULL(b.EndDate, @NullDate)
					AND ISNULL(A.EndDate, @NullDate)>= b.StartDate

END
