
/********************************************************************************************
** Name: [Segmentation].[Segmentation_IndividualPartner_CustomerRanking_POS]
** Derived from: [Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_Ranking_V2] 
** Desc: Ranking per Segment  
** Auth: Zoe Taylor
** Date: 15/02/2017
*********************************************************************************************
** Change History
** ---------------------
** #No		Date		Author		Description 
** --		--------	-------		------------------------------------
** 1		2019-01-10	RF			Ranking steps optimised & step to disable & rebuild indexes on 
									CustomerRanking table
*********************************************************************************************/

CREATE PROCEDURE [Segmentation].[Segmentation_IndividualPartner_CustomerRanking_POS] (@PartnerID INT
																				   , @WeeklyRun INT = 0)

AS
BEGIN

SET NOCOUNT ON

/*******************************************************************************************************************************************
	1. Prepare parameters
*******************************************************************************************************************************************/

	Declare @PartnerIDToBeRanked INT = @PartnerID
		  , @TableName VarChar(50)
		  , @Time DateTime
		  ,	@msg VarChar(2048)
		  

/*******************************************************************************************************************************************
	2. Rank Shopper & Lapsed customers
*******************************************************************************************************************************************/

	If Object_ID('tempdb..#CustomerRanking_ShopperLapsed') Is Not Null Drop Table #CustomerRanking_ShopperLapsed
	Select ssi.FanID
		 , ssi.Spend
		 , Dense_Rank() Over (Partition by [ssi].[Segment] Order by [ssi].[Spend] Desc) as Ranking
	Into #CustomerRanking_ShopperLapsed
	From Segmentation.Roc_Shopper_Segment_SpendInfo ssi
	Where [ssi].[PartnerID] = @PartnerIDToBeRanked

	Create NonClustered index IX_CustomerRankingSL_FanIDSpend on #CustomerRanking_ShopperLapsed (FanID, Spend) Include (Ranking)
		  

/*******************************************************************************************************************************************
	3. Rank Acquire customers
*******************************************************************************************************************************************/
	
	If Object_ID('tempdb..#CustomerRanking_Acquire') Is Not Null Drop Table #CustomerRanking_Acquire
	Select [Segmentation].[Roc_Shopper_Segment_HeatmapInfo].[FanID]
		 , [Segmentation].[Roc_Shopper_Segment_HeatmapInfo].[Index_RR]
		 , Dense_Rank() Over (Order by [Segmentation].[Roc_Shopper_Segment_HeatmapInfo].[Index_RR] Desc) as Ranking
	Into #CustomerRanking_Acquire
	From Segmentation.Roc_Shopper_Segment_HeatmapInfo
		  

/*******************************************************************************************************************************************
	4. Update ranking tables 
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		4.1. Delete previous ranking
	***********************************************************************************************************************/

		If @WeeklyRun = 0
			Begin
				Alter Index [ix_PartnerID_FanID] On [Segmentation].[Roc_Shopper_Segment_CustomerRanking] Disable
			End

		Delete from Segmentation.Roc_Shopper_Segment_CustomerRanking
		where [Segmentation].[Roc_Shopper_Segment_CustomerRanking].[PartnerID] = @PartnerIDToBeRanked

		EXEC Staging.oo_TimerMessage 'Previous ranking for partner deleted from Segmentation.Roc_Shopper_Segment_CustomerRanking', @Time OUTPUT
		


	/***********************************************************************************************************************
		4.2. Insert shopper and lapsed ranking
	***********************************************************************************************************************/
	
		Insert into Segmentation.Roc_Shopper_Segment_CustomerRanking
		Select #CustomerRanking_ShopperLapsed.[FanID]
			 , @PartnerIDToBeRanked [PartnerID]
			 , #CustomerRanking_ShopperLapsed.[Ranking] [Ranking] 
		from #CustomerRanking_ShopperLapsed

		EXEC Staging.oo_TimerMessage 'Insert Shopper & Lapsed', @Time OUTPUT


	/***********************************************************************************************************************
		4.3. Insert acquire ranking
	***********************************************************************************************************************/

		Insert into Segmentation.Roc_Shopper_Segment_CustomerRanking
		Select #CustomerRanking_Acquire.[FanID], @PartnerIDToBeRanked [PartnerID], #CustomerRanking_Acquire.[Ranking] [Ranking] 
		from #CustomerRanking_Acquire

		EXEC Staging.oo_TimerMessage 'Insert acquire', @Time OUTPUT
		
		If @WeeklyRun = 0
			Begin		
				Alter Index [ix_PartnerID_FanID] On [Segmentation].[Roc_Shopper_Segment_CustomerRanking] Rebuild

				EXEC Staging.oo_TimerMessage 'Rebuild index', @Time OUTPUT
			End
		
END

RETURN 0