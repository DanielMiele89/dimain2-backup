/*
	Author:		Stuart Barnley

	Date:		6th April 2016

	Purpose:	To run the Shopper Segment for all those where
				AutomaticRun = 1

	Update:		N/A

*/
CREATE PROCEDURE [Segmentation].[AllPartnerRun_20200205] (@CycleDate DATE)
AS
BEGIN

--------------------------------------------------------------------------------------------------
------------------------------------Select Partners to Shopper Segment----------------------------
--------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#partners') IS NOT NULL DROP TABLE #partners
	SELECT ps.PartnerID
		 , ROW_NUMBER() OVER (ORDER BY ps.PartnerID ASC) AS RowNo
	INTO #Partners
	FROM [nFI].[Segmentation].[PartnerSettings] ps
	INNER JOIN [nFI].[Segmentation].[ALSRetailers] als
		ON ps.PartnerID = als.PartnerID
	WHERE EXISTS (	SELECT 1
					FROM nFI.Relational.IronOffer iof
					WHERE iof.PartnerID = ps.PartnerID
					AND (iof.EndDate >= '2019-12-16' OR iof.EndDate IS NULL))

--------------------------------------------------------------------------------------------------
-----------------Call Individual Shopper Segment Stored Procedure for each partner----------------
--------------------------------------------------------------------------------------------------




	Declare @RowNo int, @RowNoMax int,@PartnerID int
	Set @RowNo = 1
	Set @RowNoMax = Coalesce((Select Max(RowNo) From #Partners),0)

	While @RowNo <= @RowNoMax
	Begin
		Set @PartnerID = (Select PartnerID From #Partners Where RowNo = @RowNo)

		Exec [Segmentation].[IndividualPartner_20200205] @PartnerID, @CycleDate

		Set @RowNo = @RowNo+1
	End

END