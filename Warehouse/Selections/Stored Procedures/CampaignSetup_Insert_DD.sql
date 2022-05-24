
CREATE PROCEDURE [Selections].[CampaignSetup_Insert_DD] (@EmailDate DATE
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
													  
													  , @CampaignTypeID INT)
As 
Begin

--Declare @EmailDate DATE = '2019-01-31'							
--	  , @PartnerID INT = '4432'								
--	  , @StartDate DATE = '2019-01-31'							
--	  , @EndDate DATE = '2019-07-17'								
--	  , @CampaignName VARCHAR(250) = 'TEST'					
--	  , @ClientServicesRef VARCHAR(250) = 'CT999'			
--	  , @NonCoreBaseOffer BIT = '0'						
--	  , @LaunchOfferID INT = ''							
--	  , @OfferID VARCHAR(250) = '16299,00000,00000,00000,00000,00000'						
--	  , @PriorityFlag INT = '1'							
--	  , @PredictedCardholderVolumes VARCHAR(250) = '3480908,0,0,0,0,0'	
--	  , @Throttling VARCHAR(250) = '0,0,0,0,0,0'					
--	  , @RandomThrottle BIT = '0'						
--	  , @MarketableByEmail BIT = ''						
--	  , @Gender VARCHAR(250) = ''						
--	  , @AgeRange VARCHAR(250) = ''						
--	  , @DriveTimeMins INT = ''							
--	  , @LiveNearAnyStore BIT = ''						
--	  , @SocialClass VARCHAR(250) = ''					
--	  , @OutletSector VARCHAR(250) = ''					
--	  , @CustomerBaseOfferDate DATE = ''				
--	  , @SelectedInAnotherCampaign VARCHAR(250) = ''	
--	  , @DeDupeAgainstCampaigns VARCHAR(250) = ''		
--	  , @CampaignID_Include INT = ''					
--	  , @CampaignID_Exclude INT = ''					
--	  , @sProcPreSelection VARCHAR(250) = ''			
--	  , @OutputTableName VARCHAR(250) = 'Warehouse.Selections.CT042_Selection_Script_1'				
--	  , @NotIn_TableName1 VARCHAR(250) = ''				
--	  , @NotIn_TableName2 VARCHAR(250) = ''				
--	  , @NotIn_TableName3 VARCHAR(250) = ''				
--	  , @NotIn_TableName4 VARCHAR(250) = ''				
--	  , @MustBeIn_TableName1 VARCHAR(250) = ''			
--	  , @MustBeIn_TableName2 VARCHAR(250) = ''			
--	  , @MustBeIn_TableName3 VARCHAR(250) = ''			
--	  , @MustBeIn_TableName4 VARCHAR(250) = ''			
--	  , @BriefLocation VARCHAR(250) = 'S:\AM\5 - ROC Campaign Brief and Forecasts\Campaign Briefs\Charles Tyrwhitt\2019\Briefs\CT042- RBS Acquire Jan19.xlsx'				
--	  , @CampaignCycleLength INT = '4'					
--	  , @BespokeCampaign BIT = '0'						
	  				
--	  , @2WeekCycles BIT = '0'							
--	  , @CampaignIncludesWelcome BIT = '0'

	DECLARE @DaysToAdd INT = CASE 
								WHEN @2WeekCycles = 1 THEN 0
								WHEN NOT EXISTS (SELECT 1 FROM Relational.ROC_CycleDates Where StartDate = @StartDate) THEN 27
								ELSE 27
							 END;

	With
	ssDates as (
				Select @EmailDate as EmailDate
					 , @StartDate as StartDate
					 , DateAdd(dd, @DaysToAdd, @StartDate) as EndDate
					 , Convert(VARCHAR(250),
						Case
							When @LaunchOfferID != 0 And @LaunchOfferID != '' Then CONVERT(VARCHAR(6), @LaunchOfferID) + ',' +CONVERT(VARCHAR(6), @LaunchOfferID) + ',' + CONVERT(VARCHAR(6), @LaunchOfferID) + ',' + SUBSTRING(@OfferID, (3*CHARINDEX(',', @OfferID, 1) +1 ), CHARINDEX(',', @OfferID, 1) - 1) + ',00000,00000'
							Else @OfferID
						End) as OfferID
					 , @Throttling as Throttling
					 , CONVERT(DATE, NULL) as CustomerBaseOfferDate
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
					 , Convert(VARCHAR(250),'0,0,0,0,0,0') as Throttling
					 , StartDate as CustomerBaseOfferDate
					 , Convert(Varchar(250), '') as MustBeIn_TableName1
					 , Convert(Bit, 1) as RandomThrottle
					 , 0 as NewCampaign
				From ssDates
				Where EndDate < @EndDate)


