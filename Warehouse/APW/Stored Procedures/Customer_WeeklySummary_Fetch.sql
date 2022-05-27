-- =============================================
-- Author:		JEA
-- Create date: 08/06/2018
-- Description:	Retrieves customers for AllPublisherWarehouse
-- =============================================
create PROCEDURE [APW].[Customer_WeeklySummary_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.CompositeID
		, CAST(132 AS INT) AS PublisherID
		, s.ActivatedDate AS ActivationDate
		, COALESCE(s.OptedOutDate, s.DeactivatedDate) AS DeactivationDate
	FROM Relational.Customer c WITH (NOLOCK)
	INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID

END
