
Create Procedure [Staging].[__ROC_CampaignCode_ParameterInsert_ALS_V4_Archived] (
			@EmailDate date,
			@PartnerID CHAR(4),
			@StartDate DATE, 
			@EndDate DATE,
			@2WeekFirstCycle bit,
			@NonCoreBaseOffer bit,
			@MarketableByEmail bit,
			@PaymentMethodsAvailable VARCHAR(10),
			@LaunchOfferID varchar(40),
			@OfferID VARCHAR(40),
			@Throttling varchar(200),
			@ClientServicesRef VARCHAR(10),
			@OutputTableName VARCHAR (100),
			@CampaignName VARCHAR (250),
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
			@CustomerBaseOfferDate date,
			@RandomThrottle bit,
			@PriorityFlag int,
			@PredictedCardholderVolumes varchar(50),
			@BriefLocation varchar(250)
			)
as 
begin

--Declare @NoOfCycles int 
----=  datediff(WEEK, @StartDate, @EndDate)/4

--If @NonCoreBaseOffer = 1  
--	 set @NoOfCycles = 1 
--	 else set @NoOfCycles = datediff(WEEK, @StartDate, @EndDate)/4

Declare @DaysToAdd int 
Set @DaysToAdd = case 
					when @2WeekFirstCycle = 1 then 13
					Else 27
				End

;WITH ssDates
    AS
    (
	   SELECT	--1 as CycleNo,
				cast(@EmailDate as date)as EmailDate,
				cast(@StartDate as date) StartDate, 
				cast(Dateadd(dd, @DaysToAdd, @StartDate) as date) EndDate,
				cast(case 
					when @LaunchOfferID <> '' then @LaunchOfferID +','+@LaunchOfferID +','+@LaunchOfferID +','+SUBSTRING(@OfferID,(3*CHARINDEX(',',@OfferID,1)+1),CHARINDEX(',',@OfferID,1)-1)+',00000,00000'
					Else @OfferID
				End as varchar(40)) as OfferID ,
				cast(@Throttling as varchar(200)) Throttling,
				cast(null as date) CustomerBaseOfferDate,
				dateadd(day, -3, cast(@StartDate as date)) SelectionDate,
				cast(@MustBeIn_TableName1 as varchar(100)) MustBeIn_TableName1,
				cast(@RandomThrottle as bit) RandomThrottle,
				1 as NewCampaign
	   UNION ALL
	   SELECT	--CycleNo + 1 as CycleNo,
				DateAdd(day, 1, EndDate) EmailDate,
				DateAdd(day, 1, EndDate) StartDate, 
				DATEADD(day, 28, EndDate) EndDate,
				@OfferID OfferID,
				cast('0,0,0,0,0,0' as varchar(200)) Throttling,
				StartDate CustomerBaseOfferDate,
				dateadd(week, -3, cast(StartDate as date)) SelectionDate,
				Cast('' as varchar(100))as MustBeIn_TableName1,
				cast(1 as bit) as RandomThrottle,
				0 as NewCampaign

	   FROM ssDates
	   WHERE EndDate < @EndDate --CycleNo < @NoOfCycles
    )

Insert into Warehouse.Staging.ROCShopperSegment_PreSelection_ALS (
			EmailDate,
			PartnerID,
			StartDate,
			EndDate,
			MarketableByEmail,
			PaymentMethodsAvailable,
			OfferID,
			Throttling,
			ClientServicesRef,
			OutputTableName,
			CampaignName,
			SelectionDate,
			DeDupeAgainstCampaigns,
			NotIn_TableName1,
			NotIn_TableName2,
			NotIn_TableName3,
			NotIn_TableName4,
			MustBeIn_TableName1,
			MustBeIn_TableName2,
			MustBeIn_TableName3,
			MustBeIn_TableName4,
			Gender,
			AgeRange,
			CampaignID_Include,
			CampaignID_Exclude,
			DriveTimeMins,
			LiveNearAnyStore,
			OutletSector,
			SocialClass,
			SelectedInAnotherCampaign,
			CampaignTypeID,
			CustomerBaseOfferDate,
			ReadyToRun,
			SelectionRun,
			RandomThrottle,
			PriorityFlag,
			NewCampaign,
			PredictedCardholderVolumes,
			BriefLocation)

Select		x.EmailDate, 
			@PartnerID, 
			x.StartDate, 
			case 
				when @NonCoreBaseOffer = 1 then @EndDate
				Else x.EndDate
			End, 
			@MarketableByEmail,
			@PaymentMethodsAvailable,
			x.OfferID,
			case
				When @NonCoreBaseOffer = 1 then @Throttling
				Else x.Throttling
			End,
			@ClientServicesRef,
			@OutputTableName,
			@CampaignName,
			x.SelectionDate,
			@DeDupeAgainstCampaigns,
			@NotIn_TableName1,
			@NotIn_TableName2,
			@NotIn_TableName3,
			@NotIn_TableName4,
			x.MustBeIn_TableName1,
			@MustBeIn_TableName2,
			@MustBeIn_TableName3,
			@MustBeIn_TableName4,
			@Gender,
			@AgeRange,
			@CampaignID_Include,
			@CampaignID_Exclude,
			@DriveTimeMins,
			@LiveNearAnyStore,
			@OutletSector,
			@SocialClass,
			@SelectedInAnotherCampaign,
			@CampaignTypeID,
			x.CustomerBaseOfferDate,
			0,
			0,
			x.RandomThrottle,
			@PriorityFlag,
			x.NewCampaign,
			@PredictedCardholderVolumes,
			@BriefLocation
From ssDates x

END