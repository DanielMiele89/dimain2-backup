-- =============================================
-- Author:		JEA
-- Create date: 06/06/2013
-- Description:	Gets list of scheme customers
-- =============================================
CREATE PROCEDURE [MI].[SchemeCustomer_Load] 
	
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
	--JEA 25/11/2013 link produced where a customer's most recent activation was offline, else null
	--LEFT OUTER JOIN (SELECT DISTINCT h.FanID
	--					FROM MI.CustomerActivationHistory h
	--					INNER JOIN (SELECT FanID, MAX(StatusDate) AS StatusDate
	--								FROM MI.CustomerActivationHistory
	--								WHERE ActivationStatusID = 1
	--								GROUP BY FanID) s ON h.FanID = s.FanID and h.StatusDate = s.StatusDate
	--					WHERE ActivationStatusID = 1
	--					AND ActivatedOffline = 1) o ON f.ID = o.FanID
	LEFT OUTER JOIN (SELECT FanID, EmailEngaged
						FROM Relational.Customer_EmailEngagement
						WHERE EndDate IS NULL) e ON f.ID = e.FanID
	INNER JOIN (SELECT FanID, Registered
					FROM Relational.Customer) r ON F.ID = r.FanID
	ORDER BY FanID
   
END