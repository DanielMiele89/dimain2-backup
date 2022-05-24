

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 13/11/2014
-- Description: Create data tables for SSRS Report to report on OPE performance
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0055_ReportingOPEPerformance_LoadDataTables] (
			@StartDate Date,
			@EndDate Date
			)
			
AS
BEGIN
	SET NOCOUNT ON;


--DECLARE	@StartDate DATE,
--	@EndDate DATE

--SET @StartDate = '06 Nov 2014'
--SET @EndDate = '07 Nov 2014'

/*********************************************************
**********Finding Campaigns for Dates Specified***********
*********************************************************/
IF OBJECT_ID ('Warehouse.Staging.R_0055_Campaigns') IS NOT NULL DROP TABLE Warehouse.Staging.R_0055_Campaigns
SELECT	ROW_NUMBER() OVER(ORDER BY LionSendID) as RowNo,
	LionSendID,
	SendDate,
	NewOfferRange
INTO Warehouse.Staging.R_0055_Campaigns
FROM	(
	SELECT	DISTINCT 
		LionSendID,
		CAST(ec.SendDate AS DATE) as SendDate,
		DATEADD(DD,-2,SendDate) as NewOfferRange

	FROM Warehouse.Relational.EmailCampaign ec
	INNER JOIN Warehouse.Relational.CampaignLionSendIDs cls
		ON ec.CampaignKey = cls.CampaignKey
	WHERE CAST(ec.SendDate AS DATE) BETWEEN @StartDate AND @EndDate
	)a

CREATE CLUSTERED INDEX IDX_LS ON Warehouse.Staging.R_0055_Campaigns (LionSendID)


/*********************************************************
*****Finding Number Of People Selected in Weeks Email*****
*********************************************************/
IF OBJECT_ID ('Warehouse.Staging.R_0055_FansSelected') IS NOT NULL DROP TABLE Warehouse.Staging.R_0055_FansSelected
CREATE TABLE Warehouse.Staging.R_0055_FansSelected
	(
	LionSendRowNo INT NOT NULL,
	FanID INT NOT NULL,
	CompositeID BIGINT NOT NULL,
	LionSendID INT NOT NULL
	)
	
/******************************************************************
**********************Declare the variables************************
******************************************************************/
DECLARE @StartRow INT,
	@LionSendID INT,
	@MaxLionSendID INT
	
SET @StartRow = 1
SET @LionSendID = (SELECT LionSendID FROM Warehouse.Staging.R_0055_Campaigns WHERE RowNo = 1)
SET @MaxLionSendID = (SELECT MAX(LionSendID) FROM Warehouse.Staging.R_0055_Campaigns)


WHILE  @LionSendID <= @MaxLionSendID
BEGIN

	DECLARE @Fan INT,
		@MaxFan INT,
		@Chunksize INT

	SET @Fan = (SELECT MIN([Customer ID]) FROM Warehouse.Relational.SFD_PostUploadAssessmentData WHERE LionSendID = @LionSendID)
	SET @MaxFan = (SELECT MAX([Customer ID]) FROM Warehouse.Relational.SFD_PostUploadAssessmentData WHERE LionSendID = @LionSendID)
	SET @Chunksize = 500000

	WHILE @Fan < @MaxFan
	
	BEGIN 

		INSERT INTO Warehouse.Staging.R_0055_FansSelected
		SELECT	TOP
			(@Chunksize)
			ROW_NUMBER() OVER(PARTITION BY sfd.LionSendID ORDER BY sfd.[Customer ID]) as LionSendRowNo,
			sfd.[Customer ID] as FanID,
			c.CompositeID,
			sfd.LionSendID
		FROM Warehouse.Relational.SFD_PostUploadAssessmentData sfd
		INNER JOIN Warehouse.Staging.R_0055_Campaigns ca
			ON sfd.LionSendID = ca.LionSendID
		INNER JOIN Warehouse.Relational.Customer c
			ON sfd.[Customer ID] = c.FanID
		WHERE	NOT (sfd.CJS = 'M3' AND WeekNumber = 2) -- Exclude MOT3 Week 2 from all results
			AND sfd.LionSendID = @LionSendID
			AND sfd.[Customer ID] >= @Fan
		ORDER BY sfd.[Customer ID]

	SET @Fan = (SELECT MAX(FanID) FROM Warehouse.Staging.R_0055_FansSelected WHERE LionSendID = @LionSendID)+1

	END

SET @StartRow = @StartRow+1
SET @LionSendID = (SELECT LionSendID FROM Warehouse.Staging.R_0055_Campaigns WHERE RowNo = @StartRow)

END

