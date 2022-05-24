-- =============================================
-- Author:		JEA
-- Create date: 08/07/2014
-- Description:	sources new transactions to be given a unique id for MI Portal purposes
-- =============================================
CREATE PROCEDURE [MI].[PartnerTrans_Additional_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT MatchID, FileID, RowNum
	FROM
	(
		SELECT pt.MatchID, a.FileID, a.RowNum
		FROM Relational.PartnerTrans pt
		LEFT OUTER JOIN Relational.AdditionalCashbackAward a ON pt.MatchID = a.MatchID

		UNION

		SELECT MatchID, FileID, RowNum
		FROM Relational.AdditionalCashbackAward
		WHERE MatchID IS NULL
	) p
	
	EXCEPT

	SELECT MatchID, FileID, RowNum
	FROM MI.SchemeTransUniqueID

END