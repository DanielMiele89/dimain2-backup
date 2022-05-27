-- =============================================
-- Author:		JEA
-- Create date: 08/07/2013
-- Description:	Refreshes the MI.SchemeFanInfo staging table
-- =============================================
CREATE PROCEDURE [MI].[SchemeFanInfo_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    ALTER INDEX IX_MI_SchemeFanInfo_CIN ON MI.SchemeFanInfo DISABLE
	ALTER INDEX IX_MI_SchemeFanInfo_CINID ON MI.SchemeFanInfo DISABLE
	
	TRUNCATE TABLE MI.SchemeFanInfo
		
	INSERT INTO MI.SchemeFanInfo(FanID, GenderID, DOB, ActivationDate, CIN
		, ContactByEmail, ContactByPhone, ContactBySMS, ContactByPost, DeactivatedDate)
	SELECT f.ID, f.Sex AS GenderID, case when f.DOB = '1900-01-01' then CAST(
      CAST(n.YearOfBirth AS VARCHAR(4)) +
      RIGHT('0' + CAST(n.MonthOfBirth AS VARCHAR(2)), 2) +
      '01' AS DATE) else f.DOB end as DOB
      , a.ActivatedDate AS ActivationDate
      , F.SourceUID
	  , CAST(CASE WHEN F.Unsubscribed = 1 THEN 0 ELSE 1 END AS BIT) As ContactByEmail
	  , F.ContactByPhone AS ContactByPhone
	  , F.ContactBySMS AS ContactBySMS
	  , F.ContactByPost AS ContactByPost
	  , a.DeactivatedDate
	FROM SLC_Report..Fan f 
	INNER JOIN SLC_Report..NobleFanAttributes n on f.CompositeID = n.CompositeID
	INNER JOIN MI.CustomerActiveStatus a on f.ID = a.FanID
	
	ALTER INDEX IX_MI_SchemeFanInfo_CIN ON MI.SchemeFanInfo REBUILD
	
	UPDATE MI.SchemeFanInfo SET CINID = c.CINID
	FROM MI.SchemeFanInfo f
	INNER JOIN Relational.CINList c on f.CIN = c.CIN
	
	ALTER INDEX IX_MI_SchemeFanInfo_CINID ON MI.SchemeFanInfo REBUILD
	
	UPDATE MI.SchemeFanInfo SET TmpBankID = C.BankID
	FROM MI.SchemeFanInfo F
	INNER JOIN Relational.CustomerAttribute C ON F.CINID = C.CINID
	
	UPDATE MI.SchemeFanInfo SET BankID = CASE C.IsRBS WHEN 1 THEN 1 ELSE 2 END
		, RainbowID = CASE C.IsRainbow WHEN 1 THEN 1 ELSE 2 END
	FROM MI.SchemeFanInfo F
	INNER JOIN Relational.CardTransactionBank c ON F.TmpBankID = C.BankID

END
