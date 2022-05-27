
-- =============================================
-- Author:		Rory
-- Create date:	2020-11-06
-- Description:	On the morning of a newsletter deployemnt, update the LionSendIDs of customers if they do / do not meet the criteria for a test group
-- =============================================

CREATE PROCEDURE [SmartEmail].[NewsletterTesting_LionSendID_Update]
AS
BEGIN

	SET NOCOUNT ON;
	
/*******************************************************************************************************************************************
	1.	Fetch eligible customers
*******************************************************************************************************************************************/

	DECLARE	@EmailDate DATE
		,	@Today DATE = GETDATE()
		,	@CheckDate DATETIME = DATEADD(DAY, 0, GETDATE())

	SELECT @EmailDate = MAX(EmailSendDate)
	FROM [Staging].[R_0183_LionSendVolumesCheck]
	WHERE UsersUploadedSFD IS NULL

	IF @EmailDate IS NULL RETURN
	
	IF OBJECT_ID('tempdb..#EmailSendIDs') IS NOT NULL DROP TABLE #EmailSendIDs;
	SELECT	EmailType
		,	ID
	INTO #EmailSendIDs
	FROM [WH_AllPublishers].[Email].[EmailSend]
	WHERE Scheme = 'MyRewards'
	AND EmailType IN ('Newsletter - Full Generic',  'Newsletter - Full Dynamic')
	AND EmailSendDate = @EmailDate
	
	IF OBJECT_ID('tempdb..#EmailSend') IS NOT NULL DROP TABLE #EmailSend;
	SELECT	MAX(CASE
					WHEN EmailType = 'Newsletter - Full Generic' THEN ID
				END) AS LionSendID_Generic
		,	MAX(CASE
					WHEN EmailType = 'Newsletter - Full Dynamic' THEN ID
					ELSE ID
				END) AS LionSendID_Dynamic
	INTO #EmailSend
	FROM #EmailSendIDs
		
	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;
	SELECT	cu.FanID
		,	cu.CompositeID
		,	dd.ClubCashAvailable
		,	CASE
				WHEN 5 <= ClubCashAvailable THEN LionSendID_Dynamic
				ELSE LionSendID_Generic
			END AS LionSendID
	INTO #Customer
	FROM [SmartEmail].[vw_SmartEmailDailyData_v2] dd
	INNER JOIN [Relational].[Customer] cu
		ON dd.FanID = cu.FanID
	CROSS JOIN #EmailSend es
	WHERE NOT EXISTS (	SELECT 1
						FROM [SmartEmail].[SubjectLineTest_TestGroupControlGroup_20200610] slt
						WHERE dd.FanID = slt.FanID)
						
	CREATE CLUSTERED INDEX CIX_CompositeID ON #Customer (CompositeID)
	CREATE NONCLUSTERED INDEX IX_FanID ON #Customer (FanID)


/*******************************************************************************************************************************************
	2.	Update tables in the Lion Schema
*******************************************************************************************************************************************/

	UPDATE ls
	SET ls.LionSendID = COALESCE(cu.LionSendID, 0)
	FROM [Lion].[NominatedLionSendComponent] ls
	INNER JOIN #Customer cu
		ON ls.CompositeID = cu.CompositeID
	WHERE ls.LionSendID != cu.LionSendID
	AND EXISTS (	SELECT 1
					FROM #EmailSendIDs esi
					WHERE ls.LionSendID = esi.ID)

	UPDATE ls
	SET ls.LionSendID = COALESCE(cu.LionSendID, 0)
	FROM [Lion].[NominatedLionSendComponent_RedemptionOffers] ls
	INNER JOIN #Customer cu
		ON ls.CompositeID = cu.CompositeID
	WHERE ls.LionSendID != cu.LionSendID
	AND EXISTS (	SELECT 1
					FROM #EmailSendIDs esi
					WHERE ls.LionSendID = esi.ID)


/*******************************************************************************************************************************************
	3.	Update tables in the SmartEmail
*******************************************************************************************************************************************/

	UPDATE osd
	SET osd.LionSendID = COALESCE(cu.LionSendID, 0)
	FROM [SmartEmail].[OfferSlotData] osd
	LEFT JOIN #Customer cu
		ON osd.FanID = cu.FanID
	WHERE osd.LionSendID != cu.LionSendID
	AND EXISTS (	SELECT 1
					FROM #EmailSendIDs esi
					WHERE osd.LionSendID = esi.ID)

	UPDATE osd
	SET osd.LionSendID = COALESCE(cu.LionSendID, 0)
	FROM [SmartEmail].[RedeemOfferSlotData] osd
	INNER JOIN #Customer cu
		ON osd.FanID = cu.FanID
	WHERE osd.LionSendID != cu.LionSendID
	AND EXISTS (	SELECT 1
					FROM #EmailSendIDs esi
					WHERE osd.LionSendID = esi.ID)

END