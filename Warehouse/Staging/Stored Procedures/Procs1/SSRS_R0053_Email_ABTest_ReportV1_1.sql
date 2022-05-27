

-- *********************************************
-- Author: Suraj Chahal
-- Create date: 21/10/2014
-- Description: Shows Email Stats for the Campaign you have chosen in the Parameter
-- *********************************************
CREATE PROCEDURE [Staging].[SSRS_R0053_Email_ABTest_ReportV1_1] (
			@StartDate Date,
			@EndDate Date
			)
			
AS
BEGIN
	SET NOCOUNT ON;

--DECLARE	@CampaignID INT
--SET @CampaignID = 1


/**************************************************
***Find CampaignKeys between the Date Parameters***
**************************************************/
SELECT	DISTINCT 
	ck.CampaignID 
INTO #Camps
FROM Relational.Email_ABTest_CampaignKeys ck
INNER JOIN Relational.EmailCampaign ec
	ON ck.CampaignKey = ec.CampaignKey
WHERE	SendDate BETWEEN @StartDate AND @EndDate

/*************************************************************************
************************Find Members in the Campaign**********************
*************************************************************************/
IF OBJECT_ID ('tempdb..#CampaignMembers') IS NOT NULL DROP TABLE #CampaignMembers
SELECT	CampaignID,
	TestGroupID,
	FanID
INTO #CampaignMembers
FROM Warehouse.Relational.Email_ABTest_Members
WHERE	CampaignID IN (SELECT CampaignID FROM #Camps)


CREATE CLUSTERED INDEX IDX_FanID ON #CampaignMembers (FanID)
CREATE NONCLUSTERED INDEX IDX_CampaignID ON #CampaignMembers (CampaignID)
CREATE NONCLUSTERED INDEX IDX_TestGroupID ON #CampaignMembers (TestGroupID)


/*************************************************************************
***************Find CampaignKey's associated to the Campaign**************
*************************************************************************/
IF OBJECT_ID ('tempdb..#CampaignKeys') IS NOT NULL DROP TABLE #CampaignKeys
SELECT	ck.CampaignID,
	ck.CampaignKey,
	ec.CampaignName,
	cls.ClubID,
	CAST(ec.SendDate AS DATE) as SendDate
INTO #CampaignKeys
FROM Warehouse.Relational.Email_ABTest_CampaignKeys ck
INNER JOIN Warehouse.Relational.EmailCampaign ec
	ON ck.CampaignKey = ec.CampaignKey
INNER JOIN Warehouse.Relational.CampaignLionSendIDs cls
	ON ck.CampaignKey = cls.CampaignKey
WHERE	ck.CampaignID IN (Select CampaignID From #Camps)

CREATE CLUSTERED INDEX IDX_CampaignID ON #CampaignKeys (CampaignID)
CREATE NONCLUSTERED INDEX IDX_CampaignKey ON #CampaignKeys (CampaignKey)

/*************************************************************************
*****************Find Email Stats associated to the Campaign**************
*************************************************************************/
SELECT	a.CampaignID,
	a.CampaignName,
	a.ClubID,
	abt.Test_Description,
	a.SendDate,
	SUM(SentOK) as Delivered,
	SUM(Opened) as Opens,
	SUM(Clicked) as Clicked
FROM	(
	SELECT	ee.FanID,
		ck.CampaignID,
		ck.CampaignName,
		ck.SendDate,
		ck.ClubID,
		m.TestGroupID,
		MAX(CASE WHEN EmailEventCodeID IN (910,1301,605,301) THEN 1 ELSE 0 END) as SentOK,
		MAX(CASE WHEN EmailEventCodeID IN (1301,301,605) THEN 1 ELSE 0 END) as Opened,
		MAX(CASE WHEN EmailEventCodeID IN (605) THEN 1 ELSE 0 END) as Clicked,
		MAX(CASE WHEN EmailEventCodeID IN (701,702) THEN 1 ELSE 0 END) as Bounced
	FROM #CampaignKeys ck
	INNER JOIN #CampaignMembers m
		ON ck.CampaignID = m.CampaignID
	INNER JOIN Warehouse.Relational.EmailEvent ee
		ON ee.CampaignKey = ck.CampaignKey
		AND ee.FanID = m.FanID
	GROUP BY ee.FanID,ck.CampaignID,ck.CampaignName,ck.SendDate,ck.ClubID,m.TestGroupID
	)a
INNER JOIN Warehouse.Relational.Email_ABTest_Tests abt
	ON abt.CampaignID = a.CampaignID
	AND abt.TestGroupID = a.TestGroupID
WHERE Bounced = 0 OR Clicked = 1 OR Opened = 1
GROUP BY a.CampaignID,a.CampaignName,a.ClubID,abt.Test_Description,	a.SendDate
ORDER BY a.SendDate


END