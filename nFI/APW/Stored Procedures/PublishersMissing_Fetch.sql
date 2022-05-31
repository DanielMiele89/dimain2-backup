-- =============================================
-- Author:		JEA
-- Create date: 12/10/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.PublishersMissing_Fetch

AS
BEGIN

	SET NOCOUNT ON;

	SELECT CAST (ClubID AS INT) AS PublisherID
		, ClubName AS PublisherName
	FROM Relational.Club

END