Insert into Selections.CampaignSetup_DD (EmailDate
									   , PartnerID
									   , StartDate
									   , EndDate
									   , CampaignName
									   , ClientServicesRef
									   , OfferID
									   , PriorityFlag
									   , PredictedCardholderVolumes
									   , Throttling
									   , RandomThrottle
									   , MarketableByEmail
									   , Gender
									   , AgeRange
									   , DriveTimeMins
									   , LiveNearAnyStore
									   , SocialClass
									   , OutletSector
									   , CustomerBaseOfferDate
									   , SelectedInAnotherCampaign
									   , DeDupeAgainstCampaigns
									   , CampaignID_Include
									   , CampaignID_Exclude
									   , sProcPreSelection
									   , OutputTableName
									   , NotIn_TableName1
									   , NotIn_TableName2
									   , NotIn_TableName3
									   , NotIn_TableName4
									   , MustBeIn_TableName1
									   , MustBeIn_TableName2
									   , MustBeIn_TableName3
									   , MustBeIn_TableName4
									   , BriefLocation
									   , CampaignCycleLength_Weeks
									   , NewCampaign
									   , BespokeCampaign
									   , CampaignTypeID
									   , ReadyToRun
									   , SelectionRun
									   , ControlGroupPercentage)

	Select EmailDate
		 , @PartnerID as PartnerID
		 , StartDate
		 , Case 
	  			When @NonCoreBaseOffer = 1 then @EndDate
	  			Else EndDate
		   End as EndDate
		 , @CampaignName as CampaignName
		 , @ClientServicesRef as ClientServicesRef 
		 , OfferID
		 , @PriorityFlag as PriorityFlag
		 , @PredictedCardholderVolumes as PredictedCardholderVolumes
		 , Case
	  			When @NonCoreBaseOffer = 1 then @Throttling
	 			Else Throttling
		   End Throttling
		 , RandomThrottle
		 , @MarketableByEmail as MarketableByEmail
		 , Case
	  			When EmailDate = @EmailDate Or @CampaignIncludesWelcome = 1 Then @Gender
	 			Else ''
		   End as Gender
		 , Case
	  			When EmailDate = @EmailDate Or @CampaignIncludesWelcome = 1 Then @AgeRange
	 			Else ''
		   End as AgeRange
		 , @DriveTimeMins as DriveTimeMins
		 , @LiveNearAnyStore as LiveNearAnyStore
		 , @SocialClass as SocialClass
		 , @OutletSector as OutletSector
		 , CustomerBaseOfferDate
		 , Case
	  			When EmailDate = @EmailDate Then @SelectedInAnotherCampaign
	 			Else ''
		   End as SelectedInAnotherCampaign
		 , Case
	  			When EmailDate = @EmailDate Then @DeDupeAgainstCampaigns
	 			Else ''
		   End as DeDupeAgainstCampaigns
		 , Case
				When @CampaignID_Include = 0 Then ''
				Else @CampaignID_Include
		   End as CampaignID_Include
		 , Case
				When @CampaignID_Exclude = 0 Then ''
				Else @CampaignID_Exclude
		   End as CampaignID_Exclude
		 , Case
	  			When EmailDate = @EmailDate Then @sProcPreSelection
	 			Else ''
		   End as sProcPreSelection
		 , @OutputTableName as OutputTableName
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
		 , @BriefLocation as BriefLocation
		 , @CampaignCycleLength
		 , NewCampaign
		 , @BespokeCampaign
		 , @CampaignTypeID
		 , 0 as ReadyToRun
		 , 0 as SelectionRun
		 , 0
	From ssDates
	WHERE NOT EXISTS (	SELECT 1
						FROM [Selections].[CampaignSetup_DD] als
						WHERE als.ClientServicesRef = @ClientServicesRef)

End