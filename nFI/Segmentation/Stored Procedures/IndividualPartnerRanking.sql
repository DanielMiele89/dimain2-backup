

/********************************************************************************************
** Name: [Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_Ranking_V1] 
** Desc: Ranking per Segment for nFIs 
** Auth: Zoe Taylor
** Date: 14/03/2017
*********************************************************************************************
** Change History
** ---------------------
** #No		Date		Author			Description 
** --		--------	-------			------------------------------------
** 1		2020-06-15	RF				Process no actually used so simplify to improve runtime, ranking by registration dates removed
*********************************************************************************************/

CREATE PROCEDURE [Segmentation].[IndividualPartnerRanking] (@PartnerID INT)

AS
BEGIN

	--DECLARE @PartnerID INT = 4186

	SET NOCOUNT ON

	DECLARE @time DATETIME
		  , @msg VARCHAR(2048)
		  , @PartnerName VARCHAR(100) = (SELECT pa.PartnerName FROM [Relational].[Partner] pa WHERE pa.PartnerID = @PartnerID)

	DECLARE @TwoYearsAgo DATE = DATEADD(YEAR, -2, GETDATE())

	IF OBJECT_ID('tempdb..#PartnerTrans') IS NOT NULL  DROP TABLE #PartnerTrans
	SELECT pt.FanID
		 , MAX(pt.TransactionDate) AS TransactionDate
		 , MAX(CASE WHEN pt.PartnerID = @PartnerID THEN pt.TransactionDate ELSE @TwoYearsAgo END) AS TransactionDatePartner
	INTO #PartnerTrans
	FROM [Relational].[PartnerTrans] pt
	GROUP BY pt.FanID
	HAVING MAX(pt.TransactionDate) > @TwoYearsAgo

	CREATE CLUSTERED INDEX CIX_FanID ON #PartnerTrans (FanID)

	SELECT @msg = @PartnerName + ' - Ranking - Fetch customers last transaction dates'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	IF OBJECT_ID('tempdb..#CustomerRanking') IS NOT NULL  DROP TABLE #CustomerRanking
	SELECT si.FanID
		 , ROW_NUMBER() OVER (PARTITION BY si.ClubID, si.Segment ORDER BY si.Spend DESC, pt.TransactionDatePartner DESC, pt.TransactionDate DESC) AS CustomerRanking
	INTO #CustomerRanking
	FROM [Segmentation].[Roc_Shopper_Segment_SpendInfo] si
	LEFT JOIN #PartnerTrans pt
		ON si.FanID = pt.FanID

	SELECT @msg = @PartnerName + ' - Ranking - Assigned each customer a ranking'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------
	--		Insert Shopper and Lapsed Ranking
	-------------------------------------------------------------------

	INSERT INTO [Segmentation].[Roc_Shopper_Segment_CustomerRanking] (FanID
																	, PartnerID
																	, Ranking)
	SELECT FanID
		 , @PartnerID
		 , CustomerRanking
	FROM #CustomerRanking

	SELECT @msg = @PartnerName + ' - Ranking - ' + CONVERT(VARCHAR(10), @@RowCount) + ' customers inserted to [Segmentation].[Roc_Shopper_Segment_CustomerRanking]'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

END