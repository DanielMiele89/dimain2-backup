
-- =============================================
-- Author:		Rory
-- Create date:	2020-11-06
-- Description:	On the morning of a newsletter deployemnt, update the LionSendIDs of customers if they do / do not meet the criteria for a test group
-- =============================================

CREATE PROCEDURE [SmartEmail].[NewsletterTesting_LionSendID_Update_20210920]
AS
BEGIN

	SET NOCOUNT ON;
	
/*******************************************************************************************************************************************
	1.	Fetch eligible customers
*******************************************************************************************************************************************/

	DECLARE	@EmailDate DATE
		,	@Today DATE = GETDATE()

	SELECT @EmailDate = MAX(EmailSendDate)
	FROM [Staging].[R_0183_LionSendVolumesCheck]
		
	IF OBJECT_ID('tempdb..#CustomerFan') IS NOT NULL DROP TABLE #CustomerFan;
	SELECT	dd.FanID
		,	CASE
				WHEN ClubCashAvailable < 5 OR slt.FanID IS NOT NULL THEN 839
				ELSE 840
			END AS LionSendID
	INTO #CustomerFan
	FROM [SmartEmail].[DailyData] dd
	INNER JOIN Relational.Customer cu
		ON dd.FanID = cu.FanID
	LEFT JOIN [SmartEmail].[SubjectLineTest_TestGroupControlGroup_20200610] slt
		ON dd.FanID = slt.FanID
	WHERE @Today <= @EmailDate

	CREATE CLUSTERED INDEX CIX_FanID ON #CustomerFan (FanID)

	UPDATE osd
	SET osd.LionSendID = cu.LionSendID
	FROM SmartEmail.OfferSlotData osd
	INNER JOIN #CustomerFan cu
		ON osd.FanID = cu.FanID
	WHERE osd.LionSendID != cu.LionSendID
	AND EXISTS (	SELECT 1
					FROM #CustomerFan cf
					WHERE osd.LionSendID = cf.LionSendID)

	UPDATE osd
	SET osd.LionSendID = cu.LionSendID
	FROM SmartEmail.RedeemOfferSlotData osd
	INNER JOIN #CustomerFan cu
		ON osd.FanID = cu.FanID
	WHERE osd.LionSendID != cu.LionSendID
	AND EXISTS (	SELECT 1
					FROM #CustomerFan cf
					WHERE osd.LionSendID = cf.LionSendID)
		
	IF OBJECT_ID('tempdb..#CustomerComposite') IS NOT NULL DROP TABLE #CustomerComposite;
	SELECT	cu.CompositeID
		,	CASE
				WHEN ClubCashAvailable < 5 OR slt.FanID IS NOT NULL THEN 839
				ELSE 840
			END AS LionSendID
	INTO #CustomerComposite
	FROM [SmartEmail].[DailyData] dd
	INNER JOIN Relational.Customer cu
		ON dd.FanID = cu.FanID
	LEFT JOIN [SmartEmail].[SubjectLineTest_TestGroupControlGroup_20200610] slt
		ON dd.FanID = slt.FanID
	WHERE @Today <= @EmailDate

	CREATE CLUSTERED INDEX CIX_CompositeID ON #CustomerComposite (CompositeID)

	UPDATE ls
	SET ls.LionSendID = cu.LionSendID
	FROM Lion.NominatedLionSendComponent ls
	INNER JOIN #CustomerComposite cu
		ON ls.CompositeID = cu.CompositeID
	WHERE ls.LionSendID != cu.LionSendID
	AND EXISTS (	SELECT 1
					FROM #CustomerFan cf
					WHERE ls.LionSendID = cf.LionSendID)

	UPDATE ls
	SET ls.LionSendID = cu.LionSendID
	FROM Lion.NominatedLionSendComponent_RedemptionOffers ls
	INNER JOIN #CustomerComposite cu
		ON ls.CompositeID = cu.CompositeID
	WHERE ls.LionSendID != cu.LionSendID
	AND EXISTS (	SELECT 1
					FROM #CustomerFan cf
					WHERE ls.LionSendID = cf.LionSendID)
	
