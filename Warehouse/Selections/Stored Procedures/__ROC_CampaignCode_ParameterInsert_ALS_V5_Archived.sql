
CREATE Procedure [Selections].[__ROC_CampaignCode_ParameterInsert_ALS_V5_Archived] (@EmailDate Date
																	  , @PartnerID Char(4)
																	  , @StartDate Date
																	  , @EndDate Date
																	  , @2WeekFirstCycle Bit
																	  , @NonCoreBaseOffer Bit
																	  , @MarketableByEmail Bit
																	  , @PaymentMethodsAvailable Varchar(10)
																	  , @LaunchOfferID Varchar(40)
																	  , @OfferID Varchar(40)
																	  , @Throttling Varchar(200)
																	  , @ClientServicesRef Varchar(10)
																	  , @OutputTableName Varchar (100)
																	  , @CampaignName Varchar (250)
																	  , @DeDupeAgainstCampaigns Varchar(50)
																	  , @NotIn_TableName1 Varchar(100)
																	  , @NotIn_TableName2 Varchar(100)
																	  , @NotIn_TableName3 Varchar(100)
																	  , @NotIn_TableName4 Varchar(100)
																	  , @MustBeIn_TableName1 Varchar(100)
																	  , @MustBeIn_TableName2 Varchar(100)
																	  , @MustBeIn_TableName3 Varchar(100)
																	  , @MustBeIn_TableName4 Varchar(100)
																	  , @Gender Char(1)
																	  , @AgeRange Varchar(7)
																	  , @CampaignID_Include Char(3)
																	  , @CampaignID_Exclude Char(3)
																	  , @DriveTimeMins Char(3)
																	  , @LiveNearAnyStore Bit
																	  , @OutletSector Char(6)
																	  , @SocialClass Varchar(5)
																	  , @SelectedInAnotherCampaign Varchar(20)
																	  , @CampaignTypeID Char(1)
																	  , @CustomerBaseOfferDate Date
																	  , @RandomThrottle Bit
																	  , @PriorityFlag Int
																	  , @PredictedCardholderVolumes Varchar(50)
																	  , @BriefLocation Varchar(250)
																	  , @sProcPreSelection Varchar(150)
																	  , @2WeekCycles Bit
																	  , @CampaignIncludesWelcome Bit
																	  , @CampaignCycleLength Int
																	  , @BespokeCampaign Bit)
As 
Begin

	Declare @DaysToAdd int
	Set @DaysToAdd = Case 
						When @2WeekFirstCycle = 0 and @2WeekCycles = 0 then 27
						Else 13
					End;


	With
	ssDates as (
				Select Convert(Date, @EmailDate) as EmailDate
					 , Convert(Date, @StartDate) as StartDate
					 , Convert(Date, DateAdd(dd, @DaysToAdd, @StartDate)) as EndDate
					 , Convert(Varchar(40),
							Case
								When @LaunchOfferID <> '' Then @LaunchOfferID + ',' +@LaunchOfferID + ',' + @LaunchOfferID + ',' + SUBSTRING(@OfferID, (3*CHARINDEX(',', @OfferID, 1) +1 ), CHARINDEX(',', @OfferID, 1) - 1) + ',00000,00000'
								Else @OfferID
							End) as OfferID
					 , Convert(Varchar(200), @Throttling) as Throttling
					 , Convert(Date, null) as CustomerBaseOfferDate
					 , Convert(Date, DateAdd(day, -3, @StartDate)) as SelectionDate
					 , Convert(Varchar(100), @MustBeIn_TableName1) as MustBeIn_TableName1
					 , Convert(Bit, @RandomThrottle) as RandomThrottle
					 , 1 as NewCampaign
				Union all
				Select DateAdd(day, 1, EndDate) as EmailDate
					 , DateAdd(day, 1, EndDate) as StartDate
					 , Case
							When @2WeekCycles = 1 Then DateAdd(day, 14, EndDate)
							Else DateAdd(day, 28, EndDate)
					   End as EndDate
					 , @OfferID as OfferID
					 , Convert(Varchar(200), '0,0,0,0,0,0') as Throttling
					 , StartDate as CustomerBaseOfferDate
					 , DateAdd(day, -2, Convert(Date, EndDate)) SelectionDate
					 , Convert(Varchar(100), '') as MustBeIn_TableName1
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
																		, BespokeCampaign)

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
	From ssDates

End










