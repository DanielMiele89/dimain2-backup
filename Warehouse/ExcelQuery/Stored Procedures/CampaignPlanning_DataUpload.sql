
/*=================================================================================================
Campaign Planning Procedures
Part 1: Data Upload
Version 2: P.Lovell 17/12/2015
=================================================================================================*/


CREATE PROCEDURE [ExcelQuery].[CampaignPlanning_DataUpload]
(								@PartnerName			as		VARCHAR(150)
								,@ClientServicesRef		as		VARCHAR(25)  --client services ref
								--,@PartnerID					INT	NOT NULL --partnerid
								,@CampaignName			as		VARCHAR(150) 
								,@CampaignType			as		VARCHAR(25)
								,@MainObjective			as		VARCHAR(50)
								,@Budget				as		NUMERIC(32,8)
								,@MarketingSupport		as		VARCHAR(20)
								,@EmailTesting			as		BIT 
								,@CustomerBaseID		as		INT
								,@BirthdayType			as		VARCHAR(50)
								,@ATL					as		BIT
							--	,@RetailerType			as		VARCHAR(40)
							--	,@Override_rate			as		Numeric(7,4)
							--	,@baserate				as		Numeric(7,4)

								--specific cs reference goes here?
								,@startdate				as		DATE--camapign start date from s/sheet
								,@enddate				as		DATE--campaign end date from s/sheet
								,@HTMID					as		TINYINT
								,@CompetitorShopper4wk	as		BIT
								,@Homemover				as		BIT	
								,@Lapser				as		BIT
								,@Student				as		BIT
								,@AcquireMember			as		BIT
								,@SuperSegmentID		as		TINYINT
								,@Gender				as		VARCHAR(1)
								,@MinAge				as		INT
								,@MaxAge				as		INT
								,@DriveTimeband			as		VARCHAR(50)
								,@CAMEO_CODE_GRP		as		VARCHAR(200)
								,@SocialClass			as		NVARCHAR(2)
								,@MinHeatMapScore		as		INT
								,@MaxHeatMapScore		as		INT
								,@BespokeTargeting		as		INT
								,@QualifyingMids		as		INT
								,@OfferRate				as		Numeric(7,4)
								,@SpendThreshold		as		MONEY
								,@AB_Split				as		Numeric(32,2) 
								,@control_share			as		DECIMAL(3,2) 
								,@noncorebo_csref		as		VARCHAR(20)
								,@Activerow				as		BIT
								,@Uplift				as		DECIMAL(5,4)
								)

AS
BEGIN
	SET NOCOUNT ON;

Declare @fixdate DATE
SET @fixdate = GetDate()

INSERT INTO warehouse.staging.CampaignPlanningTool_CampaignInput ([PartnerID]
      ,[PartnerName]
      ,[ClientServicesRef]
      ,[CampaignName]
      ,[CampaignType]
      ,[MainObjective]
      ,[Budget]
      ,[MarketingSupport]
      ,[EmailTesting]
      ,[CustomerBaseID]
      ,[BirthdayType]
      ,[ATL]
      ,[RetailerType]
      ,[ControlGroup_Size]
	  ,Status_StartDate
	  )

Select b.partnerid
		,@PartnerName
		,@ClientServicesRef
		,@CampaignName
		,@CampaignType
		,@MainObjective
		,@Budget
		,@MarketingSupport
		,@EmailTesting
		,@CustomerBaseID
		,@BirthdayType
		,@atl
		,CASE WHEN b.RetailerTypeID = 0 THEN 'Core'
						WHEN b.RetailerTypeID = 1 THEN 'Non-Core'
						WHEN b.RetailerTypeID = 2 THEN 'STO'
						ELSE NULL END
		,@control_share
		,@fixdate

FROM warehouse.staging.CampaignPlanning_Brand as b with (NOLOCK) 
INNER JOIN warehouse.relational.Partner as p with (NOLOCK)
	ON b.PartnerID = p.PartnerID AND p.PartnerName=@PartnerName



INSERT INTO warehouse.staging.CampaignPlanningTool_CampaignSegment (
      [ClientServicesRef]
	  ,[startdate]
      ,[enddate]
      ,[HTMID]
      ,[CompetitorShopper4wk]
      ,[Homemover]
      ,[Lapser]
      ,[Student]
      ,[AcquireMember]
      ,[SuperSegmentID]
      ,[Gender]
      ,[MinAge]
      ,[MaxAge]
      ,[DriveTimeband]
      ,[CAMEO_CODE_GRP]
      ,[SocialClass]
      ,[MinHeatMapScore]
      ,[MaxHeatMapScore]
      ,[BespokeTargeting]
      ,[QualifyingMids]
      ,[OfferRate]
      ,[SpendThreshold]
      ,[AB_Split]
      ,[uplift]
      ,[noncorebo_csref]
      ,[ActiveRow]
	  ,Status_StartDate
	  )


