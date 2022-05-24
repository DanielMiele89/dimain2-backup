-- =============================================
-- Author:		<Hayden>

-- =============================================
CREATE PROCEDURE MI.HaydenTestPartnerList

AS
BEGIN
	SET NOCOUNT ON;

	SELECT PartnerID
		,PartnerName
	FROM Relational.[Partner]
	ORDER BY PartnerName
	

END
