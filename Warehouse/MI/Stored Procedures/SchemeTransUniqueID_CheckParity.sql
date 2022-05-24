-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[SchemeTransUniqueID_CheckParity] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @CashACAAddedDate DATE, @MissingCount INT

	SELECT @CashACAAddedDate = MAX(AddedDate)
	FROM RBSMIPortal.SchemeCashback_ACA_AddedDateLoaded

	TRUNCATE TABLE RBSMIPortal.AwardsMissing

	INSERT INTO RBSMIPortal.AwardsMissing(MatchID, FileID, RowNum)
	SELECT a.MatchID, a.FileID, a.RowNum
	FROM Relational.AdditionalCashbackAward a
	WHERE NOT EXISTS (SELECT FileID, RowNum 
					FROM MI.SchemeTransUniqueID 
					WHERE FileID = a.FileID and RowNum = a.RowNum)
	AND a.TranDate >= '2018-04-01'
	AND a.AddedDate <= @CashACAAddedDate

	SELECT @MissingCount = COUNT(*)
	FROM RBSMIPortal.AwardsMissing

	IF @MissingCount > 0
	BEGIN
		--EXEC MI.SchemeTransUniqueID_Indexes_Disable

		INSERT INTO MI.SchemeTransUniqueID(MatchID, FileID, RowNum)
		SELECT MatchID, FileID, RowNum
		FROM RBSMIPortal.AwardsMissing

		--EXEC MI.SchemeTransUniqueID_Indexes_Rebuild
	END
	
END