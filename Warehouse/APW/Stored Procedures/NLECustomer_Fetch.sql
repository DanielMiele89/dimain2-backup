-- =============================================
-- Author:		JEA
-- Create date: 02/08/2016
-- Description:	retrieves NLEFans for loading into NLECustomers
-- =============================================
CREATE PROCEDURE APW.NLECustomer_Fetch 
(
	@RetailerID INT
)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT FanID
		, CINID
		, @RetailerID AS RetailerID
		, NLE
	FROM APW.NLEFans

END