--	IF OBJECT_ID('tempdb..#SubjectLineTest') IS NOT NULL DROP TABLE #SubjectLineTest;
--	WITH
--	SubjectLineTest AS (SELECT	cu.SubjectLineTestID
--							,	cu.SubjectLineTestGroupID
--							,	cu.FanID
--							,	gr.ClubID
--							,	gr.IsLoyalty
--							,	gr.ClubCashAvailableMin
--							,	gr.ClubCashAvailableMax
--							,	sch.SubjectLineType
--							,	sch.LionSendID
--						FROM [SmartEmail].[SubjectLineTestCustomers] cu
--						INNER JOIN [SmartEmail].[SubjectLineTestSchedule] sch
--							ON cu.SubjectLineTestID = sch.SubjectLineTestID
--							AND cu.SubjectLineTestGroupID = sch.SubjectLineTestGroupID
--							AND sch.EmailDate BETWEEN @StartDate AND @EndDate
--						INNER JOIN [SmartEmail].[SubjectLineTestGroup] gr
--							ON cu.SubjectLineTestID = gr.SubjectLineTestID
--							AND cu.SubjectLineTestGroupID = gr.SubjectLineTestGroupID),

--	DynamicSL AS (	SELECT	SubjectLineTestID
--						,	SubjectLineTestGroupID
--						,	FanID
--						,	ClubID
--						,	IsLoyalty
--						,	ClubCashAvailableMin
--						,	ClubCashAvailableMax
--						,	LionSendID
--					FROM SubjectLineTest
--					WHERE SubjectLineType = 'Dynamic'),

--	StandardLS AS (	SELECT	DISTINCT
--							LionSendID
--					FROM SubjectLineTest
--					WHERE SubjectLineType = 'Standard'),

--	Customer_RBSGSegments AS (	SELECT	sg.FanID
--									,	CASE
--											WHEN sg.CustomerSegment LIKE '%v%' THEN 1
--											ELSE 0
--										END AS IsLoyalty
--								FROM [Relational].[Customer_RBSGSegments] sg
--								WHERE sg.EndDate IS NULL
--								AND EXISTS (SELECT 1
--											FROM SubjectLineTest slt
--											WHERE sg.FanID = slt.FanID))

--	SELECT	dsl.FanID
--		,	fa.CompositeID
--		,	dsl.LionSendID  AS LionSendID_Dynamic
--		,	(SELECT LionSendID FROM StandardLS)  AS LionSendID_Standard
--		,	CASE
--				WHEN dsl.ClubCashAvailableMin <= fa.ClubCashAvailable AND dsl.ClubID = fa.ClubID AND dsl.IsLoyalty = sg.IsLoyalty THEN dsl.LionSendID
--				ELSE (SELECT LionSendID FROM StandardLS)
--			END AS LionSendID
--	INTO #SubjectLineTest
--	FROM [SLC_REPL].[dbo].[Fan] fa
--	INNER JOIN Customer_RBSGSegments sg
--		ON fa.ID = sg.FanID
--	INNER JOIN DynamicSL dsl
--		ON fa.ID = dsl.FanID

--	CREATE CLUSTERED INDEX CIX_CompLion ON #SubjectLineTest (CompositeID, LionSendID)
--	CREATE NONCLUSTERED INDEX IX_FanLion ON #SubjectLineTest (FanID, LionSendID)

--	;WITH
--	SubjectLine AS (	SELECT	DISTINCT
--								sch.SubjectLineTestID
--							,	sch.SubjectLineTestGroupID
--							,	gr.ClubID
--							,	gr.IsLoyalty
--							,	gr.ClubCashAvailableMin
--							,	gr.ClubCashAvailableMax
--							,	sch.SubjectLineType
--							,	sch.LionSendID
--						FROM [SmartEmail].[SubjectLineTestSchedule] sch
--						INNER JOIN [SmartEmail].[SubjectLineTestGroup] gr
--							ON sch.SubjectLineTestID = gr.SubjectLineTestID
--							AND sch.SubjectLineTestGroupID = gr.SubjectLineTestGroupID
--						WHERE sch.EmailDate BETWEEN @StartDate AND @EndDate),

