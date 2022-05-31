-- =============================================
-- Author:		JEA
-- Create date: 08/02/2015
-- Description:	Retrieves payment cards for all publisher warehouse
-- =============================================
CREATE PROCEDURE APW.PaymentCard_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID
		, FanID
		, ClubID AS PublisherID
		, StartDate
		, EndDate
	FROM Relational.Customer_PaymentCard

END
