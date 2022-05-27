/*

	Author:		Stuart Barnley

	Date:		18th December 2017

	Purpose:	To Run ALS Shopper Segments as needed

*/
CREATE Procedure [Segmentation].[ShopperSegmentationALS_WeeklyRun_v2] (@EmailDate Date)
as

SET NOCOUNT ON

/*******************************************************************************************************************************************
	1. Write Entry to JobLog
*******************************************************************************************************************************************/

	Insert Into Staging.JobLog_Temp
	Select StoredProcedureName = 'ShopperSegmentationALS_WeeklyRun'
		 , TableSchemaName = 'Segmentation'
		 , TableName = ''
		 , StartDate = GetDate()
		 , EndDate = Null
		 , TableRowCount  = Null
		 , AppendReload = Null


/*******************************************************************************************************************************************
	2. Declare Variables and Tables
*******************************************************************************************************************************************/

	Declare @SDate Date = @EmailDate
	Declare @EDate Date = DateAdd(day, 7, @SDate)
		  , @CycleID Int
		
	Set @CycleID = (Select Coalesce(CycleID, 0) as CID
					From Relational.ROC_CycleDates 
					Where StartDate Between @SDate And @EDate)

	If Object_ID('Tempdb..#SegmentsToRun') Is Not Null Drop Table #SegmentsToRun
	Create Table #SegmentsToRun (PartnerID Int
							   , RowNo Int
							   , Primary Key (PartnerID))


/*******************************************************************************************************************************************
	3. Find offers that will be live at the time (non Core Base)
*******************************************************************************************************************************************/

If @CycleID > 0
Begin

	If Object_ID('Tempdb..#Partners') Is Not Null Drop Table #Partners
	Select Distinct iof.PartnerID
	Into #Partners
	From Relational.IronOffer iof
	Left join Relational.PartnerOffers_Base pob
		on iof.IronOfferID = pob.OfferID
	Where iof.StartDate <= @EDate
	And (iof.EndDate > @SDate Or iof.EndDate Is Null)
	And pob.OfferID Is Null

	Create Clustered index CIX_Partners_PartnerID on #Partners (PartnerID)


/*******************************************************************************************************************************************
	4. Find Partners that have settings corerctly added
*******************************************************************************************************************************************/

	Insert Into #SegmentsToRun
	Select pa.PartnerID
		 , Row_Number() Over (Order by pa.PartnerID Asc) AS RowNo
	From #Partners pa
	Inner join Segmentation.ROC_Shopper_Segment_Partner_Settings ps
		on pa.PartnerID = ps.PartnerID
	Inner join Staging.Partners_IncFuture pif
		on ps.PartnerID = pif.PartnerID
	Where ps.AutoRun = 1
	And ps.StartDate <= @EDate
	And (ps.EndDate Is Null Or ps.EndDate > @SDate)

End


/*******************************************************************************************************************************************
	5. Find Partners with offers going live within Strt and End Dates
*******************************************************************************************************************************************/

	Declare @LatestRowNo int = coalesce((Select Max(RowNo) From #SegmentsToRun),0)

	If Object_ID('Tempdb..#Partners2') Is Not Null Drop Table #Partners2
	Select Distinct iof.PartnerID
	Into #Partners2
	From Relational.IronOffer iof
	Left join Relational.PartnerOffers_Base pob
		on iof.IronOfferID = pob.OfferID
	Left join #SegmentsToRun seg
		on iof.PartnerID = seg.PartnerID
	Where iof.StartDate = @SDate
	And pob.OfferID Is Null
	And seg.PartnerID Is Null	

	Create Clustered index cix_Partners2_PartnerID on #Partners2 (PartnerID)


/*******************************************************************************************************************************************
	6. Find Partners that have settings corerctly added
*******************************************************************************************************************************************/

	Insert into #SegmentsToRun
	Select pa.PartnerID
		 , Row_Number() Over (Order by pa.PartnerID Asc) + @LatestRowNo AS RowNo
	From #Partners2 pa
	Inner join Segmentation.ROC_Shopper_Segment_Partner_Settings ps
		on pa.PartnerID = ps.PartnerID
	Inner join Staging.Partners_IncFuture pif
		on ps.PartnerID = pif.PartnerID
	Where ps.AutoRun = 1
	And ps.StartDate <= @EDate
	And (ps.EndDate Is Null Or ps.EndDate > @SDate)


/*******************************************************************************************************************************************
	7. Find Partners that have settings corerctly added
*******************************************************************************************************************************************/

	Declare @RowNo Int = 1
		  , @RowNoMax Int = (Select Coalesce(Max(RowNo),0) From #SegmentsToRun)
		  , @PartnerID Int


	Alter Index [ix_PartnerID_FanID] On [Segmentation].[Roc_Shopper_Segment_CustomerRanking] Disable

	While @RowNo <= @RowNoMax
	Begin
		  Set @PartnerID = (Select PartnerID From #SegmentsToRun Where RowNo = @RowNo)
		  Exec [Segmentation].[Segmentation_IndividualPartner_POS] @PartnerID, 1, 1
		  Set @RowNo = @RowNo+1
	End

	Alter Index [ix_PartnerID_FanID] On [Segmentation].[Roc_Shopper_Segment_CustomerRanking] Rebuild


/*******************************************************************************************************************************************
	8. Update entry in JobLogTemp Table with End Date
*******************************************************************************************************************************************/

	Update Staging.JobLog_Temp
	Set EndDate = GETDATE()
	where StoredProcedureName = 'ShopperSegmentationALS_WeeklyRun'
	And TableSchemaName = 'Segmentation'
	And TableName = ''
	And EndDate Is Null


/*******************************************************************************************************************************************
	9. Update entry in JobLog Table with Row Count
*******************************************************************************************************************************************/

	Insert Into Staging.JobLog
	Select [StoredProcedureName]
		 , [TableSchemaName]
		 , [TableName]
		 , [StartDate]
		 , [EndDate]
		 , [TableRowCount]
		 , [AppendReload]
	From staging.JobLog_Temp

	Truncate Table Staging.JobLog_Temp