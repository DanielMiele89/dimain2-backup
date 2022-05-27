-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Prototype].[CustomerActiveVSegment_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT c.FanID, cin.CINID, CAST(CAST(ISNULL(V.FanID,0) AS bit) AS tinyint) AS IsV
	FROM Relational.Customer c
	INNER JOIN Relational.CINList cin ON c.SourceUID = CIN.CIN
	LEFT OUTER JOIN MI.CINDuplicate d ON c.FanID = d.FanID
	LEFT OUTER JOIN (SELECT FanID 
						FROM Relational.Customer_RBSGSegments 
						WHERE CustomerSegment = 'V' AND EndDate IS NULL) V ON c.FanID = V.FanID
	WHERE d.FanID IS NULL
	AND c.CurrentlyActive = 1

END
