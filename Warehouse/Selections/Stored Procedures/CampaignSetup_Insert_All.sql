
CREATE PROCEDURE [Selections].[CampaignSetup_Insert_All] (	@EmailDate DATE
														,	@PartnerID INT
														,	@StartDate DATE
														,	@EndDate DATE
														,	@CampaignName VARCHAR(250)
														,	@ClientServicesRef VARCHAR(250)
														,	@LaunchOfferID VARCHAR(250)
														,	@OfferID VARCHAR(250)
														,	@PriorityFlag INT
														,	@PredictedCardholderVolumes VARCHAR(250)
														,	@Throttling VARCHAR(250)
														,	@ThrottleType VARCHAR(10)
														,	@RandomThrottle BIT
														,	@GSBB VARCHAR(23)
														,	@MarketableByEmail VARCHAR(25)
														,	@PaymentMethodsAvailable VARCHAR(250)
														,	@Gender VARCHAR(250)
														,	@AgeRange VARCHAR(250)
														,	@DriveTimeMins VARCHAR(25)
														,	@LiveNearAnyStore BIT
														,	@SocialClass VARCHAR(250)
														,	@FreqStretch_TransCount INT
														,	@CustomerBaseOfferDate DATE
														,	@SelectedInAnotherCampaign VARCHAR(250)
														,	@DeDupeAgainstCampaigns VARCHAR(250)
														,	@CampaignID_Include VARCHAR(25)
														,	@CampaignID_Exclude VARCHAR(25)
														,	@ControlGroupPercentage FLOAT
														,	@sProcPreSelection VARCHAR(250)
														,	@OutputTableName VARCHAR(250)
														,	@NotIn_TableName1 VARCHAR(250)
														,	@NotIn_TableName2 VARCHAR(250)
														,	@NotIn_TableName3 VARCHAR(250)
														,	@NotIn_TableName4 VARCHAR(250)
														,	@MustBeIn_TableName1 VARCHAR(250)
														,	@MustBeIn_TableName2 VARCHAR(250)
														,	@MustBeIn_TableName3 VARCHAR(250)
														,	@MustBeIn_TableName4 VARCHAR(250)
														,	@BriefLocation VARCHAR(250)
														,	@CampaignCycleLength INT
														,	@BespokeCampaign BIT

														,	@2WeekCycles BIT
														,	@Publisher VARCHAR(25)
														,	@IsDirectDebit BIT
														)
