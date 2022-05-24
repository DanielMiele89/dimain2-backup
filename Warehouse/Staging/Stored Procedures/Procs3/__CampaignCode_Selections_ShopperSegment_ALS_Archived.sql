

CREATE PROCEDURE [Staging].[__CampaignCode_Selections_ShopperSegment_ALS_Archived] @RunType bit, @EmailDate varchar(30), @NewCampaign bit

AS
BEGIN

SET NOCOUNT ON

	Declare @Today datetime,
			@time DATETIME,
			@msg VARCHAR(2048),
			@RunID int, 
			@MaxID int,
			@Qry nvarchar(max)

	/******************************************************************		
			Get email campaigns for next email send 
	******************************************************************/

	If Object_ID('tempdb..#CampaignsToRun') IS NOT NULL DROP TABLE #CampaignsToRun
	Select *, ROW_NUMBER() OVER (ORDER BY case when PriorityFlag = 0 then 99 else PriorityFlag End asc, ID) [RunID]
	Into #CampaignsToRun
	from Warehouse.Staging.ROCShopperSegment_PreSelection_ALS
	Where EmailDate = @EmailDate
	and SelectionRun = 0
	and ReadyToRun = 1
	and NewCampaign = @NewCampaign
	--and PriorityFlag = @PriorityFlag
	Order by RunID, PriorityFlag


If @RunType = 1 or @RunType = 0
Begin

	Select * 
	from #CampaignsToRun
	Order by RunID, PriorityFlag

End

	/******************************************************************		
			Declare and set variables 
	******************************************************************/

