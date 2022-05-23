
CREATE PROCEDURE [ETL].[FIFO_Refresh_Incremental_OLD]
(
	@DebugMode BIT = 0
)
AS
BEGIN

	SET NOCOUNT OFF
	DECLARE @msg varchar(max)

	IF OBJECT_ID('tempdb..#PartialAllocated') IS NOT NULL
	DROP TABLE #PartialAllocated

	CREATE TABLE #PartialAllocated
	(
		[ReductionID] [int] NOT NULL,
		EarningID [int] NULL,
		[CustomerID] [int] NOT NULL,
		[ReductionDate] [date] NOT NULL,
		[ReductionValue] [money] NULL,
		[Earnings] [money] NULL,
		[TranDate] [date] NULL,
		[runval] [money] NULL,
		[maxrunval] [money] NULL,
		[rw] [bigint] NULL,
		[maxrw] [bigint] NULL,
		[newEarnings] [money] NULL,
		EarningSourceID [smallint] NULL,
		[EarningTypeID] [tinyint] NULL,
		[ReductionTypeID] [tinyint] NOT NULL,
		originalearning [money] NULL,
	)

	IF OBJECT_ID('tempdb..#Allocated') IS NOT NULL
	DROP TABLE #Allocated

	CREATE TABLE #Allocated
	(
		[ReductionID] [int] NOT NULL,
		EarningID [int] NULL,
		[CustomerID] [int] NOT NULL,
		[ReductionDate] [date] NOT NULL,
		[ReductionValue] [money] NULL,
		[Earnings] [money] NULL,
		[TranDate] [date] NULL,
		[runval] [money] NULL,
		[maxrunval] [money] NULL,
		[rw] [bigint] NULL,
		[maxrw] [bigint] NULL,
		[newEarnings] [money] NULL,
		EarningSourceID [smallint] NULL,
		[EarningTypeID] [tinyint] NULL,
		[ReductionTypeID] [tinyint] NOT NULL,
		originalearning [money] NULL,
	)

	DECLARE @LatestRunDateTime DATETIME
	SELECT @LatestRunDateTime = MAX(CreatedDateTime)
	FROM ETL.FIFO_Checkpoint

	----------------------------------------------------------------------
	-- Get customers to loop through
	----------------------------------------------------------------------

	IF (SELECT COUNT(1) FROM ETL.FIFO_Customers) = 0
	BEGIN


		--INSERT INTO ETL.FIFO_Customers
		--SELECT DISTINCT CustomerID 
		--FROM dbo.Earnings
		--WHERE CreatedDateTime > @LatestRunDateTime

		INSERT INTO ETL.FIFO_Customers
		SELECT DISTINCT CUstomerID
		FROM dbo.Earnings
		
		TRUNCATE TABLE ETL.FIFO_CheckpointEnd
		INSERT INTO ETL.FIFO_CheckpointEnd
		SELECT MAX(CreatedDateTime) FROM dbo.Earnings

		TRUNCATE TABLE dbo.ReductionAllocation
	END	

	-- Delete customers where they have had allocations already
	--DELETE ra FROM dbo.ReductionAllocation ra
	--WHERE EXISTS (
	--	SELECT 1
	--	FROM ETL.FIFO_Customers c
	--	WHERE ra.CustomerID = c.CustomerID
	--)

	

	RAISERROR('Initial Setup Completed', 0, 1)
	RAISERROR('Starting customer loop...', 0, 1)

	----------------------------------------------------------------------
	-- Start Fan Loop
	----------------------------------------------------------------------
	DECLARE @CurrRow INT = 0
		, @EndRow INT = (
		SELECT
			COUNT(1)
		FROM ETL.FIFO_Customers
	)
	, @FanBatches INT = 100000

	DECLARE @TotalLoops INT = CEILING(1.0*@EndRow/@FanBatches)
	WHILE 1=1
	BEGIN -- Begin Customer Loop

		IF (SELECT COUNT(1) FROM ETL.FIFO_Customers) = 0
			BREAK

		SET @CurrRow += @FanBatches
		SET @msg = CONCAT('Starting Customer Loop: ', @CurrRow / @FanBatches, '/', @TotalLoops)
		IF @DebugMode = 1 RAISERROR (@Msg, 0, 1) WITH NOWAIT
		----------------------------------------------------------------------
		-- Get Customers for current loop
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL
		DROP TABLE #Customers

		SELECT TOP (@FanBatches)
			CustomerID
		INTO #Customers
		FROM ETL.FIFO_Customers

		CREATE CLUSTERED INDEX CIX ON #Customers (CustomerID)
		----------------------------------------------------------------------
		-- Get Earnings ordered by date/id
		-- Postive Earnings
		-- Positive Breakage
		-- Cancelled Redemptions
		----------------------------------------------------------------------
		RAISERROR ('Get Base Earnings', 0, 1) WITH NOWAIT

		IF OBJECT_ID('tempdb..#Earnings_Staging') IS NOT NULL
		DROP TABLE #Earnings_Staging

		-- Positive Earnings
		SELECT
			EarningID
		  , EarningTypeID
		  , CustomerID
		  , Earnings
		  , TranDate
		  , EarningSourceID
		INTO #Earnings_Staging
		FROM dbo.Earnings t
		WHERE EXISTS
			(
				SELECT
					1
				FROM #Customers c
				WHERE t.CustomerID = c.CustomerID
			)

		CREATE CLUSTERED INDEX CIX ON #Earnings_Staging (EarningID)
		CREATE NONCLUSTERED INDEX NIX ON #Earnings_Staging (CustomerID, TranDate) INCLUDE (Earnings, EarningTypeID)

		IF OBJECT_ID('tempdb..#Earnings') IS NOT NULL
		DROP TABLE #Earnings

		SELECT
			*
		  , MAX(rw) OVER (PARTITION BY CustomerID) maxrw
		INTO #Earnings
		FROM (
			SELECT
				EarningID
			  , CustomerID
			  , Earnings
			  , TranDate
			  , ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY TranDate, EarningID) rw
			  , EarningSourceID
			  , EarningTypeID
			FROM #Earnings_Staging t
		) x

		CREATE UNIQUE CLUSTERED INDEX CIX ON #Earnings (CustomerID, rw)
		CREATE NONCLUSTERED INDEX NCIX2 ON #Earnings (CustomerID, rw) INCLUDE (Earnings)

		----------------------------------------------------------------------
		-- Get reductions, ordered by date/id
		----------------------------------------------------------------------
		RAISERROR ('Get Base Reductions', 0, 1) WITH NOWAIT
		IF OBJECT_ID('tempdb..#Reductions') IS NOT NULL
		DROP TABLE #Reductions
		SELECT
			ReductionID
		  , CustomerID
		  , ReductionDate
		  , ReductionValue
		  , ReductionTypeID
		  , ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY ReductionDate, ReductionID) AS rw
		INTO #Reductions
		FROM dbo.Reductions r
		WHERE EXISTS
			(
				SELECT
					1
				FROM #Customers c
				WHERE r.CustomerID = c.CustomerID
			)
			AND ReductionValue > 0

		CREATE CLUSTERED INDEX NCIX ON #Reductions (rw, CustomerID)

		----------------------------------------------------------------------
		-- Transaction table to hold each CustomerIDs location in the loop
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#MinTrans') IS NOT NULL
		DROP TABLE #MinTrans

		CREATE TABLE #MinTrans
		(
			CustomerID INT
		  , rw		   INT
		)

		INSERT INTO #MinTrans
		 SELECT DISTINCT CustomerID, 1 FROM #Earnings

		CREATE UNIQUE CLUSTERED INDEX cx ON #MinTrans (CustomerID)
		CREATE NONCLUSTERED INDEX ncx ON #MinTrans (rw) INCLUDE (CustomerID)

		----------------------------------------------------------------------
		-- Staging Earning table
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#Earns') IS NOT NULL
		DROP TABLE #Earns

		SELECT TOP 0
			*
		  , CAST(NULL AS MONEY) runval
		  , CAST(NULL AS MONEY) AS newearnings
		INTO #Earns
		FROM #Earnings e
		----------------------------------------------------------------------
		-- Staging Additional earning table for earnings that do not completely fall in
		-- the reduction value
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#AddEarns') IS NOT NULL
		DROP TABLE #AddEarns

		SELECT TOP 0
			*
		  , CAST(NULL AS MONEY) runval
		  , CAST(NULL AS MONEY) AS newearnings
		INTO #AddEarns
		FROM #Earnings e

		----------------------------------------------------------------------
		-- Table to handle fans that can be considered "complete"
		----------------------------------------------------------------------
		RAISERROR ('Preliminary Setup', 0, 1) WITH NOWAIT

		DECLARE @MaxRedemption INT =
				(
					SELECT
						MAX(rw)
					FROM #Reductions
				)
			  , @CurrRw INT = 0
		/**********************************************************************
		For each redemption
		***********************************************************************/

		WHILE @CurrRw < @MaxRedemption
		BEGIN -- Begin Reduction Loop

			DECLARE @EarnBatch INT = 2500
			DECLARE @BatchIncrease INT = 2500
			SET @CurrRw += 1

			SET @msg = CONCAT('Starting Loop: ', @CurrRw, '/', @MaxRedemption)
			IF @DebugMode = 1 RAISERROR (@Msg, 0, 1) WITH NOWAIT

			----------------------------------------------------------------------
			-- 1) Get next redemption for each fan
			----------------------------------------------------------------------
			IF OBJECT_ID('tempdb..#Redeem') IS NOT NULL
			DROP TABLE #Redeem

			SELECT
				*
			INTO #Redeem
			FROM #Reductions r
			WHERE r.rw = @CurrRw

			-- If we have no redemptions to calculate due to there being no earnings
			-- then end process
			IF @@rowcount = 0
			BEGIN
			RAISERROR ('No more redemptions...Ending process', 0, 1) WITH NOWAIT
			BREAK
			END

			CREATE UNIQUE CLUSTERED INDEX UCIX ON #Redeem (CustomerID)

			----------------------------------------------------------------------
			-- 2) Get set of earnings to compare
			-- 3) Calculate runvalue

			-- Also include any earnings that were not completely allocated in the previous run
			----------------------------------------------------------------------
			Get_Earnings:

			INSERT INTO #Earns
			(
				EarningID
			  , CustomerID
			  , Earnings
			  , TranDate
			  , rw
			  , EarningSourceID
			  , EarningTypeID
			  , maxrw
			  , runval
			  , newEarnings
			)
			 SELECT
				 EarningID
			   , CustomerID
			   , Earnings
			   , TranDate
			   , rw
			   , EarningSourceID
			   , EarningTypeID
			   , maxrw
			   , SUM(newEarnings) OVER (PARTITION BY CustomerID ORDER BY rw ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS runval
			   , x.newEarnings
			 FROM (
				 SELECT
					 EarningID
				   , CustomerID
				   , Earnings
				   , TranDate
				   , rw
				   , EarningSourceID
				   , EarningTypeID
				   , e.maxrw
				   , Earnings AS runval
				   , Earnings AS newearnings
				 FROM #Earnings e
				 WHERE EXISTS
					 (
						 SELECT
							 1
						 FROM #Redeem r
						 WHERE e.CustomerID = r.CustomerID
					 )
					 AND EXISTS
					 (
						 SELECT
							 t.rw
						 FROM #MinTrans t
						 WHERE e.CustomerID = t.CustomerID
							 AND e.rw BETWEEN t.rw AND t.rw + @EarnBatch
					 )

				 UNION ALL

				 SELECT
					 EarningID
				   , CustomerID
				   , Earnings
				   , TranDate
				   , rw
				   , EarningSourceID
				   , EarningTypeID
				   , maxrw
				   , runval
				   , newEarnings
				 FROM #AddEarns

			 ) x

			RAISERROR ('Earnings Gathered', 0, 1) WITH NOWAIT

			----------------------------------------------------------------------
			-- 4) Get initial allocation
			-- initial because there may not be enough earnings in the batch to
			-- completely allocate
			----------------------------------------------------------------------
			IF OBJECT_ID('tempdb..#InitialAlloc_Stage') IS NOT NULL
			DROP TABLE #InitialAlloc_Stage

			SELECT
				ReductionID
			  , ea.EarningID
			  , r.CustomerID
			  , ReductionDate
			  , ReductionValue
			  , Earnings
			  , TranDate
			  , ea.runval
			  , ea.rw
			  , ea.maxrw
			  , CASE
					WHEN runval - ReductionValue > 0
					 THEN (runval - ReductionValue)
					ELSE newEarnings
				END			newEarnings
			  , EarningSourceID
			  , EarningTypeID
			  , r.ReductionTypeID
			  , newEarnings AS originalearning
			INTO #InitialAlloc_Stage
			FROM #Redeem r
			LEFT JOIN #Earns ea
				ON ea.runval - ea.newEarnings < r.ReductionValue
					AND ea.CustomerID = r.CustomerID

			----------------------------------------------------------------------
			-- Remove rows that are not continous allocations due to refunds
			-- by removing all rows after the point of final allocation
			--- where applicable
			----------------------------------------------------------------------
			DELETE ia
			FROM #InitialAlloc_Stage ia
			CROSS APPLY (
				SELECT
					MIN(rw)
				FROM #InitialAlloc_stage ix
				WHERE NOT (ix.ReductionValue - ix.runval > 0)
					AND ia.ReductionID = ix.ReductionID
			) x (minrw)
			WHERE ia.rw > x.minrw

			IF OBJECT_ID('tempdb..#InitialAlloc') IS NOT NULL
			DROP TABLE #InitialAlloc
			SELECT
				*
			  , MAX(runval) OVER (PARTITION BY CustomerID) maxrunval
			INTO #InitialAlloc
			FROM #InitialAlloc_Stage

			CREATE CLUSTERED INDEX CIX ON #InitialAlloc (CustomerID, TranDate)

			RAISERROR ('Initial Allocated', 0, 1) WITH NOWAIT

			/**********************************************************************
			Logic Gates
				5. If reductionvalue - runval < 0
					a. Keep row for next redemption
				6. If redeuctionvalue - runval > 0
					a. go to 2)
				7. If not enough earnings, unallocated redemption

			***********************************************************************/

			----------------------------------------------------------------------
			-- Save checkpoints for each fan for next iteration
			----------------------------------------------------------------------
			UPDATE mt
			SET rw = ISNULL(x.MaxRw, rw)
			FROM #MinTrans mt
			CROSS APPLY (
				SELECT
					MAX(rw) + 1
				FROM #InitialAlloc ia
				WHERE NOT (ReductionValue - maxrunval > 0)
					AND maxrunval = runval
					AND mt.CustomerID = ia.CustomerID
			) x (MaxRw)

			----------------------------------------------------------------------
			-- Save the allocations that were done completely
			----------------------------------------------------------------------
			INSERT INTO #Allocated
			(
				ReductionID
			  , EarningID
			  , CustomerID
			  , ReductionDate
			  , ReductionValue
			  , Earnings
			  , TranDate
			  , runval
			  , maxrunval
			  , rw
			  , maxrw
			  , newEarnings
			  , EarningSourceID
			  , EarningTypeID
			  , ReductionTypeID
			  , originalearning
			)
			 SELECT
				 ReductionID
			   , EarningID
			   , CustomerID
			   , ReductionDate
			   , ReductionValue
			   , Earnings
			   , TranDate
			   , runval
			   , maxrunval
			   , rw
			   , maxrw
			   , newEarnings
			   , EarningSourceID
			   , EarningTypeID
			   , ReductionTypeID
			   , originalearning
			 FROM #InitialAlloc
			 WHERE NOT (ReductionValue - maxrunval > 0)

			TRUNCATE TABLE #Earns

			----------------------------------------------------------------------
			-- Delete additional earnings that have been allocated
			----------------------------------------------------------------------
			DELETE ae
			FROM #AddEarns ae
			JOIN #InitialAlloc ia
				ON ae.CustomerID = ia.CustomerID
			WHERE NOT (ReductionValue - maxrunval > 0)
			----------------------------------------------------------------------
			-- save the allocations that were partially allocated to the end of the reduction
			----------------------------------------------------------------------
			INSERT INTO #AddEarns
			(
				EarningID
			  , CustomerID
			  , Earnings
			  , TranDate
			  , rw
			  , EarningSourceID
			  , EarningTypeID
			  , maxrw
			  , runval
			  , newEarnings
			)
			 SELECT
				 EarningID
			   , CustomerID
			   , Earnings
			   , TranDate
			   , rw
			   , EarningSourceID
			   , EarningTypeID
			   , maxrw
			   , runval
			   , newEarnings
			 FROM #InitialAlloc
			 WHERE runval - ReductionValue > 0
				 AND maxrunval = runval

			----------------------------------------------------------------------
			-- remove fans that have been allocated successfully so they are not included
			-- when the batch size is increased
			----------------------------------------------------------------------
			DELETE r
			FROM #Redeem r
			JOIN #InitialAlloc ia
				ON r.CustomerID = ia.CustomerID
					AND NOT (ia.ReductionValue - ia.maxrunval > 0)


			/**********************************************************************
			If there are reductions that are not completely allocated
				For fans with no more earnings available
					set as an unallocated row and remove from the process and set all future redemptions as unallocated
				For reductions with no applicable earnings
					set all remaining redemptions as unallocated rows and exclude fan from future iterations
				For fans with more earnings available 
					increase batch size and try again
			***********************************************************************/
			IF EXISTS
				(
					SELECT TOP 1
						1
					FROM #InitialAlloc
					WHERE ReductionValue - maxrunval > 0
				)
			BEGIN
			RAISERROR ('Reduction Difference', 0, 1) WITH NOWAIT

			----------------------------------------------------------------------
			-- Partially allocated rows for fans that have no more earnings and the redemption could
			-- not be completely assigned
			----------------------------------------------------------------------
			INSERT INTO #PartialAllocated
			(
				ReductionID
			  , EarningID
			  , CustomerID
			  , ReductionDate
			  , ReductionValue
			  , Earnings
			  , TranDate
			  , runval
			  , maxrunval
			  , rw
			  , maxrw
			  , newEarnings
			  , EarningSourceID
			  , EarningTypeID
			  , ReductionTypeID
			  , originalearning
			)
			 SELECT
				 ReductionID
			   , EarningID
			   , CustomerID
			   , ReductionDate
			   , ReductionValue
			   , Earnings
			   , TranDate
			   , runval
			   , maxrunval
			   , rw
			   , maxrw
			   , newEarnings
			   , EarningSourceID
			   , EarningTypeID
			   , ReductionTypeID
			   , originalearning
			 FROM #InitialAlloc ia
			 WHERE ia.ReductionValue - ia.maxrunval > 0 -- there is still a reduction balance
				 AND EXISTS
				 (
					 SELECT TOP 1
						 1
					 FROM #InitialAlloc ix
					 WHERE ix.CustomerID = ia.CustomerID
						 AND ix.rw = ix.maxrw -- and this is the final earning available
				 )

			----------------------------------------------------------------------
			-- Set unseen Redemptions for fans that have no more earnings as unallocated
			----------------------------------------------------------------------
			INSERT INTO #PartialAllocated
			(
				ReductionID
			  , CustomerID
			  , ReductionDate
			  , ReductionValue
			  , ReductionTypeID
			  , EarningSourceID
			  , Earnings
			  , runval
			  , newEarnings
			  , maxrunval
			)
			 SELECT
				 ReductionID
			   , r.CustomerID
			   , ReductionDate
			   , ReductionValue
			   , ReductionTypeID
			   , -2				AS EarningSourceID
			   , ReductionValue AS Earnings
			   , ReductionValue AS RunVal
			   , ReductionValue AS newEarnings
			   , 1				AS maxrunval
			 FROM ( -- Get fans that have partially allocated redemptions
				 SELECT
					 CustomerID
				 FROM #InitialAlloc ia
				 WHERE ia.rw = ia.maxrw -- this is the final earning available
					 AND ia.ReductionValue - ia.maxrunval > 0 -- and there is still a reduction balance
			 ) x
			 JOIN #Reductions r
				 ON x.CustomerID = r.CustomerID
			 WHERE r.rw > @CurrRw

			----------------------------------------------------------------------
			-- Set Redemptions with no applicable earnings as unallocated
			-- along with any redemptions still remaining to be consumed
			----------------------------------------------------------------------

			INSERT INTO #PartialAllocated
			(
				ReductionID
			  , CustomerID
			  , ReductionDate
			  , ReductionValue
			  , ReductionTypeID
			  , EarningSourceID
			  , Earnings
			  , runval
			  , newEarnings
			  , maxrunval
			)
			 SELECT
				 ReductionID
			   , x.CustomerID
			   , ReductionDate
			   , ReductionValue
			   , ReductionTypeID
			   , -2				AS EarningSourceID
			   , ReductionValue AS Earnings
			   , ReductionValue AS RunVal
			   , ReductionValue AS newEarnings
			   , 1				AS maxrunval
			 FROM (
				 SELECT
					 CustomerID
				 FROM #InitialAlloc ia
				 WHERE ia.maxrunval IS NULL
			 ) x
			 JOIN #Reductions r
				 ON x.CustomerID = r.CustomerID
			 WHERE r.rw >= @CurrRw


			----------------------------------------------------------------------
			-- Clear additional earnings that have been unalloacated
			----------------------------------------------------------------------
			DELETE ae
			FROM #AddEarns ae
			JOIN #InitialAlloc ia
				ON ae.EarningID = ia.EarningID
					AND ae.EarningTypeID = ia.EarningTypeID
			WHERE ia.ReductionValue - ia.maxrunval > 0
				AND EXISTS
				(
					SELECT TOP 1
						1
					FROM #InitialAlloc ix
					WHERE ix.CustomerID = ia.CustomerID
						AND ix.rw = ix.maxrw
				)

			----------------------------------------------------------------------
			-- Remove fans from process where they have been unallocated
			-- since there are no more earnings
			----------------------------------------------------------------------
			DELETE r
			FROM #Reductions r
			JOIN #InitialAlloc ia
				ON r.CustomerID = ia.CustomerID
			WHERE ia.ReductionValue - ia.maxrunval > 0
				AND EXISTS
				(
					SELECT TOP 1
						1
					FROM #InitialAlloc ix
					WHERE ix.CustomerID = ia.CustomerID
						AND (ix.rw = ix.maxrw
							OR ix.maxrw IS NULL)
				)

			----------------------------------------------------------------------
			-- Exclude fans with unallocations from future sub iterations
			----------------------------------------------------------------------
			DELETE r
			FROM #Redeem r
			JOIN #InitialAlloc ia
				ON ia.CustomerID = r.CustomerID
					AND (
						ia.maxrunval IS NULL
						OR (
							ia.rw = ia.maxrw
							AND ia.ReductionValue - ia.maxrunval > 0
						)
					)

			----------------------------------------------------------------------
			-- If redemptions have all been allocated, end loop
			----------------------------------------------------------------------
			IF NOT EXISTS
				(
					SELECT TOP 1
						1
					FROM #Redeem
				)
			GOTO Loop_End;

			----------------------------------------------------------------------
			-- If there are still redemptions for this iteration and earnings for the
			-- fan to be processed, increase the batch size
			----------------------------------------------------------------------
			SET @EarnBatch += @BatchIncrease

			TRUNCATE TABLE #Earns
			RAISERROR ('More Earnings', 0, 1) WITH NOWAIT

			GOTO Get_Earnings;
			END

			Loop_End:
			----------------------------------------------------------------------
			-- Load into ReductionAllocation Table
			----------------------------------------------------------------------

			INSERT INTO dbo.ReductionAllocation
			(
				[CustomerID]
			  , [EarningID]
			  , [EarningTypeID]
			  , [ReductionID]
			  , [ReductionTypeID]
			  , [PartnerID]
			  , [EarningSourceID]
			  , [EarningDate]
			  , [Earning]
			  , [ReductionDate]
			  , [Reduction]
			  , [AllocatedEarning]
			  , [RemainingEarning]
			  , [RemainingReduction]
			  , [isFullAllocatedReduction]
			  , [isFullAllocatedEarning]
			  , AllocationOrder
			)
			 SELECT
				 CustomerID
			   , EarningID
			   , EarningTypeID
			   , ReductionID											  AS ReductionID
			   , ReductionTypeID
			   , es.PartnerID
			   , a.EarningSourceID
			   , TranDate
			   , Earnings
			   , ReductionDate
			   , ReductionValue											  AS [Reduction]
			   , CASE
					 WHEN runval - ReductionValue > 0
					  THEN originalearning - (runval - ReductionValue)
					 ELSE newEarnings
				 END													  AS [AllocatedEarning]
			   , CASE
					 WHEN runval - ReductionValue > 0
					  THEN newEarnings
					 ELSE 0
				 END													  AS [RemainingEarning]
			   , CASE
					 WHEN ReductionValue - runval < 0
					  THEN 0
					 ELSE ReductionValue - runval
				 END													  AS [RemainingReduction]
			   , CASE
					 WHEN rw = x.maxrw
					  THEN 1
				 END													  AS [isFullAllocatedReduction]
			   , 1														  AS IsFullAllocatedEarning
			   , ROW_NUMBER() OVER (PARTITION BY ReductionID ORDER BY rw) AllocationOrder
			 FROM #Allocated a
			 JOIN dbo.EarningSource es
				 ON a.EarningSourceID = es.EarningSourceID
			 CROSS APPLY (
				 SELECT
					 MAX(rw)
				 FROM #Allocated ax
				 WHERE a.ReductionID = ax.ReductionID
			 ) x (maxrw)
			 UNION ALL
			 SELECT
				 CustomerID
			   , EarningID
			   , EarningTypeID
			   , ReductionID											  AS ReductionID
			   , ReductionTypeID
			   , es.PartnerID
			   , a.EarningSourceID
			   , TranDate
			   , Earnings
			   , ReductionDate
			   , ReductionValue											  AS [Reduction]
			   , CASE
					 WHEN runval - ReductionValue > 0
					  THEN originalearning - (runval - ReductionValue)
					 ELSE newEarnings
				 END													  AS [AllocatedEarning]
			   , CASE
					 WHEN runval - ReductionValue > 0
					  THEN newEarnings
					 ELSE 0
				 END													  AS [RemainingEarning]
			   , ReductionValue - COALESCE(runval, 0)					  AS [RemainingReduction]
			   , CASE
					 WHEN COALESCE(rw, 0) = COALESCE(x.maxrw, 0)
					  THEN 0
				 END													  AS [isFullAllocatedReduction]
			   , 0														  AS IsFullAllocatedEarning
			   , ROW_NUMBER() OVER (PARTITION BY ReductionID ORDER BY rw) AllocationOrder
			 FROM #PartialAllocated a
			 JOIN dbo.EarningSource es
				 ON a.EarningSourceID = es.EarningSourceID
			 CROSS APPLY (
				 SELECT
					 MAX(rw)
				 FROM #PartialAllocated px
				 WHERE a.ReductionID = px.ReductionID
			 ) x (maxrw)

			TRUNCATE TABLE #Allocated
			TRUNCATE TABLE #PartialAllocated

			RAISERROR ('Loop End', 0, 1) WITH NOWAIT

		END -- End Reduction Loop

		DELETE c FROM ETL.FIFO_Customers c
		WHERE EXISTS (
			SELECT 1 FROM #Customers cx
			WHERE c.CustomerID = cx.CustomerID
		)
	END -- End Customer loop

	INSERT INTO ETL.FIFO_Checkpoint
	SELECT * 
	FROM ETL.FIFO_CheckpointEnd
END
