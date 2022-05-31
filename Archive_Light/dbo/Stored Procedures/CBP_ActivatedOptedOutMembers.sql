--Archive db
CREATE PROC [dbo].[CBP_ActivatedOptedOutMembers] 
	@ClubID INT
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

/*

	[ChangeLog].[TableColumns]
	ID	TableName	ColumnName	Datatype
12	Fan	Status	int
ID	TableName	ColumnName	Datatype
25	Fan	OptOut	Bit

select top 10 * from ChangeLog.DataChangeHistory_Bit where TableColumnsID = 25 
select top 10 * from ChangeLog.DataChangeHistory_Int where TableColumnsID = 12 


*/

;WITH ACT_CHNG
AS
(
	SELECT
		FanID, 
		Value,
		Date, 
		ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY Date DESC) AS RNum
	FROM ChangeLog.DataChangeHistory_Int 
		WHERE TableColumnsID = 12
	AND Value BETWEEN @StartDate and @EndDate  
),
OPTOUT_CHNG
AS
(
	SELECT
		FanID, 
		Value,
		Date, 
		ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY Date DESC) AS RNum
	FROM ChangeLog.DataChangeHistory_Bit 
		WHERE TableColumnsID = 25
	AND Value BETWEEN @StartDate and @EndDate  
)
SELECT TOP 10
	f.SourceUId AS [CUSTOMER ID],
	CASE f.ClubID
		WHEN 132 THEN '0278'
		WHEN 138 THEN '0365'
	END AS [BANK ID],
	COALESCE(CONVERT(CHAR(1),ACT_CHNG.Value),'') AS [ACTIVE FLAG],
	COALESCE(CONVERT(CHAR(1),OPTOUT_CHNG.Value),'') AS [OPT OUT FLAG],
	CASE COALESCE(CONVERT(CHAR(1),OPTOUT_CHNG.Value),'') 
		WHEN '1' THEN COALESCE(CONVERT(VARCHAR(10),OPTOUT_CHNG.Date,120),'') 
		ELSE '' END AS [OPT OUT DATE]
FROM SLC_Report.dbo.Fan f
LEFT JOIN ACT_CHNG ON f.ID = ACT_CHNG.FanID AND ACT_CHNG.RNum = 1
LEFT JOIN OPTOUT_CHNG ON f.ID = OPTOUT_CHNG.FanID AND OPTOUT_CHNG.RNum = 1
WHERE f.ClubId = @ClubID
--	AND f.ID NOT IN (1922583, 1978716, 3012641, 3037109, 2526131, 2473437, 2095124) 



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[CBP_ActivatedOptedOutMembers] TO [crtimport]
    AS [dbo];