If @RunType = 1
BEGIN

		Set		@Today = getdate()
		Set		@RunID = 1
		Select  @MaxID = Max(RunID) From #CampaignsToRun

		Declare		@PartnerID CHAR(4),
					@StartDate DATE, 
					@EndDate DATE,
					@MarketableByEmail bit,
					@PaymentMethodsAvailable VARCHAR(10),
					@OfferID VARCHAR(40),
					@Throttling varchar(200),
					@ClientServicesRef VARCHAR(10),
					@OutputTableName VARCHAR (100),
					@CampaignName VARCHAR (250),
					@SelectionDate VARCHAR(11),
					@DeDupeAgainstCampaigns VARCHAR(50),
					@NotIn_TableName1 VARCHAR(100),
					@NotIn_TableName2 VARCHAR(100),
					@NotIn_TableName3 VARCHAR(100),
					@NotIn_TableName4 VARCHAR(100),
					@MustBeIn_TableName1  VARCHAR(100),
					@MustBeIn_TableName2  VARCHAR(100),
					@MustBeIn_TableName3  VARCHAR(100),
					@MustBeIn_TableName4  VARCHAR(100),
					@Gender CHAR(1),
					@AgeRange VARCHAR(7),
					@CampaignID_Include CHAR(3),
					@CampaignID_Exclude CHAR(3),
					@DriveTimeMins CHAR(3),
					@LiveNearAnyStore BIT,
					@OutletSector CHAR(6), 
					@SocialClass VARCHAR(5),
					@SelectedInAnotherCampaign VARCHAR(20),
					@CampaignTypeID CHAR(1),
					@CustomerBaseOfferDate varchar(10),
					@RandomThrottle bit

		/******************************************************************		
				Begin loop 
		******************************************************************/

			While @RunID <= @MaxID 
			Begin
			
				If (Select Count(*) From #CampaignsToRun where RunID = @RunID) > 0
				Begin
					Set @PartnerID = (Select PartnerID from #CampaignsToRun where @RunID = RunID)
					Set	@StartDate = (Select StartDate from #CampaignsToRun where @RunID = RunID) 
					Set	@EndDate = (Select EndDate from #CampaignsToRun where @RunID = RunID)
					Set	@MarketableByEmail = (Select MarketableByEmail from #CampaignsToRun where @RunID = RunID)
					Set	@PaymentMethodsAvailable = (Select PaymentMethodsAvailable from #CampaignsToRun where @RunID = RunID)
					Set	@OfferID = (Select OfferID from #CampaignsToRun where @RunID = RunID)
					Set	@Throttling = (Select Throttling from #CampaignsToRun where @RunID = RunID)
					Set	@ClientServicesRef = (Select ClientServicesRef from #CampaignsToRun where @RunID = RunID)
					Set	@OutputTableName = (Select OutputTableName from #CampaignsToRun where @RunID = RunID)
					Set	@CampaignName = (Select CampaignName from #CampaignsToRun where @RunID = RunID)
					Set	@SelectionDate = (Select SelectionDate from #CampaignsToRun where @RunID = RunID)
					Set	@DeDupeAgainstCampaigns = (Select DeDupeAgainstCampaigns from #CampaignsToRun where @RunID = RunID)
					Set	@NotIn_TableName1 = (Select NotIn_TableName1 from #CampaignsToRun where @RunID = RunID)
					Set	@NotIn_TableName2 = (Select NotIn_TableName2 from #CampaignsToRun where @RunID = RunID)
					Set	@NotIn_TableName3 = (Select NotIn_TableName3 from #CampaignsToRun where @RunID = RunID)
					Set	@NotIn_TableName4 = (Select NotIn_TableName4 from #CampaignsToRun where @RunID = RunID)
					Set	@MustBeIn_TableName1 = (Select MustBeIn_TableName1 from #CampaignsToRun where @RunID = RunID)
					Set	@MustBeIn_TableName2 = (Select MustBeIn_TableName2 from #CampaignsToRun where @RunID = RunID)
					Set	@MustBeIn_TableName3 = (Select MustBeIn_TableName3 from #CampaignsToRun where @RunID = RunID)
					Set	@MustBeIn_TableName4 = (Select MustBeIn_TableName4 from #CampaignsToRun where @RunID = RunID)
					Set @Gender = (Select Gender From #CampaignsToRun where @RunID = RunID)
					Set @AgeRange = (Select AgeRange From #CampaignsToRun where @RunID = RunID)
					Set @CampaignID_Include = (Select CampaignID_Include From #CampaignsToRun where @RunID = RunID)
					Set @CampaignID_Exclude = (Select CampaignID_Exclude From #CampaignsToRun where @RunID = RunID)
					Set @DriveTimeMins = (Select DriveTimeMins From #CampaignsToRun where @RunID = RunID)
					Set @LiveNearAnyStore = (Select LiveNearAnyStore From #CampaignsToRun where @RunID = RunID)
					Set @OutletSector = (Select OutletSector From #CampaignsToRun where @RunID = RunID)
					Set @SocialClass = (Select SocialClass From #CampaignsToRun where @RunID = RunID)
					Set	@SelectedInAnotherCampaign = (Select SelectedInAnotherCampaign from #CampaignsToRun where @RunID = RunID)
					Set	@CampaignTypeID = (Select CampaignTypeID from #CampaignsToRun where @RunID = RunID)
					Set	@CustomerBaseOfferDate = (Select CustomerBaseOfferDate from #CampaignsToRun where @RunID = RunID)
					Set	@RandomThrottle = (Select RandomThrottle from #CampaignsToRun where @RunID = RunID)
				
					/******************************************************************		
							Exec ShopperSegment selections 
					******************************************************************/
	
					Exec [Staging].[CampaignCode_AutoGeneration_ROC_SS_V1_9_ALS_Loop] 
								@PartnerID 						 ,
								@StartDate  					 ,
								@EndDate 						 ,
								@MarketableByEmail 				 ,
								@PaymentMethodsAvailable 		 ,
								@OfferID 						 ,
								@Throttling 					 ,
								@ClientServicesRef 				 ,
								@OutputTableName  				 ,
								@CampaignName 					 ,
								@SelectionDate 					 ,
								@DeDupeAgainstCampaigns 		 ,
								@NotIn_TableName1 				 ,
								@NotIn_TableName2 				 ,
								@NotIn_TableName3 				 ,
								@NotIn_TableName4 				 ,
								@MustBeIn_TableName1 			 ,
								@MustBeIn_TableName2			 ,
								@MustBeIn_TableName3			 ,
								@MustBeIn_TableName4			 ,
								@Gender 						 ,
								@AgeRange 						 ,
								@CampaignID_Include 			 ,
								@CampaignID_Exclude 			 ,
								@DriveTimeMins 					 ,
								@LiveNearAnyStore 				 ,
								@OutletSector 					 ,
								@SocialClass 					 ,
								@SelectedInAnotherCampaign 		 ,
								@CampaignTypeID 				 ,
								@CustomerBaseOfferDate 			 ,
								@RandomThrottle
							
					/******************************************************************		
							Insert counts into Counts table 
					******************************************************************/
			
					Set @Qry = ''
			
					Set @Qry =
					'Insert Into Warehouse.Staging.ROCShopperSegment_SelectionCounts(EmailDate, OutputTableName, IronOfferID, CountSelected, RunDateTime, NewCampaign, ClientServicesRef)
					Select cast('''+@EmailDate+''' as date) EmailDate
						, '''+@OutputTableName+''' OutputTableName
						, x.OfferID as OfferID
						, x.NoOfCustomers as CountSelected
						, getdate() as RunDateTime
						, als.NewCampaign
						, '''+@ClientServicesRef+''' ClientServicesRef
					from (
						Select OfferID, count(*) NoOfCustomers
						from '+ @OutputTableName +'
					 	Group by OfferID
					) x
					Inner Join #CampaignsToRun c
						on c.RunID = '+ Cast(@RunID as varchar(4)) +'
					Inner join Warehouse.Staging.ROCShopperSegment_PreSelection_ALS als
						on c.ID = als.ID'					

					Exec sys.sp_executesql @Qry




			
					/******************************************************************		
							Update PreSelection table to show selection has run 
					******************************************************************/
						
					Update a
					Set SelectionRun = 1
					From #CampaignsToRun b
					Inner Join Warehouse.Staging.ROCShopperSegment_PreSelection_ALS a
					On a.ID = b.ID
					Where @RunID = b.RunID

					/******************************************************************		
							Show completion message for retailer
					******************************************************************/
			
					SELECT @msg = @OutputTableName + ' completed'
					EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
		
				End
				Set @RunID = @RunID + 1

			End
		
		/******************************************************************		
				Display all counts for all selections run with email date 
		******************************************************************/

		Select *
		from Warehouse.Staging.ROCShopperSegment_SelectionCounts
		Where EmailDate = @EmailDate
		Order by RunDateTime, EmailDate, OutputTableName, IronOfferID
	
	End

	SET NOCOUNT OFF

End