AS 
BEGIN

	DECLARE @DaysToAdd INT = CASE 
								WHEN @2WeekCycles = 1 THEN 13
								WHEN NOT EXISTS (SELECT 1 FROM [Relational].[ROC_CycleDates] WHERE StartDate = @StartDate) THEN 13
								ELSE 27
							 END;

	;WITH
	ssDates AS (SELECT	CONVERT(VARCHAR(250),	CASE
													WHEN @LaunchOfferID != 0 And @LaunchOfferID != '' THEN @LaunchOfferID + ',' +@LaunchOfferID + ',' + @LaunchOfferID + ',' + SUBSTRING(@OfferID, (3*CHARINDEX(',', @OfferID, 1) +1 ), CHARINDEX(',', @OfferID, 1) - 1) + ',00000,00000'
													ELSE @OfferID
												END) AS OfferID
					,	@EmailDate AS EmailDate
					,	@StartDate AS StartDate
					,	DATEADD(dd, @DaysToAdd, @StartDate) AS EndDate
					,	CONVERT(DATE, NULL) AS CustomerBaseOfferDate
					,	@Throttling AS Throttling
					,	CONVERT(INT, @ControlGroupPercentage) AS ControlGroupPercentage
					,	1 AS NewCampaign
				UNION ALL
				SELECT	@OfferID AS OfferID
					,	DATEADD(day, 1, EndDate) AS EmailDate
					,	DATEADD(day, 1, EndDate) AS StartDate
					,	CASE
							WHEN @2WeekCycles = 1 THEN DATEADD(day, 14, EndDate)
							WHEN DATEADD(day, 28, EndDate) > @EndDate THEN DATEADD(day, 14, EndDate)
							ELSE DATEADD(day, 28, EndDate)
						END AS EndDate
					,	StartDate AS CustomerBaseOfferDate
					,	CONVERT(VARCHAR(250), '0,0,0,0,0,0') AS Throttling
					,	CONVERT(INT, 0) AS ControlGroupPercentage
					,	0 AS NewCampaign
				FROM ssDates
				WHERE EndDate < @EndDate)
			
	SELECT	EmailDate
		,	@PartnerID AS PartnerID
		,	StartDate
		,	EndDate
		,	@CampaignName AS CampaignName
		,	@ClientServicesRef AS ClientServicesRef
		,	OfferID
		,	@PriorityFlag AS PriorityFlag
		,	@PredictedCardholderVolumes AS PredictedCardholderVolumes
		,	Throttling
		,	@ThrottleType AS ThrottleType
		,	@RandomThrottle AS RandomThrottle
		,	@GSBB AS GSBB
		,	@MarketableByEmail AS MarketableByEmail
		,	@PaymentMethodsAvailable AS PaymentMethodsAvailable
		,	@Gender AS Gender
		,	@AgeRange AS AgeRange
		,	@DriveTimeMins AS DriveTimeMins
		,	@LiveNearAnyStore AS LiveNearAnyStore
		,	@SocialClass AS SocialClass
		,	@FreqStretch_TransCount AS FreqStretch_TransCount
		,	CustomerBaseOfferDate
		,	@SelectedInAnotherCampaign AS SelectedInAnotherCampaign
		,	@DeDupeAgainstCampaigns AS DeDupeAgainstCampaigns
		,	@CampaignID_Include AS CampaignID_Include
		,	@CampaignID_Exclude AS CampaignID_Exclude
		,	ControlGroupPercentage
		,	@sProcPreSelection AS sProcPreSelection
		,	@OutputTableName AS OutputTableName
		,	@NotIn_TableName1 AS NotIn_TableName1
		,	@NotIn_TableName2 AS NotIn_TableName2
		,	@NotIn_TableName3 AS NotIn_TableName3
		,	@NotIn_TableName4 AS NotIn_TableName4
		,	@MustBeIn_TableName1 AS MustBeIn_TableName1
		,	@MustBeIn_TableName2 AS MustBeIn_TableName2
		,	@MustBeIn_TableName3 AS MustBeIn_TableName3
		,	@MustBeIn_TableName4 AS MustBeIn_TableName4
		,	@BriefLocation AS BriefLocation
		,	@CampaignCycleLength AS CampaignCycleLength_Weeks
		,	NewCampaign
		,	@BespokeCampaign AS BespokeCampaign
		,	0 AS ReadyToRun
		,	0 AS SelectionRun
	INTO #CampaignSetup
	FROM ssDates s

	DECLARE @Query VARCHAR(MAX)
		,	@DestinationTable VARCHAR(150)

	SET @DestinationTable = CASE
								WHEN @Publisher = 'MyRewards' AND @IsDirectDebit = 0 THEN '[Warehouse].[Selections].[CampaignSetup_POS]'
								WHEN @Publisher = 'MyRewards' AND @IsDirectDebit = 1 THEN '[Warehouse].[Selections].[CampaignSetup_DD]'
								WHEN @Publisher = 'Virgin Money VGLC' AND @IsDirectDebit = 0 THEN '[WH_Virgin].[Selections].[CampaignSetup_POS]'
								WHEN @Publisher = 'Virgin Money VGLC' AND @IsDirectDebit = 1 THEN '[WH_Virgin].[Selections].[CampaignSetup_DD]'
								WHEN @Publisher = 'Visa Barclaycard' AND @IsDirectDebit = 0 THEN '[WH_Visa].[Selections].[CampaignSetup_POS]'
								WHEN @Publisher = 'Visa Barclaycard' AND @IsDirectDebit = 1 THEN '[WH_Visa].[Selections].[CampaignSetup_DD]'
							END


	SET @Query = '
	INSERT INTO ' + @DestinationTable + ' ( [EmailDate]
										,	[PartnerID]
										,	[StartDate]
										,	[EndDate]
										,	[CampaignName]
										,	[ClientServicesRef]
										,	[OfferID]
										,	[PriorityFlag]
										,	[PredictedCardholderVolumes]
										,	[Throttling]
										,	[ThrottleType]
										,	[RandomThrottle]
										,	[GSBB]
										,	[MarketableByEmail]
										,	[PaymentMethodsAvailable]
										,	[Gender]
										,	[AgeRange]
										,	[DriveTimeMins]
										,	[LiveNearAnyStore]
										,	[SocialClass]
										,	[FreqStretch_TransCount]
										,	[CustomerBaseOfferDate]
										,	[SelectedInAnotherCampaign]
										,	[DeDupeAgainstCampaigns]
										,	[CampaignID_Include]
										,	[CampaignID_Exclude]
										,	[ControlGroupPercentage]
										,	[sProcPreSelection]
										,	[OutputTableName]
										,	[NotIn_TableName1]
										,	[NotIn_TableName2]
										,	[NotIn_TableName3]
										,	[NotIn_TableName4]
										,	[MustBeIn_TableName1]
										,	[MustBeIn_TableName2]
										,	[MustBeIn_TableName3]
										,	[MustBeIn_TableName4]
										,	[BriefLocation]
										,	[CampaignCycleLength_Weeks]
										,	[NewCampaign]
										,	[BespokeCampaign]
										,	[ReadyToRun]
										,	[SelectionRun])
	SELECT *
	FROM #CampaignSetup cs
	WHERE NOT EXISTS (	SELECT 1
						FROM ' + @DestinationTable + ' c
						WHERE cs.ClientServicesRef = c.ClientServicesRef
						AND cs.EmailDate = c.EmailDate
						AND cs.OfferID = c.OfferID)
	ORDER BY EmailDate'

	EXEC(@Query)

END