-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.Customer_WeeklySummary_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT CompositeID
		, ClubID AS PublisherID
		, CAST(RegistrationDate AS DATE) AS ActivatedDate
	FROM Relational.Customer

END
