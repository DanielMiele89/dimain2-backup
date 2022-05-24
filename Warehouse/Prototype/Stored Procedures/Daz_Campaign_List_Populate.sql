-- =============================================
-- Author:		Shaun H.
-- Create date: 25th June 2019
-- Description:	Identify, and append the IronOfferIDs and Offers associated with the Campaign you wish to profile
-- =============================================

CREATE PROCEDURE Prototype.Daz_Campaign_List_Populate
	-- Add the parameters for the stored procedure here
	@PartnerID INT,
	@StartDate DATE = NULL,
	@EndDate DATE = NULL,
	@IronOfferIDs VARCHAR(1000) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/*
	  Note:
	  Users must supply:
	    PartnerID
		One of the options below

	  Users can supply:
	    - StartDate and EndDate - script will identify all IronOfferIDs associated with those dates, and the provided partner
		- IronOfferID - script will identify the IronOfferID and find the corresponding dates for the IronOffer @ the provided partner
		- StartDate, EndDate and IronOfferID - script will subset the identified IronOfferIDs to those specifically listed
	*/

	-- Test rig
	--DECLARE @PartnerID INT = 4263
	--DECLARE @StartDate DATE = '2019-06-06'
	--DECLARE @EndDate DATE = '2019-06-19'
	--DECLARE @IronOfferIDs VARCHAR(1000) = NULL	--'17070'
	
	DECLARE @time DATETIME
	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign List - Start', @time OUTPUT

	IF @StartDate IS NOT NULL
	  BEGIN
		IF @EndDate IS NULL
		  BEGIN
			PRINT 'If you supply StartDate, you must supply EndDate'
		  END
		ELSE
		  BEGIN
			IF @IronOfferIDs IS NOT NULL
			  BEGIN
				PRINT 'You have supplied StartDate, EndDate and IronOfferIDs for profiling purposes'
			  END
			ELSE
			  BEGIN
				PRINT 'You have supplied StartDate and EndDate for profiling purposes'
			  END
		  END
	  END
	ELSE
	  BEGIN
		IF @IronOfferIDs IS NOT NULL
		  BEGIN
			PRINT 'You have supplied IronOfferIDs for profiling purposes'
		  END
		ELSE
		  BEGIN
			PRINT 'You have not supplied anything to profile'
			RETURN
		  END
	  END 

	-- Filter IronOffers to those we are interested in
	IF OBJECT_ID('tempdb..#IronOffers') IS NOT NULL DROP TABLE #IronOffers
	CREATE TABLE #IronOffers
	  (
		IronOfferID INT,
		IronOfferName NVARCHAR(200),
		StartDate DATE,
		EndDate DATE,
		PartnerID INT
	  )

	IF (@StartDate IS NOT NULL) AND (@IronOfferIDs IS NOT NULL)
	  BEGIN
		INSERT INTO #IronOffers
		  SELECT
			io.ID AS IronOfferID,
			io.Name AS IronOfferName,
			io.StartDate,
			io.EndDate,
			io.PartnerID
		  FROM SLC_Report.dbo.IronOffer io
		  LEFT JOIN	Warehouse.Relational.IronOffer ior
			ON io.ID = ior.IronOfferID
		  WHERE io.PartnerID = @PartnerID
			AND (io.StartDate = @StartDate AND CHARINDEX(',' + CAST(io.ID AS VARCHAR) + ',', ',' + @IronOfferIDs + ',') > 0)
			AND ior.IronOfferID IS NOT NULL -- RBS ONLY OFFERS
	  END
	ELSE
	  BEGIN
		INSERT INTO #IronOffers
   		  SELECT
   			io.ID AS IronOfferID,
   			io.Name AS IronOfferName,
   			io.StartDate,
   			io.EndDate,
   			io.PartnerID
   		  FROM SLC_Report.dbo.IronOffer io
   		  LEFT JOIN	Warehouse.Relational.IronOffer ior
   			ON io.ID = ior.IronOfferID
   		  WHERE io.PartnerID = @PartnerID
   			AND (io.StartDate = @StartDate OR CHARINDEX(',' + CAST(io.ID AS VARCHAR) + ',', ',' + @IronOfferIDs + ',') > 0)
   			AND ior.IronOfferID IS NOT NULL -- RBS ONLY OFFERS
	  END
 
	CREATE CLUSTERED INDEX cix_IronOfferID ON #IronOffers (IronOfferID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - IronOffer Details Gathered', @time OUTPUT

	IF (@StartDate IS NULL OR @EndDate IS NULL)
	  BEGIN
		SELECT
		  @StartDate = MIN(StartDate),
		  @EndDate = MAX(EndDate)
		FROM #IronOffers
	  END

	IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
	SELECT
	  io.IronOfferID,
	  io.IronOfferName,
	  CAST(io.StartDate AS DATE) AS StartDate,
	  CAST(io.EndDate AS DATE) AS EndDate,
	  io.PartnerID,
	  COALESCE(pcrb.CommissionRate,pcrnb.CommissionRate) AS BelowThresholdRate,
	  COALESCE(pcr.MinimumBasketSize,pcrn.MinimumBasketSize) AS MinimumBasketSize,
	  COALESCE(pcr.CommissionRate,pcrn.CommissionRate) AS AboveThresholdRate
	INTO #Offers
	FROM #IronOffers io
	LEFT JOIN  (
			SELECT	*
			FROM	[Warehouse].[Relational].[IronOffer_PartnerCommissionRule]
			WHERE	MinimumBasketSize IS NOT NULL
				AND	TypeID = 1
				AND	DeletionDate IS NULL
			) pcr 
		ON io.IronOfferID = pcr.IronOfferID
	LEFT JOIN  (
			SELECT	*
			FROM	[Warehouse].[Relational].[IronOffer_PartnerCommissionRule]
			WHERE	MinimumBasketSize IS NULL
				AND	TypeID = 1
				AND	DeletionDate IS NULL
			) pcrb 
		ON io.IronOfferID = pcrb.IronOfferID
	LEFT JOIN  (
			SELECT	*
			FROM	[NFI].[Relational].[IronOffer_PartnerCommissionRule]
			WHERE	MinimumBasketSize IS NOT NULL
				AND	TypeID = 1
				AND	DeletionDate IS NULL
			) pcrn
		ON io.IronOfferID = pcrn.IronOfferID
	LEFT JOIN  (
			SELECT	*
			FROM	[NFI].[Relational].[IronOffer_PartnerCommissionRule]
			WHERE	MinimumBasketSize IS NULL
				AND	TypeID = 1
				AND	DeletionDate IS NULL
			) pcrnb 
		ON io.IronOfferID = pcrnb.IronOfferID

	CREATE CLUSTERED INDEX cix_IronOfferID ON #Offers (IronOfferID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - Offer Details Gathered', @time OUTPUT

	-- Capture your subsequent processing requirements
	INSERT INTO Warehouse.Prototype.Daz_Campaign_List
		SELECT	a.*,
				GETDATE() AS ProcessingTime,
				COALESCE(MaxCampaignID,0) + 1 AS CampaignID
		FROM	#Offers a
		CROSS JOIN (SELECT MAX(CampaignID) AS MaxCampaignID FROM Warehouse.Prototype.Daz_Campaign_List) b

	ALTER INDEX cix_IronOfferID ON Warehouse.Prototype.Daz_Campaign_List REBUILD
	ALTER INDEX nix_IronOfferID_CampaignID ON Warehouse.Prototype.Daz_Campaign_List REBUILD


	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign List - End', @time OUTPUT

	/*
	-- Clear all previous entries
	TRUNCATE TABLE Warehouse.Prototype.Daz_Campaign_List

	-- Delete specfic collection of entries
	DELETE FROM Warehouse.Prototype.Daz_Campaign_List WHERE CampaignID = 1

	-- Recreate Table
	IF OBJECT_ID('Warehouse.Prototype.Daz_Campaign_List') IS NOT NULL DROP TABLE Warehouse.Prototype.Daz_Campaign_List
	CREATE TABLE Warehouse.Prototype.Daz_Campaign_List
		(
			IronOfferID INT,
			IronOfferName VARCHAR(100),
			StartDate DATE,
			EndDate DATE,
			PartnerID INT,
			BelowThresholdRate INT,
			MinimumBasketSize INT,
			AboveThresholdRate INT,
			ProcessingTime DATETIME,
			CampaignID INT
		)

	CREATE CLUSTERED INDEX cix_IronOfferID ON Warehouse.Prototype.Daz_Campaign_List (IronOfferID)
	CREATE NONCLUSTERED INDEX nix_IronOfferID_CampaignID ON Warehouse.Prototype.Daz_Campaign_List (IronOfferID) INCLUDE (CampaignID)

	*/
END