CREATE NONCLUSTERED INDEX IDX_FanID ON Warehouse.Staging.R_0055_FansSelected (FanID)
CREATE NONCLUSTERED INDEX IDX_LS ON Warehouse.Staging.R_0055_FansSelected (LionSendID)
CREATE NONCLUSTERED INDEX IDX_Comp ON Warehouse.Staging.R_0055_FansSelected (CompositeID)


/*********************************************************
**************Creating Partner Tier Table*****************
*********************************************************/
IF OBJECT_ID ('Warehouse.Staging.R_0055_PartnerTier') IS NOT NULL DROP TABLE Warehouse.Staging.R_0055_PartnerTier
SELECT	p.PartnerID,
	CASE
		WHEN Tier = 1 THEN 'Gold'
		WHEN Tier = 2 THEN 'Silver'
		WHEN Tier = 3 THEN 'Bronze'
		WHEN mrt.PartnerID IS NULL AND p.PartnerID NOT IN (4433,4447,4498,4497,4488,4453) THEN 'POC Only'
		ELSE 'RBS Funded'
	END as RetailerTier
INTO Warehouse.Staging.R_0055_PartnerTier
FROM Warehouse.Relational.Partner p
LEFT OUTER JOIN Warehouse.Relational.Master_Retailer_Table mrt
	ON p.PartnerID = mrt.PartnerID

/*********************************************************
*******Finding New IronOffers going Live that week********
*********************************************************/
IF OBJECT_ID ('Warehouse.Staging.R_0055_NewOffers') IS NOT NULL DROP TABLE Warehouse.Staging.R_0055_NewOffers
SELECT	DISTINCT
	LionSendID,
	i.StartDate,
	io.IronOfferID
INTO Warehouse.Staging.R_0055_NewOffers
FROM Warehouse.Relational.IronOffer i
INNER JOIN Warehouse.Relational.IronOffer_Campaign_HTM io
	ON i.IronOfferID = io.IronOfferID
INNER JOIN Warehouse.Staging.R_0055_Campaigns c
	ON i.StartDate BETWEEN c.NewOfferRange AND c.SendDate

--SELECT	*
--FROM Warehouse.Staging.R_0055_NewOffers


/**************************************************************
********Finding the number of offers trimmed Prep Table********
**************************************************************/
IF OBJECT_ID ('Warehouse.Staging.R_0055_FansWithOver7') IS NOT NULL DROP TABLE Warehouse.Staging.R_0055_FansWithOver7
SELECT	LionSendID,
	FanID,
	CompositeID
INTO Warehouse.Staging.R_0055_FansWithOver7
FROM	(
	SELECT	fs.CompositeID,
		fs.FanID,
		fs.LionSendID,
		COUNT(iom.IronOfferID) as [Count]
	FROM Warehouse.Staging.R_0055_FansSelected fs
	INNER JOIN Warehouse.Relational.IronOfferMember iom
		ON fs.CompositeID = iom.CompositeID
	INNER JOIN Warehouse.Staging.R_0055_NewOffers no
		ON iom.IronOfferID = no.IronOfferID
		AND fs.LionSendID = no.LionSendID
	GROUP BY fs.CompositeID, fs.FanID, fs.LionSendID
	HAVING COUNT(iom.IronOfferID) > 7
	)a

IF OBJECT_ID ('Warehouse.Staging.R_0055_IronOffersOver7') IS NOT NULL DROP TABLE Warehouse.Staging.R_0055_IronOffersOver7
SELECT	fo.FanID,
	fo.LionSendID,
	iom.IronOfferID
INTO Warehouse.Staging.R_0055_IronOffersOver7
FROM Warehouse.Staging.R_0055_FansWithOver7 fo
INNER JOIN Warehouse.Relational.IronOfferMember iom
		ON fo.CompositeID = iom.CompositeID
INNER JOIN Warehouse.Staging.R_0055_NewOffers no
	ON iom.IronOfferID = no.IronOfferID
	AND fo.LionSendID = no.LionSendID



/****************************************************************
********************Slot In-Filling Prep Table*******************
*****************************************************************/
--**
IF OBJECT_ID ('Warehouse.Staging.R_0055_BaseOffers') IS NOT NULL DROP TABLE Warehouse.Staging.R_0055_BaseOffers
SELECT	DISTINCT
	PartnerID,
	IronOfferID
INTO Warehouse.Staging.R_0055_BaseOffers
FROM	(
	SELECT	DISTINCT
		PartnerID,
		OfferID as IronOfferID
	FROM Warehouse.Relational.PartnerOffers_Base
UNION
	SELECT	PartnerID,
		IronOfferID
	FROM Warehouse.Relational.Partner_NonCoreBaseOffer
	)a

END