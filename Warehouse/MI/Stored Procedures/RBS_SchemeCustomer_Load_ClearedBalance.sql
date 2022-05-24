-- =============================================
-- Author:		JEA
-- Create date: 15/12/2014
-- Description:	Gets list of scheme customers
-- =============================================
CREATE PROCEDURE [MI].[RBS_SchemeCustomer_Load_ClearedBalance] 
	
AS
BEGIN
	
	SET NOCOUNT ON;
   
   SELECT f.ID AS FanID
		, f.Sex AS GenderID
		, f.DOB
      , a.ActivatedDate AS ActivationDate
	  , a.DeactivatedDate
	  , a.OptedOutDate
	  , CAST(CASE WHEN a.IsRBS = 1 THEN 1 ELSE 2 END AS TINYINT) AS BankID
	  , CAST(ISNULL(CASE WHEN b.IsRainbow = 1 THEN 1 ELSE 2 END,2) AS TINYINT) AS RainbowID
	  , CAST(CASE WHEN F.Unsubscribed = 1 THEN 0 ELSE 1 END AS INT) As ContactByEmail
	  , CAST(F.ContactByPhone AS INT) AS ContactByPhone
	  , CAST(F.ContactBySMS AS INT) AS ContactBySMS
	  , CAST(F.ContactByPost AS INT) AS ContactByPost
	  , ISNULL(j.CustomerJourneyStatus, 'MOT1') As CustomerJourneyStatus
	  , ISNULL(j.LapsFlag, 'Not Lapsed') AS LapsFlag
	  , a.ActivationMethodID AS ActivationMethod
	  , f.SourceUID
	  , ISNULL(e.EmailEngaged,0) AS EmailEngaged
	  , ISNULL(r.Registered, 0) AS Registered
	  , ISNULL(co.ChannelPreferenceID, 3) AS ChannelPreferenceID
	  , f.ActivationChannel
	  , f.ClubCashAvailable As ClearedBalance
	FROM SLC_Report..Fan f 
	INNER JOIN MI.CustomerActiveStatus a on f.ID = a.FanID
	LEFT OUTER JOIN (SELECT c.CIN, b.IsRainbow
						FROM Relational.CINList c
						INNER JOIN Relational.CustomerAttribute CA ON C.CINID = CA.CINID
						INNER JOIN Relational.CardTransactionBank b ON CA.BankID = b.BankID
					) b on f.sourceUID = b.CIN
	LEFT OUTER JOIN (SELECT FanID, CustomerJourneyStatus, LapsFlag
				FROM Relational.CustomerJourney
				WHERE EndDate IS NULL) j on f.ID = j.FanID
	LEFT OUTER JOIN (SELECT FanID, EmailEngaged
						FROM Relational.Customer_EmailEngagement
						WHERE EndDate IS NULL) e ON f.ID = e.FanID
	INNER JOIN (SELECT FanID, Registered
					FROM Relational.Customer) r ON F.ID = r.FanID
	LEFT OUTER JOIN MI.RBS_ChannelPreferenceOffline co ON F.ID = co.FanID
	ORDER BY FanID
   
END