--	DynamicSL AS (	SELECT	SubjectLineTestID
--						,	SubjectLineTestGroupID
--						,	ClubID
--						,	IsLoyalty
--						,	ClubCashAvailableMin
--						,	ClubCashAvailableMax
--						,	LionSendID
--					FROM SubjectLine
--					WHERE SubjectLineType = 'Dynamic'),

--	StandardLS AS (	SELECT	DISTINCT
--							LionSendID
--					FROM SubjectLine
--					WHERE SubjectLineType = 'Standard'),

--	Customer_RBSGSegments AS (	SELECT	sg.FanID
--									,	CASE
--											WHEN sg.CustomerSegment LIKE '%v%' THEN 1
--											ELSE 0
--										END AS IsLoyalty
--								FROM [Relational].[Customer_RBSGSegments] sg
--								WHERE sg.EndDate IS NULL)
							
--	INSERT INTO #SubjectLineTest
--	SELECT	osd.FanID
--		,	fa.CompositeID
--		,	dsl.LionSendID AS LionSendID_Dynamic
--		,	(SELECT LionSendID FROM StandardLS)  AS LionSendID_Standard
--		,	CASE
--				WHEN dsl.ClubCashAvailableMin <= fa.ClubCashAvailable AND dsl.ClubID = fa.ClubID AND dsl.IsLoyalty = sg.IsLoyalty THEN dsl.LionSendID
--				ELSE (SELECT LionSendID FROM StandardLS)
--			END AS LionSendID
--	FROM [SmartEmail].[OfferSlotData] osd
--	INNER JOIN [SLC_REPL].[dbo].[Fan] fa
--		ON osd.FanID = fa.ID
--	INNER JOIN Customer_RBSGSegments sg
--		ON fa.ID = sg.FanID
--	LEFT JOIN DynamicSL dsl
--		ON fa.ClubID = dsl.ClubID
--		AND sg.IsLoyalty = dsl.IsLoyalty
--	WHERE NOT EXISTS (	SELECT 1
--						FROM #SubjectLineTest slt
--						WHERE osd.FanID = slt.FanID)


--/*******************************************************************************************************************************************
--	2.	Update tables in the Lion Schema
--*******************************************************************************************************************************************/

--	UPDATE ls
--	SET ls.LionSendID = slt.LionSendID
--	FROM #SubjectLineTest slt
--	INNER JOIN [Lion].[NominatedLionSendComponent] ls
--		ON slt.CompositeID = ls.CompositeID
--		AND ls.LionSendID IN (slt.LionSendID_Standard, slt.LionSendID_Dynamic)

--	UPDATE ls
--	SET ls.LionSendID = slt.LionSendID
--	FROM #SubjectLineTest slt
--	INNER JOIN [Lion].[NominatedLionSendComponent_RedemptionOffers] ls
--		ON slt.CompositeID = ls.CompositeID
--		AND ls.LionSendID IN (slt.LionSendID_Standard, slt.LionSendID_Dynamic)


--/*******************************************************************************************************************************************
--	2.	Update tables in the SmartEmail
--*******************************************************************************************************************************************/
		
--	UPDATE osd
--	SET osd.LionSendID = slt.LionSendID
--	FROM #SubjectLineTest slt
--	INNER JOIN [SmartEmail].[OfferSlotData] osd
--		ON slt.FanID = osd.FanID
--		AND osd.LionSendID IN (slt.LionSendID_Standard, slt.LionSendID_Dynamic)

--	UPDATE osd
--	SET osd.LionSendID = slt.LionSendID
--	FROM #SubjectLineTest slt
--	INNER JOIN [SmartEmail].[RedeemOfferSlotData] osd
--		ON slt.FanID = osd.FanID
--		AND osd.LionSendID IN (slt.LionSendID_Standard, slt.LionSendID_Dynamic)

END