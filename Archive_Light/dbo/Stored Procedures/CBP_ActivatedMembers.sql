--Archive db
CREATE PROC [dbo].[CBP_ActivatedMembers]
AS
SET NOCOUNT ON

DECLARE 
	@StartDate datetime,
	@EndDate datetime = CONVERT(VARCHAR(10),CONVERT(DATE,GETDATE()-1)) + ' 23:59:59'

SELECT @StartDate = CONVERT(DATE,@EndDate)

--SELECT @StartDate, @EndDate

--SELECT 
--	SourceUId AS [CUSTOMER ID],
--	Email AS [E-MAIL ADDRESS],
--	MobileTelephone AS [MOBILE NUMBER],
--	CASE ClubID
--		WHEN 132 THEN '0278'
--		WHEN 138 THEN '0365'
--		ELSE ''
--	END AS [BANK ID]
--FROM fan
--WHERE ClubId IN (132, 138) AND Status = 1 
--	AND AgreedTCsDate BETWEEN @StartDate and @EndDate
--	AND ID NOT IN (1922583, 1978716, 3012641, 3037109, 2526131, 2473437, 2095124)


;WITH CHNG
AS
(
	SELECT
		FanID, 
		Value, 
		ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY Value DESC) AS RNum
	FROM ChangeLog.DataChangeHistory_Datetime 
		WHERE TableColumnsID = 21
	AND Value BETWEEN @StartDate and @EndDate  
)
SELECT 
	f.SourceUId AS [CUSTOMER ID],
	f.Email AS [E-MAIL ADDRESS],
	f.MobileTelephone AS [MOBILE NUMBER],
	CASE f.ClubID
		WHEN 132 THEN '0278'
		WHEN 138 THEN '0365'
		ELSE ''
	END AS [BANK ID]
FROM CHNG
INNER JOIN SLC_Report.dbo.Fan f on CHNG.FanID = f.ID
WHERE CHNG.RNum = 1
	AND f.ClubId IN (132, 138) --AND f.Status = 1
	AND f.ID NOT IN (1922583, 1978716, 3012641, 3037109, 2526131, 2473437, 2095124) 