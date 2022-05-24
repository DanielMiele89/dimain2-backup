-- =============================================
-- Author:		JEA
-- Create date: 19/04/2016
-- Description:	Retrieves customers for AllPublisherWarehouse
-- =============================================
CREATE PROCEDURE APW.Customer_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.FanID
		, CAST(132 AS INT) AS PublisherID
		, c.DOB
		, c.Gender
		, s.ActivatedDate AS ActivationDate
		, COALESCE(s.OptedOutDate, s.DeactivatedDate) AS DeactivationDate
	FROM Relational.Customer c WITH (NOLOCK)
	INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID

END
