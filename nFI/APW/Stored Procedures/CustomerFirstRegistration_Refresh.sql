-- =============================================
-- Author:		JEA
-- Create date: 08/02/2015
-- Description:	Fetches first registration date for a customer
-- =============================================
CREATE PROCEDURE APW.CustomerFirstRegistration_Refresh 
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	INSERT INTO APW.CustomerFirstRegistration(FanID, FirstRegistrationDate)
    SELECT c.FanID, CAST(RegistrationDate AS DATE) AS FirstRegistrationDate
	FROM Relational.Customer c
	LEFT OUTER JOIN APW.CustomerFirstRegistration f ON c.FanID = f.FanID
	WHERE f.FanID IS NULL

END
