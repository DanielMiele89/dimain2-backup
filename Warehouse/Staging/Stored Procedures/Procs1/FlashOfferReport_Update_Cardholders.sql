/******************************************************************************
Author: Jason Shipp
Created: 24/05/2018
Purpose:
	- Updates newly calculated cardholders in the Warehouse.Staging.FlashOfferReport_Metrics table
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Update_Cardholders
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Load cardholder counts
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Cardholder_Counts') IS NOT NULL DROP TABLE #Cardholder_Counts;

	SELECT -- Control nFI/Warehouse/AMEX
		o.IronOfferID
		, c.Exposed
		, c.IsWarehouse
		, o.StartDate
		, o.EndDate
		, o.PeriodType
		, c.ControlGroupTypeID
		, COUNT(DISTINCT c.FanID) AS Cardholders
	INTO #Cardholder_Counts
	FROM Warehouse.Staging.FlashOfferReport_All_Offers o 
	LEFT JOIN Warehouse.Staging.FlashOfferReport_ExposedControlCustomers c
		ON o.ControlGroupID = c.GroupID
		AND o.ControlGroupTypeID = c.ControlGroupTypeID
	   	AND (
			o.isWarehouse = c.isWarehouse
			OR o.isWarehouse IS NULL AND c.isWarehouse IS NULL
		)
	WHERE 
		c.Exposed = 0
	GROUP BY
		o.IronOfferID
		, c.Exposed
		, c.isWarehouse
		, o.StartDate
		, o.EndDate
		, o.PeriodType
		, c.ControlGroupTypeID

	UNION ALL

	SELECT -- Exposed nFI/Warehouse
		o.IronOfferID
		, c.Exposed
		, c.IsWarehouse
		, o.StartDate
		, o.EndDate
		, o.PeriodType
		, c.ControlGroupTypeID
		, COUNT(DISTINCT c.FanID) AS Cardholders
	FROM Warehouse.Staging.FlashOfferReport_All_Offers o 
	LEFT JOIN Warehouse.Staging.FlashOfferReport_ExposedControlCustomers c
		ON o.IronOfferCyclesID = c.GroupID 
	   	AND (
			o.isWarehouse = c.isWarehouse
		)
	WHERE 
		c.Exposed = 1
		AND o.ControlGroupTypeID = 0
		AND o.IsWarehouse IS NOT NULL
	GROUP BY
		o.IronOfferID
		, c.Exposed
		, c.isWarehouse
		, o.StartDate
		, o.EndDate
		, o.PeriodType
		, c.ControlGroupTypeID

	UNION ALL

	SELECT -- Exposed AMEX
		x.IronOfferID
		, CAST(1 AS bit) AS Exposed
		, NULL AS isWarehouse 
		, x.StartDate
		, x.EndDate
		, x.PeriodType
		, NULL AS ControlGroupTypeID
		, x.ClickCounts AS Cardholders
    FROM (
		SELECT DISTINCT
			ame.IronOfferID
			, ame.ClickCounts
			, o.StartDate
			, o.EndDate
			, o.PeriodType
			, ROW_NUMBER() OVER (PARTITION BY o.IronOfferID, o.OfferSetupStartDate, o.OfferSetupEndDate ORDER BY ame.ReceivedDate DESC) DateRank
		FROM Warehouse.Staging.FlashOfferReport_All_Offers o
		INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
			ON ame.IronOfferID = o.IronOfferID
			AND DATEADD(day, 1, ame.ReceivedDate) <= o.OfferSetupEndDate
	) x
	WHERE x.DateRank = 1;

	/******************************************************************************
	Update Warehouse.Staging.FlashOfferReport_Metrics table
	******************************************************************************/

	UPDATE t1
	SET t1.Cardholders = t2.Cardholders
	FROM Warehouse.Staging.FlashOfferReport_Metrics t1
	INNER JOIN #Cardholder_Counts t2
		ON t1.Exposed = t2.Exposed
		AND (t1.isWarehouse = t2.isWarehouse OR t1.isWarehouse IS NULL AND t2.isWarehouse IS NULL)
		AND t1.IronOfferID = t2.IronOfferID
		AND (t1.ControlGroupTypeID = t2.ControlGroupTypeID OR (t1.ControlGroupTypeID IS NULL AND t2.ControlGroupTypeID IS NULL))
		AND t1.StartDate = t2.StartDate
		AND t1.EndDate = t2.EndDate
		AND t1.PeriodType = t2.PeriodType
	WHERE
		t1.Cardholders IS NULL;

END