
/******************************************************************************
CAMPAIGN PLANNING TOOL - SCRIPT 2
---------------------------------
-- Author: Suraj Chahal
-- Create date: 10/11/2015
-- Description: Build the following tables used for Campaign Planning

Input from previous Queries:
-Staging.CampaignPlanning_Brand - analysed partner
-Staging.CampaignPlanning_AllCustomers - whole customer universe


BUILDS THEN TRUNCATES CampaignPlanning_Trans TABLE
*******************************************************************************/

CREATE PROCEDURE [Staging].[CampaignPlanning_2_TransactionalData]
									
AS
BEGIN
	SET NOCOUNT ON;

/**********************************************************************
****************Build the Campaign Planning Trans table****************
**********************************************************************/
/* Cal 4 weeks ago StartDate and EndDate*/
IF OBJECT_ID('tempdb..#Cal') IS NOT NULL DROP TABLE #Cal
SELECT	Stratification.LeastDate(CAST(CAST(DATEDIFF(WEEK, 0, GETDATE())*7-7*4-7 AS DATETIME) AS DATE) ,
			CAST(CAST(DATEDIFF(WEEK, 0, MaxDate)*7-7*4 AS DATETIME) AS DATE)) as StartDate, 
	Stratification.LeastDate( CAST(CAST(DATEDIFF(WEEK, 0, GETDATE())*7-1-7 AS DATETIME) AS DATE),
			CAST(CAST(DATEDIFF(WEEK, 0, MaxDate)*7-1 AS DATETIME) AS DATE))  as EndDate
INTO #Cal
FROM Staging.CampaignPlanning_MaxTrandate
--

/*******************************************************
********Excluding weeks when campaigns were live********
*******************************************************/
IF OBJECT_ID('tempdb..#Base_Offer1M') IS NOT NULL DROP TABLE #Base_Offer1M
SELECT	DISTINCT
	p.PartnerID,
	w.StartDate,
	w.EndDate,
	DATEDIFF(week, cal.StartDate, w.EndDate) as WeekNumb
INTO #Base_Offer1M
FROM Relational.SchemeUpliftTrans_Week w
INNER JOIN #Cal cal ON w.EndDate >= cal.StartDate
	AND w.StartDate <= cal.EndDate
CROSS JOIN Staging.CampaignPlanning_Brand p
WHERE NOT EXISTS (
		SELECT 1
		FROM Relational.IronOffer ab
		INNER JOIN Staging.CampaignPlanning_Brand pp
			ON ab.PartnerID = pp.PartnerID
		WHERE pp.PartnerID = p.PartnerID
			AND COALESCE(ab.StartDate, '1900-01-01') <= w.EndDate
			AND COALESCE(ab.EndDate, '2999-01-01') >= w.StartDate
			AND ab.IronOfferID NOT IN (
				SELECT BaseOfferID
				FROM Stratification.ReportingBaseOffer
				)
			AND ab.AboveBase = 1
		)

CREATE CLUSTERED INDEX IDX_BO ON #Base_Offer1M (StartDate,EndDate, PartnerID)
--

/*******************************************************************
***1 month Transactional data for natural response rate and spend***
*******************************************************************/
IF OBJECT_ID('tempdb..#Trans1M') IS NOT NULL DROP TABLE #Trans1M
SELECT	t.FanID,
	cc.PartnerID,
	WeekNumb,
	COALESCE(sum(Amount), 0) as Value,
	COUNT(1) as TransCount
INTO #Trans1M
FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
INNER JOIN Staging.CampaignPlanning_AllCustomers t
	ON t.CINID = ct.CINID
INNER JOIN Staging.CampaignPlanning_Brand_CCID cc
	ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
INNER JOIN #Base_Offer1M cw
	ON cw.PartnerID = cc.PartnerID
	AND ct.TranDate BETWEEN cw.StartDate AND cw.EndDate
WHERE Amount > 0
GROUP BY t.FanID, cc.PartnerID, WeekNumb, t.CINID


IF OBJECT_ID('tempdb..#Base_Offer2M') IS NOT NULL DROP TABLE #Base_Offer2M
SELECT	DISTINCT
	p.PartnerID,
	w.StartDate,
	w.EndDate,
	DATEDIFF(week, cal.StartDate, w.EndDate) as WeekNumb
INTO #Base_Offer2M
FROM Relational.SchemeUpliftTrans_Week w
INNER JOIN #Cal cal
	ON w.EndDate >= cal.StartDate
	AND w.StartDate <= cal.EndDate
CROSS JOIN Staging.CampaignPlanning_Brand p
WHERE PartnerID NOT IN 
	(
	SELECT t1M.PartnerID
	FROM #Trans1M t1M
	)
