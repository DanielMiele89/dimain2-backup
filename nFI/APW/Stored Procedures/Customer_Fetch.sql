-- =============================================
-- Author:		JEA
-- Create date: 08/02/2016
-- Description:	Retrieves customers for All Publisher Warehouse
-- =============================================
CREATE PROCEDURE [APW].[Customer_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT c.FanID
		, c.ClubID AS PublisherID
		, c.DOB
		, c.Gender
		, COALESCE(f.FirstRegistrationDate, CAST(C.RegistrationDate AS DATE)) AS ActivationDate
	FROM Relational.Customer c
	LEFT OUTER JOIN APW.CustomerFirstRegistration f ON c.FanID = f.FanID

END
