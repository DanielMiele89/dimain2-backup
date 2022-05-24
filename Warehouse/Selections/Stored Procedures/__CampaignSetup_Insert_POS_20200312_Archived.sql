
CREATE PROCEDURE [Selections].[__CampaignSetup_Insert_POS_20200312_Archived] (@EmailDate DATE
													   , @PartnerID INT
													   , @StartDate DATE
													   , @EndDate DATE
													   , @CampaignName VARCHAR(250)
													   , @ClientServicesRef VARCHAR(250)
													   , @NonCoreBaseOffer BIT
													   , @LaunchOfferID VARCHAR(250)
													   , @OfferID VARCHAR(250)
													   , @PriorityFlag INT
													   , @PredictedCardholderVolumes VARCHAR(250)
													   , @Throttling VARCHAR(250)
													   , @RandomThrottle BIT
													   , @MarketableByEmail VARCHAR(25)
													   , @Gender VARCHAR(250)
													   , @AgeRange VARCHAR(250)
													   , @DriveTimeMins VARCHAR(25)
													   , @LiveNearAnyStore BIT
													   , @SocialClass VARCHAR(250)
													   , @OutletSector VARCHAR(250)
													   , @CustomerBaseOfferDate DATE
													   , @SelectedInAnotherCampaign VARCHAR(250)
													   , @DeDupeAgainstCampaigns VARCHAR(250)
													   , @CampaignID_Include VARCHAR(25)
													   , @CampaignID_Exclude VARCHAR(25)
													   , @sProcPreSelection VARCHAR(250)
													   , @OutputTableName VARCHAR(250)
													   , @NotIn_TableName1 VARCHAR(250)
													   , @NotIn_TableName2 VARCHAR(250)
													   , @NotIn_TableName3 VARCHAR(250)
													   , @NotIn_TableName4 VARCHAR(250)
													   , @MustBeIn_TableName1 VARCHAR(250)
													   , @MustBeIn_TableName2 VARCHAR(250)
													   , @MustBeIn_TableName3 VARCHAR(250)
													   , @MustBeIn_TableName4 VARCHAR(250)
													   , @BriefLocation VARCHAR(250)
													   , @CampaignCycleLength INT
													   , @BespokeCampaign BIT
													   
													   , @2WeekCycles BIT
													   , @CampaignIncludesWelcome BIT
													   
													   , @PaymentMethodsAvailable VARCHAR(250)
													   , @CampaignTypeID INT)
