/*
	Author:		Stuart Barnley

	Date:		6th April 2016

	Purpose:	To run the Shopper Segment for all those where
				AutomaticRun = 1

	Update:		N/A

*/
CREATE Procedure [Segmentation].[Roc_Segmentation_AllPartnerRun_ALS]
As
--------------------------------------------------------------------------------------------------
---------------------------------------Write Entry to JobLog--------------------------------------
--------------------------------------------------------------------------------------------------
INSERT INTO Staging.JobLog
SELECT	StoredProcedureName = 'ShopperSegment_Build_Start - ALS',
		TableSchemaName = 'Segmentation',
		TableName = '',
		StartDate = GETDATE(),
		EndDate = NULL,
		TableRowCount  = NULL,
		AppendReload = NULL

--------------------------------------------------------------------------------------------------
------------------------------------Select Partners to Shopper Segment----------------------------
--------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#partners') IS NOT NULL DROP TABLE #partners

Select a.PartnerID,
		ROW_NUMBER() OVER(ORDER BY a.PartnerID ASC) AS RowNo
Into #Partners
From [nFI].[Segmentation].[PartnerSettings] as a
inner join nFI.segmentation.ALSRetailers as b
	on a.PartnerID = b.PartnerID
--Where AutomaticRun = 1
--------------------------------------------------------------------------------------------------
-----------------Call Individual Shopper Segment Stored Procedure for each partner----------------
--------------------------------------------------------------------------------------------------
Declare @RowNo int, @RowNoMax int,@PartnerID int
Set @RowNo = 1
Set @RowNoMax = Coalesce((Select Max(RowNo) From #Partners),0)

While @RowNo <= @RowNoMax
Begin
	Set @PartnerID = (Select PartnerID From #Partners Where RowNo = @RowNo)

	Exec [Segmentation].[ROC_Segmentation_Build_V2_Dev] @PartnerID,1

	Set @RowNo = @RowNo+1
End

--------------------------------------------------------------------------------------------------
---------------------------------------Write Entry to JobLog--------------------------------------
--------------------------------------------------------------------------------------------------
INSERT INTO Staging.JobLog
SELECT	StoredProcedureName = 'ShopperSegment_Build_End - ALS',
	TableSchemaName = 'Segmentation',
	TableName = '',
	StartDate = GETDATE(),
	EndDate = GETDATE(),
	TableRowCount  = NULL,
	AppendReload = NULL

