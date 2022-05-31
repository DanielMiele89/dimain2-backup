/*
	Author:		Stuart Barnley

	Date:		6th April 2016

	Purpose:	To run the Shopper Segment for all those where
				AutomaticRun = 1

	Update:		N/A

*/
CREATE PROCEDURE [Segmentation].[AllPartnerRun] (@CycleDate DATE)
AS
BEGIN

	SET NOCOUNT ON
	--DECLARE @CycleDate DATE = '2020-04-09'


-------------------------------------------------------------------------------------
----------------------Close any offers that are no longer live-----------------------
-------------------------------------------------------------------------------------


	EXEC [Segmentation].[ROC_ShopperSegment_ClosedOffers] @CycleDate

-------------------------------------------------------------------------------------
-------------------------Find those Merchants running SS offers----------------------
-------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#SSPartners') IS NOT NULL DROP TABLE #SSPartners
	SELECT DISTINCT
		   PartnerID
	INTO #SSPartners
	FROM [Segmentation].[ROC_Shopper_Segment_To_Offers] sto
	INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
		ON sto.IronOfferID = iof.ID
	WHERE LiveOffer = 1
	AND ShopperSegmentTypeID BETWEEN 7 AND 9

	CREATE CLUSTERED INDEX CIX_PartnerID ON #SSPartners (PartnerID)


-------------------------------------------------------------------------------------
------------------Update Auto Run to only needed SS Segmentation---------------------
-------------------------------------------------------------------------------------

	UPDATE ps
	SET AutomaticRun = (CASE
							WHEN a.PartnerID IS NULL THEN 0
							ELSE 1
						END)
	FROM [Segmentation].[PartnerSettings] ps
	LEFT JOIN #SSPartners as a
		ON ps.PartnerID = a.PartnerID

	
-------------------------------------------------------------------------------------
---------------------Update Table of Retailer to Segment (ALS)-----------------------
-------------------------------------------------------------------------------------

	INSERT INTO nFI.segmentation.ALSRetailers
	SELECT DISTINCT
		   iof.PartnerID
	FROM [Segmentation].[ROC_Shopper_Segment_To_Offers] sto
	INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
		ON sto.IronOfferID = iof.ID
	WHERE LiveOffer = 1
	AND ShopperSegmentTypeID BETWEEN 7 AND 9
	AND NOT EXISTS (SELECT 1
					FROM [nFI].[Segmentation].[ALSRetailers] als
					WHERE iof.PartnerID = als.PartnerID)


--------------------------------------------------------------------------------------------------
------------------------------------Select Partners to Shopper Segment----------------------------
--------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#partners') IS NOT NULL DROP TABLE #partners
	SELECT	ps.PartnerID
		,	pa.Name AS PartnerName
		,	ROW_NUMBER() OVER (ORDER BY ps.PartnerID ASC) AS RowNo
	INTO #Partners
	FROM [nFI].[Segmentation].[PartnerSettings] ps
	INNER JOIN [nFI].[Segmentation].[ALSRetailers] als
		ON ps.PartnerID = als.PartnerID
	INNER JOIN [SLC_REPL].[dbo].[Partner] pa
		ON als.PartnerID = pa.ID
	WHERE EXISTS (	SELECT 1
					FROM [SLC_REPL].[dbo].[IronOffer] iof
					WHERE ps.PartnerID = iof.PartnerID
					AND iof.IsDefaultCollateral = 0
					AND (iof.EndDate IS NULL OR iof.EndDate > GETDATE()))
	AND NOT EXISTS (	SELECT 1
						FROM [Segmentation].[Shopper_Segmentation_JobLog] jl
						WHERE jl.StartDate > DATEADD(DAY, -2, GETDATE())
						AND pa.ID = jl.PartnerID)
	AND ps.EndDate IS NULL

--------------------------------------------------------------------------------------------------
-----------------Call Individual Shopper Segment Stored Procedure for each partner----------------
--------------------------------------------------------------------------------------------------

	-------------------------------------------------------------------
	--		Get customer data
	-------------------------------------------------------------------
	
		IF OBJECT_ID('tempdb..##Customers') IS NOT NULL DROP TABLE ##Customers
		SELECT cu.SourceUID
			 , cu.FanID
			 , cu.CompositeID
		INTO ##Customers
		FROM Relational.Customer cu
		WHERE cu.Status = 1
		
		CREATE CLUSTERED INDEX CIX_CompositeID on ##Customers (CompositeID)
		CREATE NONCLUSTERED INDEX IX_FanID on ##Customers (FanID)
		
			
	-------------------------------------------------------------------
	--		Get pan data
	-------------------------------------------------------------------
	
		IF OBJECT_ID('tempdb..##CustomerPans') IS NOT NULL DROP TABLE ##CustomerPans
		SELECT pa.CompositeID
			 , pa.ID AS PanID
		INTO ##CustomerPans
		FROM [SLC_Report].[dbo].[Pan] pa
		WHERE EXISTS (	SELECT 1
						FROM ##Customers cu
						WHERE pa.CompositeID = cu.CompositeID)

		CREATE CLUSTERED INDEX CIX_PanID on ##CustomerPans (PanID)

		TRUNCATE TABLE [Segmentation].[Roc_Shopper_Segment_CustomerRanking]


	Declare @RowNo int, @RowNoMax int,@PartnerID int
	Set @RowNo = 1
	Set @RowNoMax = Coalesce((Select Max(RowNo) From #Partners),0)

	While @RowNo <= @RowNoMax
	Begin
		Set @PartnerID = (Select PartnerID From #Partners Where RowNo = @RowNo)

		Exec [Segmentation].[IndividualPartner] @PartnerID, 0
		PRINT CHAR(13)

		Set @RowNo = @RowNo+1
	End

	DROP TABLE ##Customers
	DROP TABLE ##CustomerPans

END