As 
Begin

	DECLARE @DaysToAdd INT = CASE 
								WHEN @2WeekCycles = 1 THEN 13
								WHEN NOT EXISTS (SELECT 1 FROM Relational.ROC_CycleDates Where StartDate = @StartDate) THEN 13
								ELSE 27
							 END;

	With
	ssDates as (
				Select @EmailDate as EmailDate
					 , @StartDate as StartDate
					 , DateAdd(dd, @DaysToAdd, @StartDate) as EndDate
					 , Convert(Varchar(250),
							Case
								When @LaunchOfferID != 0 And @LaunchOfferID != '' Then @LaunchOfferID + ',' +@LaunchOfferID + ',' + @LaunchOfferID + ',' + SUBSTRING(@OfferID, (3*CHARINDEX(',', @OfferID, 1) +1 ), CHARINDEX(',', @OfferID, 1) - 1) + ',00000,00000'
								Else @OfferID
							End) as OfferID
					 , @Throttling as Throttling
					 , CONVERT(DATE, NULL) as CustomerBaseOfferDate
					 , Convert(Date, DateAdd(day, -3, @StartDate)) as SelectionDate
					 , @MustBeIn_TableName1 as MustBeIn_TableName1
					 , @RandomThrottle as RandomThrottle
					 , 1 as NewCampaign
				Union all
				Select DateAdd(day, 1, EndDate) as EmailDate
					 , DateAdd(day, 1, EndDate) as StartDate
					 , Case
							When @2WeekCycles = 1 Then DateAdd(day, 14, EndDate)
							When DateAdd(day, 28, EndDate) > @EndDate Then DateAdd(day, 14, EndDate)
							Else DateAdd(day, 28, EndDate)
					   End as EndDate
					 , @OfferID as OfferID
					 , Convert(Varchar(250), '0,0,0,0,0,0') as Throttling
					 , StartDate as CustomerBaseOfferDate
					 , DateAdd(day, -2, Convert(Date, EndDate)) SelectionDate
					 , Convert(Varchar(250), '') as MustBeIn_TableName1
					 , Convert(Bit, 1) as RandomThrottle
					 , 0 as NewCampaign
				From ssDates
				Where EndDate < @EndDate)
			
	Insert into Warehouse.Selections.ROCShopperSegment_PreSelection_ALS ( EmailDate
																		, PartnerID
																		, StartDate
																		, EndDate
																		, MarketableByEmail
																		, PaymentMethodsAvailable
																		, OfferID
																		, Throttling
																		, ClientServicesRef
																		, OutputTableName
																		, CampaignName
																		, SelectionDate
																		, DeDupeAgainstCampaigns
																		, NotIn_TableName1
																		, NotIn_TableName2
																		, NotIn_TableName3
																		, NotIn_TableName4
																		, MustBeIn_TableName1
																		, MustBeIn_TableName2
																		, MustBeIn_TableName3
																		, MustBeIn_TableName4
																		, Gender
																		, AgeRange
																		, CampaignID_Include
																		, CampaignID_Exclude
																		, DriveTimeMins
																		, LiveNearAnyStore
																		, OutletSector
																		, SocialClass
																		, SelectedInAnotherCampaign
																		, CampaignTypeID
																		, CustomerBaseOfferDate
																		, ReadyToRun
																		, SelectionRun
																		, RandomThrottle
																		, PriorityFlag
																		, NewCampaign
																		, PredictedCardholderVolumes
																		, BriefLocation
																		, sProcPreSelection
																		, CampaignCycleLength
																		, BespokeCampaign
																		, FreqStretch_TransCount
																		, ControlGroupPercentage)

	Select EmailDate
		 , @PartnerID as PartnerID
		 , StartDate
		 , Case 
	  			When @NonCoreBaseOffer = 1 then @EndDate
	  			Else EndDate
		   End as EndDate
		 , @MarketableByEmail as MarketableByEmail
		 , @PaymentMethodsAvailable as PaymentMethodsAvailable
		 , OfferID
		 , Case
	  			When @NonCoreBaseOffer = 1 then @Throttling
	 			Else Throttling
		   End Throttling
		 , @ClientServicesRef as ClientServicesRef 
		 , @OutputTableName as OutputTableName
		 , @CampaignName as CampaignName
		 , SelectionDate
		 , Case
	  			When EmailDate = @EmailDate Then @DeDupeAgainstCampaigns
	 			Else ''
		   End as DeDupeAgainstCampaigns
		 , Case
	  			When EmailDate = @EmailDate Then @NotIn_TableName1
	 			Else ''
		   End as NotIn_TableName1
		 , Case
	  			When EmailDate = @EmailDate Then @NotIn_TableName2
	 			Else ''
		   End as NotIn_TableName2
		 , Case
	  			When EmailDate = @EmailDate Then @NotIn_TableName3
	 			Else ''
		   End as NotIn_TableName3
		 , Case
	  			When EmailDate = @EmailDate Then @NotIn_TableName4
	 			Else ''
		   End as NotIn_TableName4
		 , Case
	  			When EmailDate = @EmailDate Then @MustBeIn_TableName1
	 			Else ''
		   End as MustBeIn_TableName1
		 , Case
	  			When EmailDate = @EmailDate Then @MustBeIn_TableName2
				When @PartnerID = 4514 Then @MustBeIn_TableName2
	 			Else ''
		   End as MustBeIn_TableName2
		 , Case
	  			When EmailDate = @EmailDate Then @MustBeIn_TableName3
	 			Else ''
		   End as MustBeIn_TableName3
		 , Case
	  			When EmailDate = @EmailDate Then @MustBeIn_TableName4
	 			Else ''
		   End as MustBeIn_TableName4
		   
		 , Case
	  			When EmailDate = @EmailDate Or @CampaignIncludesWelcome = 1 Then @Gender
	 			Else ''
		   End as Gender
		 , Case
	  			When EmailDate = @EmailDate Or @CampaignIncludesWelcome = 1 Then @AgeRange
	 			Else ''
		   End as AgeRange
		 , @CampaignID_Include as CampaignID_Include
		 , @CampaignID_Exclude as CampaignID_Exclude
		 , @DriveTimeMins as DriveTimeMins
		 , @LiveNearAnyStore as LiveNearAnyStore
		 , @OutletSector as OutletSector
		 , @SocialClass as SocialClass
		 , Case
	  			When EmailDate = @EmailDate Then @SelectedInAnotherCampaign
	 			Else ''
		   End as SelectedInAnotherCampaign
		 , @CampaignTypeID as CampaignTypeID
		 , CustomerBaseOfferDate
		 , 0 as ReadyToRun
		 , 0 as SelectionRun
		 , RandomThrottle
		 , @PriorityFlag as PriorityFlag
		 , NewCampaign
		 , @PredictedCardholderVolumes as PredictedCardholderVolumes
		 , @BriefLocation as BriefLocation
		 , Case
	  			When EmailDate = @EmailDate Then @sProcPreSelection
	 			Else ''
		   End as sProcPreSelection
		 , @CampaignCycleLength
		 , @BespokeCampaign
		 , 0
		 , 0
	From ssDates

End