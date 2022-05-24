-- =============================================
-- Author:		JEA
-- Create date: 09/07/2014
-- Description:	sources new transactions to be given a unique id for MI Portal purposes
-- Destination is Warehouse.Staging.SchemeTransUniqueID
-- Called by task [Load Staging SchemeTransUniqueID from PartnerTrans] on REWARDBI
-- =============================================
CREATE PROCEDURE [MI].[SchemeTransUniqueID_PartnerTrans_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT pt.MatchID, a.FileID, a.RowNum
	FROM Relational.PartnerTrans pt WITH (NOLOCK)
	LEFT OUTER JOIN (SELECT DISTINCT MatchID, FileID, RowNum
		FROM Relational.AdditionalCashbackAward a WITH (NOLOCK)
		WHERE MatchID IS NOT NULL) a ON pt.MatchID = a.MatchID
	LEFT OUTER JOIN MI.SchemeTransUniqueID s WITH (NOLOCK) ON pt.MatchID = s.MatchID
	WHERE S.MatchID IS NULL

END
