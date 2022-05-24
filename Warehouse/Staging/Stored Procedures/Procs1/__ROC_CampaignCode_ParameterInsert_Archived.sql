
CREATE Procedure [Staging].[__ROC_CampaignCode_ParameterInsert_Archived] (
			@EmailDate date,
			@PartnerID CHAR(4),
			@StartDate DATE, 
			@EndDate DATE,
			@2WeekFirstCycle bit,
			@NonCoreBaseOffer bit,
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
			@CustomerBaseOfferDate date
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
				cast(@Throttling as varchar(200)) Throttling,
				cast(null as date) CustomerBaseOfferDate,
				cast(@SelectionDate as date) SelectionDate
	   UNION ALL
	   SELECT	--CycleNo + 1 as CycleNo,
				DateAdd(day, 1, EndDate) EmailDate,
				DateAdd(day, 1, EndDate) StartDate, 
				DATEADD(day, 28, EndDate) EndDate,
				cast('0,0,0,0,0,0' as varchar(200)) Throttling,
				StartDate CustomerBaseOfferDate,
				dateadd(week, 4, cast(SelectionDate as date)) SelectionDate
	   FROM ssDates
	   WHERE EndDate < @EndDate
    )

Insert into Warehouse.Staging.ROCShopperSegment_PreSelection (
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
			--MustBeIn_TableName1,
			SelectedInAnotherCampaign,
			CampaignTypeID,
			CoreSpendersToPrime,
			CustomerBaseOfferDate,
			SelectionRun)

Select		x.EmailDate, 
			@PartnerID, 
			x.StartDate, 
			case 
				when @NonCoreBaseOffer = 1 then @EndDate
				Else x.EndDate
			End, 
			@MarketableByEmail,
			@PaymentMethodsAvailable,
			@OfferID,
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
		--	@MustBeIn_TableName1,
			@SelectedInAnotherCampaign,
			@CampaignTypeID,
			@CoreSpendersToPrime,
			x.CustomerBaseOfferDate,
			0 
From ssDates x

END




