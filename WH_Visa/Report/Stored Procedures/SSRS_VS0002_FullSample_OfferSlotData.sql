
/********************************************************************************************
	Name:	[Report].[SSRS_V0002_FullSample_OfferSlotData]
	Desc:	Gets all Offer information for Sample Customers for Ops to be able to cross check
	Auth:	Rory Francis

	Change History
	Initials	Date		Change Info

*********************************************************************************************/

CREATE PROCEDURE [Report].[SSRS_VS0002_FullSample_OfferSlotData] (@LionSendID INT)

AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	--	DECLARE @LionSendID INT = 843

	DECLARE @LSID INT = @LionSendID

	IF @LSID IS NULL
		BEGIN
			SELECT @LSID = MIN(LionSendID)
			FROM [Email].[NewsletterReporting] nr
			WHERE ReportSent = 0
			AND ReportName = 'SSRS_VS0002_FullSample_OfferSlotData'
		END
		
/*******************************************************************************************************************************************
	1. Fetch all sample customer information 
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#SmartEmailDailyData') IS NOT NULL DROP TABLE #SmartEmailDailyData
		SELECT	LastName + ' - ' + Email AS Email
			,	sedd.FanID
			,	LionSendID
			,	EarnOfferID_Hero
			,	EarnOfferID_1
			,	EarnOfferID_2
			,	EarnOfferID_3
			,	EarnOfferID_4
			,	EarnOfferID_5
			,	EarnOfferID_6
			,	EarnOfferID_7
			,	EarnOfferID_8
			,	EarnOfferStartDate_Hero
			,	EarnOfferStartDate_1
			,	EarnOfferStartDate_2
			,	EarnOfferStartDate_3
			,	EarnOfferStartDate_4
			,	EarnOfferStartDate_5
			,	EarnOfferStartDate_6
			,	EarnOfferStartDate_7
			,	EarnOfferStartDate_8
			,	EarnOfferEndDate_Hero
			,	EarnOfferEndDate_1
			,	EarnOfferEndDate_2
			,	EarnOfferEndDate_3
			,	EarnOfferEndDate_4
			,	EarnOfferEndDate_5
			,	EarnOfferEndDate_6
			,	EarnOfferEndDate_7
			,	EarnOfferEndDate_8
			,	BurnOfferID_Hero
			,	BurnOfferID_1
			,	BurnOfferID_2
			,	BurnOfferID_3
			,	BurnOfferID_4
			,	BurnOfferEndDate_Hero
			,	BurnOfferEndDate_1
			,	BurnOfferEndDate_2
			,	BurnOfferEndDate_3
			,	BurnOfferEndDate_4
		INTO #SmartEmailDailyData 
		From [Email].[vw_EmailDailyData] sedd
		INNER JOIN [Email].[SampleCustomersList] scli
			ON sedd.FanID = scli.FanID
		INNER JOIN [Email].[SampleCustomerLinks] scln
			ON scli.ID = scln.SampleCustomerID
		WHERE sedd.LionSendID = @LSID


/*******************************************************************************************************************************************
	2. Transpose oofer data to long format
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
		CREATE TABLE #Offers (	FanID INT
							,	Email VARCHAR(250)
							,	OfferType VARCHAR(10)
							,	ItemID INT
							,	OfferStartDate DATETIME
							,	OfferEndDate DATETIME
							,	Slot INT)

		DECLARE	@Query VARCHAR(MAX)
			,	@OfferType VARCHAR(4) = 'Earn'
			,	@OfferNumberINT INT = 1
			,	@OfferNumberVAR VARCHAR(4) = 'Hero'
			,	@OfferID VARCHAR(50)
			,	@OfferStartDate VARCHAR(50)
			,	@OfferEndDate VARCHAR(50)

		WHILE @OfferNumberINT <= 7
			BEGIN
				
				SELECT	@OfferID =  'EarnOfferID_' + @OfferNumberVAR
					,	@OfferStartDate = 'EarnOfferStartDate_' + @OfferNumberVAR
					,	@OfferEndDate = 'EarnOfferEndDate_' + @OfferNumberVAR

				SET @Query = '
				INSERT INTO #Offers
				SELECT	FanID
					,	Email
					,	''' + @OfferType + '''
					,	' + @OfferID + '
					,	' + @OfferStartDate + '
					,	' + @OfferEndDate + '
					,	' + CONVERT(VARCHAR(10), @OfferNumberINT) + '
				FROM #SmartEmailDailyData'

				EXEC (@Query)

				SET @OfferNumberVAR = @OfferNumberINT
				SET @OfferNumberINT = @OfferNumberINT + 1

			END

		SELECT	@OfferType = 'Burn'
			,	@OfferNumberINT = 1
			,	@OfferNumberVAR = 'Hero'

		WHILE @OfferNumberINT <= 5
			BEGIN
				
				SELECT	@OfferID =  'BurnOfferID_' + @OfferNumberVAR
					,	@OfferEndDate = 'BurnOfferEndDate_' + @OfferNumberVAR

				SET @Query = '
				INSERT INTO #Offers
				SELECT	FanID
					,	Email
					,	''' + @OfferType + '''
					,	' + @OfferID + '
					,	NULL
					,	' + @OfferEndDate + '
					,	' + CONVERT(VARCHAR(10), @OfferNumberINT) + '
				FROM #SmartEmailDailyData'

				EXEC (@Query)

				SET @OfferNumberVAR = @OfferNumberINT
				SET @OfferNumberINT = @OfferNumberINT + 1

			END


/*******************************************************************************************************************************************
	3. Offer data ranked to show first instance of offers in report
*******************************************************************************************************************************************/

		DECLARE @Today DATETIME = GetDate()

		IF OBJECT_ID('tempdb..#SSRS_V0002_FullSample_OfferSlotData_v2') IS NOT NULL DROP TABLE #SSRS_V0002_FullSample_OfferSlotData_v2
		SELECT	FanID
			,	Email
			,	OfferType
			,	ItemID
			,	OfferName
			,	OfferStartDate
			,	OfferEndDate
			,	Slot
			,	CONVERT(VARCHAR(30), OfferAge) AS OfferAge
			,	DENSE_RANK() OVER (PARTITION BY OfferType, ItemID ORDER BY NewOfferCount DESC, FanID, Slot) AS OfferRank
			,	DENSE_RANK() OVER (PARTITION BY OfferType, ItemID ORDER BY NewOfferCount DESC, FanID, Slot) AS OfferRankPerSegment
		INTO #SSRS_V0002_FullSample_OfferSlotData_v2
		FROM (	SELECT	o.FanID
					,	o.Email
					,	o.OfferType
					,	o.ItemID
					,	COALESCE(iof.IronOfferName, '£' + CONVERT(VARCHAR(10), ro.TradeUp_CashbackRequired) + ' ' + rp.PartnerName + ' Gift Card + ' + CONVERT(VARCHAR(10), ro.TradeUp_MarketingPercentage) + '% back in Rewards') as OfferName
					,	OfferStartDate
					,	OfferEndDate
					,	CASE
							WHEN OfferType = 'Earn' THEN Slot
							WHEN OfferType = 'Burn' THEN Slot
						END AS Slot
					,	CASE
							WHEN iof.StartDate > @Today THEN 'New'
							Else 'Existing'
						END AS OfferAge
					,	COUNT(	CASE
									WHEN iof.StartDate > @Today THEN 1
								END) OVER (PARTITION BY FanID) AS NewOfferCount
				From #Offers o
				LEFT JOIN [Derived].[IronOffer] iof
					ON o.ItemID = iof.IronOfferID
					AND o.OfferType = 'Earn'
				LEFT JOIN [Derived].[RedemptionOffers] ro
					ON o.ItemID = ro.ID
					AND o.OfferType = 'Burn'
				LEFT JOIN [Derived].[RedemptionPartners] rp 
					ON ro.RedemptionPartnerGUID = rp.RedemptionPartnerGUID	
					
					) [all]

