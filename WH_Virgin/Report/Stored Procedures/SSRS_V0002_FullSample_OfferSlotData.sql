
/********************************************************************************************
	Name:	[Report].[SSRS_V0002_FullSample_OfferSlotData]
	Desc:	Gets all Offer information for Sample Customers for Ops to be able to cross check
	Auth:	Rory Francis

	Change History
	Initials	Date		Change Info

*********************************************************************************************/

CREATE PROCEDURE [Report].[SSRS_V0002_FullSample_OfferSlotData] (@LionSendID INT)

AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	--	DECLARE @LionSendID INT = 999

	DECLARE @LSID INT = @LionSendID

	IF @LSID IS NULL
		BEGIN
			SELECT @LSID = MIN([nr].[LionSendID])
			FROM [Email].[NewsletterReporting] nr
			WHERE [nr].[ReportSent] = 0
			AND [nr].[ReportName] = 'SSRS_V0002_FullSample_OfferSlotData'
		END
		
/*******************************************************************************************************************************************
	1. Fetch all sample customer information 
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#SmartEmailDailyData') IS NOT NULL DROP TABLE #SmartEmailDailyData
		SELECT	[sedd].[LastName] + ' - ' + [sedd].[Email] AS Email
			,	sedd.FanID
			,	[sedd].[LionSendID]
			,	[sedd].[EarnOfferID_Hero]
			,	[sedd].[EarnOfferID_1]
			,	[sedd].[EarnOfferID_2]
			,	[sedd].[EarnOfferID_3]
			,	[sedd].[EarnOfferID_4]
			,	[sedd].[EarnOfferID_5]
			,	[sedd].[EarnOfferID_6]
			,	[sedd].[EarnOfferID_7]
			,	[sedd].[EarnOfferID_8]
			,	[sedd].[EarnOfferStartDate_Hero]
			,	[sedd].[EarnOfferStartDate_1]
			,	[sedd].[EarnOfferStartDate_2]
			,	[sedd].[EarnOfferStartDate_3]
			,	[sedd].[EarnOfferStartDate_4]
			,	[sedd].[EarnOfferStartDate_5]
			,	[sedd].[EarnOfferStartDate_6]
			,	[sedd].[EarnOfferStartDate_7]
			,	[sedd].[EarnOfferStartDate_8]
			,	[sedd].[EarnOfferEndDate_Hero]
			,	[sedd].[EarnOfferEndDate_1]
			,	[sedd].[EarnOfferEndDate_2]
			,	[sedd].[EarnOfferEndDate_3]
			,	[sedd].[EarnOfferEndDate_4]
			,	[sedd].[EarnOfferEndDate_5]
			,	[sedd].[EarnOfferEndDate_6]
			,	[sedd].[EarnOfferEndDate_7]
			,	[sedd].[EarnOfferEndDate_8]
			,	[sedd].[BurnOfferID_Hero]
			,	[sedd].[BurnOfferID_1]
			,	[sedd].[BurnOfferID_2]
			,	[sedd].[BurnOfferID_3]
			,	[sedd].[BurnOfferID_4]
			,	[sedd].[BurnOfferEndDate_Hero]
			,	[sedd].[BurnOfferEndDate_1]
			,	[sedd].[BurnOfferEndDate_2]
			,	[sedd].[BurnOfferEndDate_3]
			,	[sedd].[BurnOfferEndDate_4]
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

		WHILE @OfferNumberINT <= 9
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
			,	[all].[OfferName]
			,	#Offers.[OfferStartDate]
			,	#Offers.[OfferEndDate]
			,	[all].[Slot]
			,	CONVERT(VARCHAR(30), [all].[OfferAge]) AS OfferAge
			,	DENSE_RANK() OVER (PARTITION BY OfferType, ItemID ORDER BY [all].[NewOfferCount] DESC, FanID, [all].[Slot]) AS OfferRank
			,	DENSE_RANK() OVER (PARTITION BY OfferType, ItemID ORDER BY [all].[NewOfferCount] DESC, FanID, [all].[Slot]) AS OfferRankPerSegment
		INTO #SSRS_V0002_FullSample_OfferSlotData_v2
		FROM (	SELECT	o.FanID
					,	o.Email
					,	o.OfferType
					,	o.ItemID
					,	COALESCE(iof.IronOfferName, 'Redmeption') as OfferName
					,	[o].[OfferStartDate]
					,	[o].[OfferEndDate]
					,	CASE
							WHEN [o].[OfferType] = 'Earn' THEN [o].[Slot]
							WHEN [o].[OfferType] = 'Burn' THEN [o].[Slot]
						END AS Slot
					,	CASE
							WHEN iof.StartDate > @Today THEN 'New'
							Else 'Existing'
						END AS OfferAge
					,	COUNT(	CASE
									WHEN iof.StartDate > @Today THEN 1
								END) OVER (PARTITION BY [o].[FanID]) AS NewOfferCount
				From #Offers o
				LEFT JOIN [Derived].[IronOffer] iof
					ON o.ItemID = iof.IronOfferID
					AND o.OfferType = 'Earn') [all]
					
/*******************************************************************************************************************************************
	4. Find offers that have not been checked previously
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#OffersRan') IS NOT NULL DROP TABLE #OffersRan
	SELECT	DISTINCT
			[ls].[ItemID]
		,	[ls].[TypeID]
	INTO #OffersRan
	FROM [Email].[Newsletter_Offers] ls
	WHERE ls.EmailSendDate < GETDATE()

	IF OBJECT_ID('tempdb..#OffersNotCheckedPreviously') IS NOT NULL DROP TABLE #OffersNotCheckedPreviously
	SELECT	DISTINCT
			[osd].[ItemID]
		,	[osd].[OfferType]
		,	StartDate
	INTO #OffersNotCheckedPreviously
	FROM #SSRS_V0002_FullSample_OfferSlotData_v2 osd
	INNER JOIN [Derived].[IronOffer] iof
		ON osd.ItemID = iof.IronOfferID
	WHERE NOT EXISTS (	SELECT 1
						FROM #OffersRan ls
						WHERE #OffersRan.[osd].ItemID = ls.ItemID
						AND #OffersRan.[osd].OfferType =	CASE
												WHEN ls.TypeID = 1 THEN 'Earn'
												ELSE 'Burn'
											END)


	UPDATE osd
	SET [osd].[OfferAge] = 'Existing - Not Checked'
	FROM #SSRS_V0002_FullSample_OfferSlotData_v2 osd
	INNER JOIN #OffersNotCheckedPreviously onc
		ON osd.ItemID = onc.ItemID
		AND osd.OfferType =onc.OfferType
	WHERE OfferAge = 'Existing'

/*******************************************************************************************************************************************
	5. Output for report
*******************************************************************************************************************************************/

	SELECT	[a].[Email]
		,	[a].[ClubSegment]
		,	[a].[OfferType]
		,	[a].[ItemID]
		,	[a].[OfferName]
		,	[a].[OfferStartDate]
		,	[a].[OfferEndDate]
		,	[a].[Slot]
		,	[a].[OfferSlot]
		,	[a].[OfferAge]
		,	[a].[OfferRank]
		,	[a].[OfferRankPerSegment]
		,	[a].[OfferColour]
		,	ROW_NUMBER() OVER (ORDER BY [a].[OfferRank_Sum] DESC, [a].[OfferRankPerSegment_Sum] DESC, [a].[FanID], [a].[OfferType] DESC, [a].[Slot]) AS ReportOrder
	FROM (	Select	#SSRS_V0002_FullSample_OfferSlotData_v2.[FanID]
				,	#SSRS_V0002_FullSample_OfferSlotData_v2.[Email]
				,	'All Customers' AS ClubSegment
				,	#SSRS_V0002_FullSample_OfferSlotData_v2.[OfferType]
				,	#SSRS_V0002_FullSample_OfferSlotData_v2.[ItemID]
				,	#SSRS_V0002_FullSample_OfferSlotData_v2.[OfferName]
				,	#SSRS_V0002_FullSample_OfferSlotData_v2.[OfferStartDate]
				,	#SSRS_V0002_FullSample_OfferSlotData_v2.[OfferEndDate]
				,	#SSRS_V0002_FullSample_OfferSlotData_v2.[Slot]
				,	CASE
						WHEN #SSRS_V0002_FullSample_OfferSlotData_v2.[Slot] = 1 THEN 'Hero'
						ELSE CONVERT(VARCHAR(1), #SSRS_V0002_FullSample_OfferSlotData_v2.[Slot] - 1)
					End AS OfferSlot
				,	CASE
						WHEN #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferAge] = 'Existing' THEN 'Existing'
						ELSE 'New'
					END AS OfferAge
				,	#SSRS_V0002_FullSample_OfferSlotData_v2.[OfferRank]
				,	#SSRS_V0002_FullSample_OfferSlotData_v2.[OfferRankPerSegment]
				,	CASE
						WHEN #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferAge] = 'New' AND #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferRank] = 1 THEN '#fffe00'
						WHEN #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferAge] = 'New' AND #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferRankPerSegment] = 1 THEN '#ffa500'
						WHEN #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferAge] = 'Existing - Not Checked' AND #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferRank] = 1 THEN '#00ff00'
						WHEN #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferAge] = 'Existing - Not Checked' AND #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferRankPerSegment] = 1 THEN '#00ffc0'
					END AS OfferColour
				,	ROW_NUMBER() OVER (ORDER BY #SSRS_V0002_FullSample_OfferSlotData_v2.[FanID], #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferType] DESC, #SSRS_V0002_FullSample_OfferSlotData_v2.[Slot]) as ReportOrder
				,	SUM(CASE
							WHEN #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferAge] = 'New' AND #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferRank] = 1 THEN 1
						END) OVER (PARTITION BY #SSRS_V0002_FullSample_OfferSlotData_v2.[Email]) AS OfferRank_Sum
				,	SUM(CASE
							WHEN #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferAge] = 'New' AND #SSRS_V0002_FullSample_OfferSlotData_v2.[OfferRankPerSegment] = 1 THEN 1
						END) OVER (PARTITION BY #SSRS_V0002_FullSample_OfferSlotData_v2.[Email]) as OfferRankPerSegment_Sum
			FROM #SSRS_V0002_FullSample_OfferSlotData_v2) a
	WHERE [a].[OfferType] = 'Earn'
	ORDER BY	ROW_NUMBER() OVER (ORDER BY [a].[OfferRank_Sum] DESC, [a].[OfferRankPerSegment_Sum] DESC, [a].[FanID], [a].[OfferType] DESC, [a].[Slot])
			,	[a].[OfferType] DESC
			,	[a].[Slot]

	UPDATE [Email].[NewsletterReporting]
	SET [Email].[NewsletterReporting].[ReportSent] = 1
	WHERE [Email].[NewsletterReporting].[ReportSent] = 0
	AND [Email].[NewsletterReporting].[ReportName] = 'SSRS_V0002_FullSample_OfferSlotData'
	AND [Email].[NewsletterReporting].[LionSendID] = @LSID
			   
END



