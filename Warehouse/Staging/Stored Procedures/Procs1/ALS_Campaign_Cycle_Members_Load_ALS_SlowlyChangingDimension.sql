/******************************************************************************
Author	  Jason Shipp
Created	  31/01/2018
Purpose	 
	Refresh tables with ALS segment assignment dates for Warhouse and nFI customers being analysed, in preparation for moving data to AllPublisherWarehouse:
		Staging.ALS_SlowlyChangingDimension_nFI
		Staging.ALS_SlowlyChangingDimension_Warehouse

Modification History
	Jason Shipp 22/02/2018
		- Replaced ShopperSegmentTypeID with SuperSegmentTypeID, and made select distinct
******************************************************************************/

CREATE PROCEDURE [Staging].[ALS_Campaign_Cycle_Members_Load_ALS_SlowlyChangingDimension]

AS
BEGIN

	SET NOCOUNT ON;

	/**************************************************************************
	Refresh Staging.ALS_SlowlyChangingDimension_nFI table with ALS assignment dates for nFI customers being analysed
	
	Create table for storing results:

	CREATE TABLE Staging.ALS_SlowlyChangingDimension_nFI
		(ID INT IDENTITY (1,1) NOT NULL
		, SuperSegmentTypeID INT
		, PartnerID INT
		, FanID INT
		, StartDate DATE
		, EndDate DATE
		, CONSTRAINT PK_ALS_SlowlyChangingDimension_nFI PRIMARY KEY CLUSTERED (ID)
		)
	***************************************************************************/

	TRUNCATE TABLE Staging.ALS_SlowlyChangingDimension_nFI;

	IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'IX_ALS_SlowlyChangingDimension_nFI') 
		DROP INDEX IX_ALS_SlowlyChangingDimension_nFI ON Staging.ALS_SlowlyChangingDimension_nFI;

	INSERT INTO Staging.ALS_SlowlyChangingDimension_nFI
		(SuperSegmentTypeID
		, PartnerID
		, FanID
		, StartDate
		, EndDate
		)
	SELECT
		st.SuperSegmentTypeID
		, sm.PartnerID
		, sm.FanID
		, sm.StartDate
		, sm.EndDate
	FROM Staging.ALS_Anchor_Cycle_Member_nFI anc
	LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Members sm WITH(NOLOCK)
		ON anc.PartnerID = sm.PartnerID
		AND anc.FanID = sm.FanID
	LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types st
		ON sm.ShopperSegmentTypeID = st.ID;

	/**************************************************************************
	Refresh Staging.ALS_SlowlyChangingDimension_Warehouse table with ALS assignment dates for Warehouse customers being analysed
	
	Create table for storing results:

	CREATE TABLE Staging.ALS_SlowlyChangingDimension_Warehouse
		(ID INT IDENTITY (1,1) NOT NULL
		, SuperSegmentTypeID INT
		, PartnerID INT
		, FanID INT
		, StartDate DATE
		, EndDate DATE
		, CONSTRAINT PK_ALS_SlowlyChangingDimension_Warehouse PRIMARY KEY CLUSTERED (ID)
		)
	***************************************************************************/

	TRUNCATE TABLE Staging.ALS_SlowlyChangingDimension_Warehouse;

	IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'IX_ALS_SlowlyChangingDimension_Warehouse') 
		DROP INDEX IX_ALS_SlowlyChangingDimension_Warehouse ON Staging.ALS_SlowlyChangingDimension_Warehouse;

	INSERT INTO Staging.ALS_SlowlyChangingDimension_Warehouse
		(SuperSegmentTypeID
		, PartnerID
		, FanID
		, StartDate
		, EndDate
		)		
	SELECT
		st.SuperSegmentTypeID
		, sm.PartnerID
		, sm.FanID
		, sm.StartDate
		, sm.EndDate
	FROM Staging.ALS_Anchor_Cycle_Member_Warehouse anc
	LEFT JOIN Warehouse.Segmentation.ROC_Shopper_Segment_Members sm WITH(NOLOCK)
		ON anc.PartnerID = sm.PartnerID
		AND anc.FanID = sm.FanID
	LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types st
		ON sm.ShopperSegmentTypeID = st.ID;

END