SELECT @ClientServicesRef					
	   ,@startdate				 --specific cs reference 
	   ,@enddate				
	   ,@HTMID					
	   ,@CompetitorShopper4wk	
	   ,@Homemover				
	   ,@Lapser				
	   ,@Student				
	   ,@AcquireMember			
	   ,@SuperSegmentID		
	   ,@Gender				
	   ,@MinAge				
	   ,@MaxAge				
	   ,@DriveTimeband			
	   ,@CAMEO_CODE_GRP		
	   ,@SocialClass			
	   ,@MinHeatMapScore		
	   ,@MaxHeatMapScore		
	   ,@BespokeTargeting		
	   ,@QualifyingMids		
	   ,@OfferRate				
	   ,@SpendThreshold		
	   ,@AB_Split				
	   ,@Uplift
	   ,@noncorebo_csref	
	   ,@Activerow	
	   ,@fixdate


INSERT INTO warehouse.ExcelQuery.CampaignPlanning_Calculations (ID)
SELECT ID
FROM warehouse.staging.CampaignPlanningTool_CampaignSegment
where  [ClientServicesRef] =			@ClientServicesRef
	  AND [startdate] =					@startdate
      AND [enddate] =					@enddate
      AND [HTMID] =						@HTMID
      AND [CompetitorShopper4wk] =		@CompetitorShopper4wk
      AND [Homemover] =					@Homemover
      AND [Lapser] =					@Lapser
      AND [Student] =					@Student
      AND [AcquireMember] =				@AcquireMember
      AND [SuperSegmentID] =			@SuperSegmentID
      AND [Gender] =					@Gender
      AND [MinAge] =					@MinAge
      AND [MaxAge] =					@MaxAge
      AND [DriveTimeband] =				@DriveTimeband
      AND [CAMEO_CODE_GRP] =			@CAMEO_CODE_GRP
      AND [SocialClass] =				@socialclass
      AND [MinHeatMapScore] =			@minheatmapscore
      AND [MaxHeatMapScore] =			@maxheatmapscore	
      AND [BespokeTargeting] =			@bespoketargeting
      AND [QualifyingMids] =			@qualifyingMids
      AND [OfferRate] =					@OfferRate
      AND [SpendThreshold] =			@SpendThreshold
      AND [AB_Split] =					@AB_Split
      AND [uplift] =					@Uplift
      AND [noncorebo_csref] =			@noncorebo_csref 
      AND [ActiveRow] =					@Activerow
	  AND Status_StartDate =			@fixdate
;

--Select the IDs to pass back to Excel
SELECT ID
FROM warehouse.staging.CampaignPlanningTool_CampaignSegment
where  [ClientServicesRef] =			@ClientServicesRef
	  AND [startdate] =					@startdate
      AND [enddate] =					@enddate
      AND [HTMID] =						@HTMID
      AND [CompetitorShopper4wk] =		@CompetitorShopper4wk
      AND [Homemover] =					@Homemover
      AND [Lapser] =					@Lapser
      AND [Student] =					@Student
      AND [AcquireMember] =				@AcquireMember
      AND [SuperSegmentID] =			@SuperSegmentID
      AND [Gender] =					@Gender
      AND [MinAge] =					@MinAge
      AND [MaxAge] =					@MaxAge
      AND [DriveTimeband] =				@DriveTimeband
      AND [CAMEO_CODE_GRP] =			@CAMEO_CODE_GRP
      AND [SocialClass] =				@socialclass
      AND [MinHeatMapScore] =			@minheatmapscore
      AND [MaxHeatMapScore] =			@maxheatmapscore	
      AND [BespokeTargeting] =			@bespoketargeting
      AND [QualifyingMids] =			@qualifyingMids
      AND [OfferRate] =					@OfferRate
      AND [SpendThreshold] =			@SpendThreshold
      AND [AB_Split] =					@AB_Split
      AND [uplift] =					@Uplift
      AND [noncorebo_csref] =			@noncorebo_csref 
      AND [ActiveRow] =					@Activerow
	  AND Status_StartDate =			@fixdate


END
;