--

DELETE FROM #Base_Offer1M
WHERE PartnerID NOT IN 
	(
	SELECT	t1M.PartnerID
	FROM #Trans1M t1M
	)


IF OBJECT_ID('tempdb..#Trans2M') IS NOT NULL DROP TABLE #Trans2M
SELECT	t.FanID,
	cc.PartnerID,
	WeekNumb,
	COALESCE(SUM(Amount), 0) as Value,
	COUNT(1) as TransCount
INTO #Trans2M
FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
INNER JOIN Staging.CampaignPlanning_AllCustomers t
	ON t.CINID = ct.CINID
INNER JOIN Staging.CampaignPlanning_Brand_CCID cc
	ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
INNER JOIN #Base_Offer2M cw
	ON cw.PartnerID = cc.PartnerID
	AND ct.TranDate BETWEEN cw.StartDate AND cw.EndDate
WHERE Amount > 0
GROUP BY t.FanID, cc.PartnerID, WeekNumb, t.CINID



IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	*
INTO #Trans
FROM (
	SELECT *
	FROM #Trans1M
UNION ALL
	SELECT *
	FROM #Trans2M
	)a


IF OBJECT_ID('tempdb..#Trans1M') IS NOT NULL DROP TABLE #Trans1M
IF OBJECT_ID('tempdb..#Trans2M') IS NOT NULL DROP TABLE #Trans2M
IF OBJECT_ID('tempdb..#Cal') IS NOT NULL DROP TABLE #Cal

CREATE CLUSTERED INDEX IDX_PartnerID ON #Trans (PartnerID);


IF OBJECT_ID('tempdb..#Base_Offer') IS NOT NULL DROP TABLE #Base_Offer
SELECT	*
INTO #Base_Offer
FROM	(
	SELECT *
	FROM #Base_Offer1M
UNION ALL
	SELECT *
	FROM #Base_Offer2M
	)a
	

IF OBJECT_ID('tempdb..#1Week') IS NOT NULL DROP TABLE #1Week
SELECT	PartnerID
	,COUNT(*) Weeks
INTO #1Week
FROM #Base_Offer
WHERE WeekNumb IN (1,2,3,4)
GROUP BY PartnerID

CREATE CLUSTERED INDEX ParnerID ON #1Week (PartnerID);

IF OBJECT_ID('tempdb..#1WeekTrans') IS NOT NULL	DROP TABLE #1WeekTrans
SELECT	t.FanID,
	t.PartnerID,
	(1.0*SUM(Value)/Weeks) as Value,
	(1.0*SUM(TransCount)/Weeks) as TransCount
INTO #1WeekTrans
FROM #Trans t
INNER JOIN #1Week w
	ON w.PartnerID = t.PartnerID
WHERE t.WeekNumb IN (1,2,3,4)
GROUP BY t.FanID, t.PartnerID, w.Weeks
-- 5s

CREATE CLUSTERED INDEX ParnerID ON #1WeekTrans (PartnerID,FanID)

IF OBJECT_ID('Staging.CampaignPlanning_Trans') IS NOT NULL DROP TABLE Staging.CampaignPlanning_Trans
SELECT	t1.FanID,
	t1.PartnerID,
	t1.Value Value1W,
	t1.TransCount Trans1W
INTO Staging.CampaignPlanning_Trans
FROM #1WeekTrans t1

IF OBJECT_ID('tempdb..#1Week') IS NOT NULL DROP TABLE #1Week
IF OBJECT_ID('tempdb..#1WeekTrans') IS NOT NULL	DROP TABLE #1WeekTrans


CREATE CLUSTERED INDEX IDX_C ON Staging.CampaignPlanning_Trans (PartnerID,FanID)


/************************************
*********Update Total Sales**********
************************************/
DECLARE @PartnerID INT,
	@StartRow INT

SET @StartRow = 1
SET @PartnerID = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow)

WHILE @StartRow <= (SELECT MAX(RowNo) FROM Staging.CampaignPlanning_Brand)

BEGIN

	UPDATE Staging.CampaignPlanning_TriggerMember
	SET	Total_SalesValue_Wk1 = tr.Value1W,
		Total_Transactions_Wk1 = tr.Trans1W
	FROM Staging.CampaignPlanning_TriggerMember tm
	INNER JOIN Staging.CampaignPlanning_Trans tr
		ON tm.FanID = tr.FanID
		AND tm.PartnerID = tr.PartnerID
	WHERE tm.PartnerID = @PartnerID

SET @StartRow = @StartRow+1
SET @PartnerID = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow) 

END

TRUNCATE TABLE Staging.CampaignPlanning_Trans

END