/*******************************************************************************************************************************************
	4. Find offers that have not been checked previously
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#OffersRan') IS NOT NULL DROP TABLE #OffersRan
	SELECT	DISTINCT
			ItemID
		,	TypeID
	INTO #OffersRan
	FROM [Email].[Newsletter_Offers] ls
	WHERE ls.EmailSendDate < GETDATE()

	IF OBJECT_ID('tempdb..#OffersNotCheckedPreviously') IS NOT NULL DROP TABLE #OffersNotCheckedPreviously
	SELECT	DISTINCT
			ItemID
		,	OfferType
		,	StartDate
	INTO #OffersNotCheckedPreviously
	FROM #SSRS_V0002_FullSample_OfferSlotData_v2 osd
	INNER JOIN [Derived].[IronOffer] iof
		ON osd.ItemID = iof.IronOfferID
	WHERE NOT EXISTS (	SELECT 1
						FROM #OffersRan ls
						WHERE osd.ItemID = ls.ItemID
						AND osd.OfferType =	CASE
												WHEN ls.TypeID = 1 THEN 'Earn'
												ELSE 'Burn'
											END)


	UPDATE osd
	SET OfferAge = 'Existing - Not Checked'
	FROM #SSRS_V0002_FullSample_OfferSlotData_v2 osd
	INNER JOIN #OffersNotCheckedPreviously onc
		ON osd.ItemID = onc.ItemID
		AND osd.OfferType =onc.OfferType
	WHERE OfferAge = 'Existing'

/*******************************************************************************************************************************************
	5. Output for report
*******************************************************************************************************************************************/

	SELECT	Email
		,	ClubSegment
		,	OfferType
		,	COALESCE(CONVERT(VARCHAR(64), iof.HydraOfferID), CONVERT(VARCHAR(64), ro.RedemptionOfferGUID), CONVERT(VARCHAR(64), ItemID)) AS ItemID
		,	OfferName
		,	OfferStartDate
		,	OfferEndDate
		,	Slot
		,	OfferSlot
		,	OfferAge
		,	OfferRank
		,	OfferRankPerSegment
		,	OfferColour
		,	ROW_NUMBER() OVER (ORDER BY OfferRank_Sum DESC, OfferRankPerSegment_Sum DESC, FanID, OfferType DESC, Slot) AS ReportOrder
	FROM (	Select	FanID
				,	Email
				,	'All Customers' AS ClubSegment
				,	OfferType
				,	ItemID
				,	OfferName
				,	OfferStartDate
				,	OfferEndDate
				,	Slot
				,	CASE
						WHEN Slot = 1 THEN 'Hero'
						ELSE CONVERT(VARCHAR(1), Slot - 1)
					End AS OfferSlot
				,	CASE
						WHEN OfferAge = 'Existing' THEN 'Existing'
						ELSE 'New'
					END AS OfferAge
				,	OfferRank
				,	OfferRankPerSegment
				,	CASE
						WHEN OfferAge = 'New' AND OfferRank = 1 THEN '#fffe00'
						WHEN OfferAge = 'New' AND OfferRankPerSegment = 1 THEN '#ffa500'
						WHEN OfferAge = 'Existing - Not Checked' AND OfferRank = 1 THEN '#00ff00'
						WHEN OfferAge = 'Existing - Not Checked' AND OfferRankPerSegment = 1 THEN '#00ffc0'
					END AS OfferColour
				,	ROW_NUMBER() OVER (ORDER BY FanID, OfferType DESC, Slot) as ReportOrder
				,	SUM(CASE
							WHEN OfferAge = 'New' AND OfferRank = 1 THEN 1
						END) OVER (PARTITION BY Email) AS OfferRank_Sum
				,	SUM(CASE
							WHEN OfferAge = 'New' AND OfferRankPerSegment = 1 THEN 1
						END) OVER (PARTITION BY Email) as OfferRankPerSegment_Sum
			FROM #SSRS_V0002_FullSample_OfferSlotData_v2) a
	LEFT JOIN [Derived].[IronOffer] iof
		ON a.ItemID = iof.IronOfferID
	LEFT JOIN [Derived].[RedemptionOffers] ro
		ON a.ItemID = ro.ID
	--WHERE OfferType = 'Earn'
	ORDER BY	ROW_NUMBER() OVER (ORDER BY OfferRank_Sum DESC, OfferRankPerSegment_Sum DESC, FanID, OfferType DESC, Slot)
			,	OfferType DESC
			,	Slot

	UPDATE [Email].[NewsletterReporting]
	SET ReportSent = 1
	WHERE ReportSent = 0
	AND ReportName = 'SSRS_VS0002_FullSample_OfferSlotData'
	AND LionSendID = @LSID
			   
END



