
-- *******************************************************************************
-- Author: JEA
-- Create date: 03/11/2016
-- Description: Retrieves non-RBS customer data from SLC_Report for APW direct load 
-- *******************************************************************************
CREATE PROCEDURE [APW].[DirectLoad_Customer_Fetch]
	--WITH EXECUTE AS 'ProcessOp'
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	
		ID AS FanID,
		f.ClubID AS PublisherID,
		CAST(CASE
			WHEN Sex = 1 THEN 'M'
			WHEN Sex = 2 THEN 'F'
			ELSE 'U'
		END AS CHAR(1)) AS Gender,
		(CASE WHEN DOB <> '1900-01-01 00:00:00.000' THEN DOB ELSE NULL END) AS DOB,
		RegistrationDate AS ActivationDate,
		CASE WHEN q.CompositeID IS NULL THEN 0 ELSE 1 END AS SubPublisherID
	FROM SLC_Report.dbo.Fan f
	INNER JOIN Relational.Club cl
		ON f.ClubID = cl.ClubID
	LEFT OUTER JOIN (SELECT DISTINCT CompositeID FROM Warehouse.InsightArchive.QuidcoR4GCustomers) q 
		ON f.CompositeID = q.CompositeID;
	
END