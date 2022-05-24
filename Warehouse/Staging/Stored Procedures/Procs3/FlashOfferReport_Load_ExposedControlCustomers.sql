/******************************************************************************
Author: Jason Shipp
Created: 23/05/2018
Purpose: 
	- Loads new exposed and control customers to get debit card only transactions for into Warehouse.Staging.FlashOfferReport_ExposedControlCustomers 

------------------------------------------------------------------------------
Modification History

Jason Shipp 19/07/2018
	-- Differentiated logic that determines whether a 1) ControlGroupID or 2) IronOfferCyclesID already exists in the FlashOfferReport_ExposedControlCustomers table

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Load_ExposedControlCustomers
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Clear table and drop any indexes on Warehouse.Staging.FlashOfferReport_ExposedControlCustomers
	******************************************************************************/

	--Truncate table Warehouse.Staging.FlashOfferReport_ExposedControlCustomers;

	--IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'UCX_FlashOfferReport_ExposedControlCustomers')
	--	DROP INDEX UCX_FlashOfferReport_ExposedControlCustomers ON Warehouse.Staging.FlashOfferReport_ExposedControlCustomers;

	--IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'NIX_FlashOfferReport_ExposedControlCustomers')
	--	DROP INDEX NIX_FlashOfferReport_ExposedControlCustomers ON Warehouse.Staging.FlashOfferReport_ExposedControlCustomers;

	/******************************************************************************
	-- Load rows from Warehouse.Staging.FlashOfferReport_All_Offers with ControlGroupIDs not already in Warehouse.Staging.FlashOfferReport_ExposedControlCustomers

	-- Create table for storing results:

	CREATE TABLE Warehouse.Staging.FlashOfferReport_All_NewOffers (
		IronOfferID int NOT NULL
		, IsWarehouse int
		, GroupID int 
		, ControlGroupTypeID int
		, IsExposed	bit NOT NULL
	)

	CREATE CLUSTERED INDEX CIX_FlashOfferReport_All_NewOffers ON Warehouse.Staging.FlashOfferReport_All_NewOffers (
		GroupID
		, IsWarehouse
	);
	******************************************************************************/
	
	TRUNCATE TABLE Warehouse.Staging.FlashOfferReport_All_NewOffers;

	INSERT INTO Warehouse.Staging.FlashOfferReport_All_NewOffers (
		IronOfferID
		, IsWarehouse
		, GroupID
		, ControlGroupTypeID
		, IsExposed
	)
	
	SELECT DISTINCT
		o.IronOfferID
		, o.IsWarehouse
		, o.ControlGroupID AS GroupID
		, o.ControlGroupTypeID
		, 0 AS IsExposed
	FROM Warehouse.Staging.FlashOfferReport_All_Offers o
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.FlashOfferReport_ExposedControlCustomers d
		WHERE 
			o.ControlGroupID = d.GroupID
			AND d.Exposed = 0
			AND (o.IsWarehouse = d.IsWarehouse OR (o.IsWarehouse IS NULL AND d.IsWarehouse IS NULL))
			AND o.ControlGroupTypeID = d.ControlGroupTypeID
	)
	UNION ALL
	SELECT DISTINCT
		o.IronOfferID
		, o.IsWarehouse
		, o.IronOfferCyclesID AS GroupID
		, NULL AS ControlGroupTypeID
		, 1 AS IsExposed
	FROM Warehouse.Staging.FlashOfferReport_All_Offers o
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.FlashOfferReport_ExposedControlCustomers d
		WHERE 
			o.IronOfferCyclesID = d.GroupID
			AND d.Exposed = 1
			AND (o.IsWarehouse = d.IsWarehouse OR (o.IsWarehouse IS NULL AND d.IsWarehouse IS NULL))
	);	

	/******************************************************************************
	Load new exposed and control customers for the iron offers in Warehouse.Staging.FlashOfferReport_All_Offers (done using SSIS package)

	-- Create table for storing results:

	CREATE TABLE Warehouse.Staging.FlashOfferReport_ExposedControlCustomers (
		GroupID int NOT NULL
		, FanID int NOT NULL
		, CINID int NULL
		, Exposed bit NOT NULL
		, IsWarehouse int NULL
		, ControlGroupTypeID int
	)
	******************************************************************************/

	--INSERT INTO Warehouse.Staging.FlashOfferReport_ExposedControlCustomers (
	--	GroupID
	--	, FanID
	--	, CINID
	--	, Exposed
	--	, IsWarehouse
	--	, ControlGroupTypeID
	--)

	SELECT 
		x.GroupID
		, x.FanID
		, cl.CINID
		, x.Exposed
		, x.IsWarehouse
		, x.ControlGroupTypeID
	FROM (
		-- Warehouse control customers
		SELECT DISTINCT
			o.GroupID
			, cm.FanID
			, 0 AS Exposed
			, o.IsWarehouse
			, o.ControlGroupTypeID
		FROM Warehouse.Staging.FlashOfferReport_All_NewOffers o
		INNER JOIN Warehouse.Relational.ControlGroupMembers cm 
			ON o.groupid = cm.controlgroupid
		WHERE
			o.IsWarehouse = 1
			AND o.IsExposed = 0

		UNION ALL

		-- nFI control customers
		SELECT DISTINCT 
			o.GroupID
			, cm.FanID
			, 0 AS Exposed
			, o.IsWarehouse
			, o.ControlGroupTypeID
		FROM Warehouse.Staging.FlashOfferReport_All_NewOffers o
		INNER JOIN nFI.Relational.controlgroupmembers cm 
			ON o.GroupID = cm.controlgroupid
		WHERE
			o.IsWarehouse = 0
			AND o.IsExposed = 0
    
		UNION ALL

		-- Warehouse exposed customers (recent)
		(SELECT DISTINCT
			o.GroupID
			, h.FanID
			, 1 AS Exposed
			, o.IsWarehouse
			, NULL AS ControlGroupTypeID
		FROM Warehouse.Staging.FlashOfferReport_All_NewOffers o
		INNER JOIN Warehouse.Relational.CampaignHistory h
			ON o.GroupID = h.IronOfferCyclesID	   
		WHERE
			o.IsWarehouse = 1
			AND o.IsExposed = 1
		-- Warehouse exposed customers (archived)
		UNION 
		SELECT DISTINCT
			o.GroupID
			, h.FanID
			, 1 AS Exposed
			, o.IsWarehouse
			, NULL AS ControlGroupTypeID
		FROM Warehouse.Staging.FlashOfferReport_All_NewOffers o
		INNER JOIN Warehouse.Relational.CampaignHistory_Archive h
			ON o.GroupID = h.IronOfferCyclesID	   
		WHERE
			o.IsWarehouse = 1
			AND o.IsExposed = 1
		)
	
		UNION ALL

		-- nFI exposed customers
		SELECT DISTINCT
			o.GroupID
			, h.FanID
			, 1 AS Exposed
			, o.IsWarehouse
			, NULL AS ControlGroupTypeID
		FROM Warehouse.Staging.FlashOfferReport_All_NewOffers o
		INNER JOIN nFI.Relational.CampaignHistory h 
			ON o.GroupID= h.IronOfferCyclesID	   
		WHERE
			o.IsWarehouse = 0 
			AND o.IsExposed = 1

		UNION ALL

		-- AMEX control customers
		SELECT DISTINCT
			o.GroupID
			, cm.FanID
			, 0 AS Exposed
			, o.IsWarehouse
			, o.ControlGroupTypeID
		FROM Warehouse.Staging.FlashOfferReport_All_NewOffers o
		INNER JOIN nFI.Relational.AmexControlGroupMembers cm
			ON o.GroupID = cm.AmexControlgroupID
		WHERE
			o.IsWarehouse IS NULL
			AND o.IsExposed = 0
	) x
	LEFT JOIN SLC_Report.dbo.Fan f ON f.ID = x.FanID
	LEFT JOIN Relational.CINList cl ON cl.CIN = f.SourceUID;
	--WHERE NOT EXISTS ( -- Shouldn't need this due to check at beginning of query
	--	SELECT NULL FROM Warehouse.Staging.FlashOfferReport_ExposedControlCustomers d
	--	WHERE 
	--		x.GroupID = d.GroupID
	--		AND x.Exposed = d.Exposed
	--		AND (x.IsWarehouse = d.IsWarehouse OR x.IsWarehouse IS NULL AND d.IsWarehouse IS NULL)
	--		AND (x.ControlGroupTypeID = d.ControlGroupTypeID OR x.ControlGroupTypeID IS NULL AND d.ControlGroupTypeID IS NULL)
	--)

END