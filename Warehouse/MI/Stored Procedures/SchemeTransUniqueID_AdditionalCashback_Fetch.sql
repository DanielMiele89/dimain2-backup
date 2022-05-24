-- =============================================
-- Author:		JEA
-- Create date: 09/07/2014
-- Description:	sources new transactions to be given a unique id for MI Portal purposes
-- Destination is Warehouse.Staging.SchemeTransUniqueID
-- Called by task [Load Staging SchemeTransUniqueID from AdditionalCashback] on REWARDBI
-- =============================================
CREATE PROCEDURE [MI].[SchemeTransUniqueID_AdditionalCashback_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT DISTINCT CAST(NULL AS INT) AS MatchID, a.FileID, a.RowNum
	FROM Relational.AdditionalCashbackAward a WITH (NOLOCK)
	LEFT OUTER JOIN MI.SchemeTransUniqueID s WITH (NOLOCK) ON a.FileID = s.FileID and a.RowNum = s.RowNum
	WHERE S.FileID IS NULL and a.MatchID IS NULL

END