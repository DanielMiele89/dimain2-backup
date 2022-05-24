

CREATE PROCEDURE [Staging].[__CampaignCode_Selections_ShopperSegment_Archived] @EmailDate varchar(30), @CampaignsToRun varchar(250)

AS 
BEGIN

SET NOCOUNT ON

Declare @Today datetime,
		@time DATETIME,
		@msg VARCHAR(2048),
		@RunID int, 
		@MaxID int,
		@Qry nvarchar(max),
		@Campaigns varchar(250)

set @Campaigns = (select '''' + replace(@CampaignsToRun, ',', ''',''') + '''')


	/******************************************************************		
			Get email campaigns for next email send 
	******************************************************************/

	If Object_ID('tempdb..#CampaignsToRun') is not null drop table #CampaignsToRun
	Create Table #CampaignsToRun (	ID int, 
									PartnerID CHAR(4),
									StartDate DATE, 
									EndDate DATE,
									MarketableByEmail bit,
									PaymentMethodsAvailable VARCHAR(10),
									OfferID VARCHAR(40),
									Throttling varchar(200),
									ClientServicesRef VARCHAR(10),
									OutputTableName VARCHAR (100),
									CampaignName VARCHAR (250),
									SelectionDate VARCHAR(11),
									DeDupeAgainstCampaigns VARCHAR(50),
									NotIn_TableName1 VARCHAR(100),
									NotIn_TableName2 VARCHAR(100),
									NotIn_TableName3 VARCHAR(100),
									NotIn_TableName4 VARCHAR(100),
									SelectedInAnotherCampaign VARCHAR(20),
									CampaignTypeID CHAR(1),
									CoreSpendersToPrime CHAR(1),
									CustomerBaseOfferDate varchar(10))

	set @Qry = '
	Insert Into #CampaignsToRun
	Select	ID
			,PartnerID
			,StartDate  
			,EndDate 
			,MarketableByEmail
			,PaymentMethodsAvailable 
			,OfferID 
			,Throttling 
			,ClientServicesRef 
			,OutputTableName 
			,CampaignName 
			,SelectionDate 
			,DeDupeAgainstCampaigns 
			,NotIn_TableName1 
			,NotIn_TableName2 
			,NotIn_TableName3 
			,NotIn_TableName4
			,SelectedInAnotherCampaign 
			,CampaignTypeID 
			,CoreSpendersToPrime 
			,CustomerBaseOfferDate 
	from Warehouse.Staging.ROCShopperSegment_PreSelection
	Where EmailDate = '''+ @EmailDate+ '''
	and SelectionRun = 0
	and ClientServicesRef in (' +@Campaigns+ ')'

	Exec sys.sp_executesql @Qry

	Create CLUSTERED index cix_ID_CampaignsToRun on #CampaignsToRun(ID)

	/******************************************************************		
			Declare and set variables 
	******************************************************************/

	Set		@Today = getdate()
	Set		@RunID = 1
	Select  @MaxID = Max(ID) From #CampaignsToRun


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
				--@MustBeIn_TableName1  VARCHAR(100),
				@SelectedInAnotherCampaign VARCHAR(20),
				@CampaignTypeID CHAR(1),
				@CoreSpendersToPrime CHAR(1),
				@CustomerBaseOfferDate varchar(10)

	/******************************************************************		
			Begin loop 
	******************************************************************/

	While @RunID <= @MaxID 
	Begin
			
		If (Select Count(*) From #CampaignsToRun where id = @RunID) > 0
		Begin
			Set @PartnerID = (Select PartnerID from #CampaignsToRun where @RunID = ID)
			Set	@StartDate = (Select StartDate from #CampaignsToRun where @RunID = ID) 
			Set	@EndDate = (Select EndDate from #CampaignsToRun where @RunID = ID)
			Set	@MarketableByEmail = (Select MarketableByEmail from #CampaignsToRun where @RunID = ID)
			Set	@PaymentMethodsAvailable = (Select PaymentMethodsAvailable from #CampaignsToRun where @RunID = ID)
			Set	@OfferID = (Select OfferID from #CampaignsToRun where @RunID = ID)
			Set	@Throttling = (Select Throttling from #CampaignsToRun where @RunID = ID)
			Set	@ClientServicesRef = (Select ClientServicesRef from #CampaignsToRun where @RunID = ID)
			Set	@OutputTableName = (Select OutputTableName from #CampaignsToRun where @RunID = ID)
			Set	@CampaignName = (Select CampaignName from #CampaignsToRun where @RunID = ID)
			Set	@SelectionDate = (Select SelectionDate from #CampaignsToRun where @RunID = ID)
			Set	@DeDupeAgainstCampaigns = (Select DeDupeAgainstCampaigns from #CampaignsToRun where @RunID = ID)
			Set	@NotIn_TableName1 = (Select NotIn_TableName1 from #CampaignsToRun where @RunID = ID)
			Set	@NotIn_TableName2 = (Select NotIn_TableName2 from #CampaignsToRun where @RunID = ID)
			Set	@NotIn_TableName3 = (Select NotIn_TableName3 from #CampaignsToRun where @RunID = ID)
			Set	@NotIn_TableName4 = (Select NotIn_TableName4 from #CampaignsToRun where @RunID = ID)
			Set	@SelectedInAnotherCampaign = (Select SelectedInAnotherCampaign from #CampaignsToRun where @RunID = ID)
			Set	@CampaignTypeID = (Select CampaignTypeID from #CampaignsToRun where @RunID = ID)
			Set	@CoreSpendersToPrime = (Select CoreSpendersToPrime from #CampaignsToRun where @RunID = ID)
			Set	@CustomerBaseOfferDate = (Select CustomerBaseOfferDate from #CampaignsToRun where @RunID = ID)
			

			/******************************************************************		
				Exec ShopperSegment selections 
			******************************************************************/

			Exec [Staging].[CampaignCode_AutoGeneration_ROC_SS_V1_7_Loop] 
						@PartnerID,
						@StartDate , 
						@EndDate ,
						@MarketableByEmail ,
						@PaymentMethodsAvailable ,
						@OfferID ,
						@Throttling ,
						@ClientServicesRef ,
						@OutputTableName  ,
						@CampaignName  ,
						@SelectionDate ,
						@DeDupeAgainstCampaigns ,
						@NotIn_TableName1 ,
						@NotIn_TableName2,
						@NotIn_TableName3,
						@NotIn_TableName4 ,
						@SelectedInAnotherCampaign,
						@CampaignTypeID ,
						@CoreSpendersToPrime ,
						@CustomerBaseOfferDate 

			/******************************************************************		
					Insert counts into Counts table 
			******************************************************************/

			Set @Qry = ''
			Set @Qry = 'Insert into Warehouse.Staging.ROCShopperSegment_SelectionCounts
						Select cast( '''+ @EmailDate +''' as date) [EmailDate], '''+ @OutputTableName +''', x.OfferID, x.NoOfCustomers, getdate() as RunDateTime
						from (Select OfferID, count(*) NoOfCustomers
								from '+ @OutputTableName +'
								Group by OfferID) x
						order by RunDateTime desc'
			
			Exec sys.sp_executesql @Qry

			/******************************************************************		
					Update PreSelection table to show selection has run 
			******************************************************************/
						
			Update Warehouse.Staging.ROCShopperSegment_PreSelection
			Set SelectionRun = 1
			Where ID = @RunID

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

SET NOCOUNT OFF

END