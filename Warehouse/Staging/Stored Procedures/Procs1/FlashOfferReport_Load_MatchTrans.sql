/******************************************************************************
Author: Jason Shipp
Created: 23/05/2018
Purpose: Loads MatchTrans for the partner being reported on for the analysis period into Warehouse.Staging.FlashOfferReport_MatchTrans
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Load_MatchTrans
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Clear and drop any indexes on Warehouse.Staging.FlashOfferReport_MatchTrans
	******************************************************************************/

	TRUNCATE TABLE Warehouse.Staging.FlashOfferReport_MatchTrans;

	IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'IX_FlashOfferReport_MatchTrans')
		DROP INDEX IX_FlashOfferReport_MatchTrans ON Warehouse.Staging.FlashOfferReport_MatchTrans;

	/******************************************************************************
	Load MatchTrans for the partner being reported on for the analysis period (done using SSIS package)

	-- Create table for storing results:		

	CREATE TABLE Warehouse.Staging.FlashOfferReport_MatchTrans (
		MatchID int NOT NULL
		, AddedDate date NOT NULL
		, TranDate date NOT NULL
		, FanID int NOT NULL
		, PartnerID int NOT NULL
		, Spend money NOT NULL
		, StatusID int NOT NULL
		, RewardStatusID int NOT NULL
		, IsOnline bit NOT NULL
		, PanID int
		, CONSTRAINT PK_FlashOfferReport_MatchTrans PRIMARY KEY CLUSTERED (MatchID ASC)
	)
	******************************************************************************/

	DECLARE @AnalysisStartDate date = (SELECT MIN(StartDate) FROM Warehouse.Staging.FlashOfferReport_All_offers);
	DECLARE @AnalysisEndDate date = (SELECT MAX(EndDate) FROM Warehouse.Staging.FlashOfferReport_All_offers);

	WITH PartnerAlternate AS ( -- Load partner alternates; Use CTE to avoid temp tables so stored procedure can be executed from SSIS
		SELECT DISTINCT * 
		FROM 
			(SELECT 
			PartnerID
			, AlternatePartnerID
			FROM Warehouse.APW.PartnerAlternate

			UNION ALL  

			SELECT 
			PartnerID
			, AlternatePartnerID
			FROM nFI.APW.PartnerAlternate
			) x
		)
	, MTSetup AS ( -- Load values to constrain rows from Match table
		SELECT DISTINCT
			r.ID
			, COALESCE(pa.AlternatePartnerID, r.PartnerID) AS PartnerID
			, r.Channel
		FROM SLC_Report.dbo.RetailOutlet r
		LEFT JOIN PartnerAlternate pa
			ON r.PartnerID = pa.PartnerID
		INNER JOIN (SELECT DISTINCT PartnerID FROM Warehouse.Staging.FlashOfferReport_All_offers) o
			ON COALESCE(pa.AlternatePartnerID, r.PartnerID) = o.PartnerID
	)	

	--INSERT INTO Warehouse.Staging.FlashOfferReport_MatchTrans (
	--	, MatchID
	--	, AddedDate
	--	, TranDate
	--	, FanID
	--	, PartnerID
	--	, Spend
	--	, StatusID
	--	, RewardStatusID
	--	, IsOnline
	--	, PanID
	--)

	SELECT		
		m.ID AS MatchID
        , CAST(m.AddedDate AS date) AS AddedDate
        , CAST(m.TransactionDate AS date) AS TranDate
        , f.ID AS FanID
        , su.PartnerID
        , m.Amount AS Spend
        , m.[Status] AS StatusID
        , m.[RewardStatus] AS RewardStatusID
        , CAST(CASE 
            WHEN su.PartnerID = 3724 and su.Channel = 1 THEN 1
            WHEN m.CardholderPresentData = '5' THEN 1
            WHEN m.CardholderPresentData = '9' and su.Channel = 1 THEN 1
            ELSE 0 
		END AS bit) AS IsOnline
		, m.PanID
	FROM SLC_Report.dbo.Match m WITH (NOLOCK)
	INNER JOIN SLC_Report.dbo.Pan p WITH (NOLOCK) 
		ON m.PanID = p.ID
	INNER JOIN SLC_Report.dbo.Fan f WITH (NOLOCK) 
		ON p.CompositeID = f.CompositeID
	INNER JOIN MTSetup su
		ON m.RetailOutletID = su.ID
	WHERE
		CAST(m.TransactionDate AS date) BETWEEN @AnalysisStartDate AND @AnalysisEndDate;		

END