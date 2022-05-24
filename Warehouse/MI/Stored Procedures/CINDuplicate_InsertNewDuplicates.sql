-- =============================================
-- Author:		JEA
-- Create date: 20/08/2015
-- Description:	Captures duplicate customer sourceUIDs
-- =============================================
CREATE PROCEDURE MI.CINDuplicate_InsertNewDuplicates

AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO MI.CINDuplicate(FanID, CIN)
	SELECT c.FanID, c.SourceUID
	FROM Relational.Customer c
	INNER JOIN (

		SELECT sourceuid, MAX(ActivatedDate) AS ActivatedDate, count(1) as freq
		FROM relational.customer c
		LEFT OUTER JOIN mi.cinduplicate d on c.sourceuid = d.cin
		WHERE d.cin is null
		GROUP BY sourceuid
		HAVING COUNT(1) > 1

	) d ON c.SourceUID = d.SourceUID AND c.ActivatedDate = d.ActivatedDate

END