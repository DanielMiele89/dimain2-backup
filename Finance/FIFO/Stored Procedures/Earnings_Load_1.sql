/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Loads earnings by partition and calculates the cumulative range 
				for each earning by customer

	When running as a simple SUM() OVER(PARTITION BY ORDER BY), it took a considerable
	amount of time to run and didnt complete and seemed to be extremely sensitive 
	to server load due to the pressure on memory.  Think because of partitioning
	on the table, it causes extra sorts to be required when loading the data

	This method of loading the data into the table and then calculating the cumulatives
	tends to be more consistent and stable albeit undocumented haha :/

******************************************************************************/
CREATE PROCEDURE [FIFO].[Earnings_Load]
AS
BEGIN
	 SET XACT_ABORT ON
	 SET NOCOUNT ON

	IF EXISTS (SELECT TOP 1 1 FROM FIFO.Earnings)
	BEGIN
		RAISERROR('FIFO.Earnings already populated, skipping',1,-1, -1) 
		RETURN
	END
	----------------------------------------------------------------------
	-- Build Partition Details
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#PartitionDetails') IS NOT NULL
		DROP TABLE #PartitionDetails
		
	SELECT
		pstats.partition_number AS PartitionNumber
	INTO #PartitionDetails
	FROM sys.dm_db_partition_stats AS pstats
	WHERE pstats.object_id = OBJECT_ID('dbo.transactions')
	ORDER BY PartitionNumber DESC;


	----------------------------------------------------------------------
	-- Loop through partitions to load data
	----------------------------------------------------------------------

	DECLARE @PartitionNumber INT = 0
		, @Insert DATETIME
		, @Update DATETIME
		, @Start DATETIME = GETDATE()
	WHILE 1=1
	BEGIN

		SELECT TOP 1 
			@PartitionNumber = PartitionNumber
		FROM #PartitionDetails
		WHERE PartitionNumber > @PartitionNumber
		ORDER BY PartitionNumber

		IF @@rowcount = 0
			BREAK

		INSERT INTO FIFO.Earnings WITH (TABLOCKX)
		(
			CustomerID
			, PublisherID
			, PaymentMethodID
			, PaymentCardID
			, TranDate
			, EligibleDate
			, TransactionID
			, Earning
			, EarningSourceID
			, CustomerEarningID
			, CumulativeEarningTo
			, CumulativeEarningFrom
			, ActivationDays
			--, PreviousCustomerID
		)
		SELECT
			CustomerID
			, PublisherID
			, PaymentMethodID
			, PaymentCardID
			, TranDate
			, DATEADD(DAY, ActivationDays, TranDate) AS EligibleDate
			, TransactionID
			, Earning
			, EarningSourceID
			, CustomerEarningID = NULL
			, CumulativeEarningTo = NULL
			, CumulativeEarningFrom = NULL
			, ActivationDays
		FROM dbo.Transactions t
		WHERE $PARTITION.PFn_Transactions_ByMonth(TranDate) = @PartitionNumber
			AND EarningSOurceID NOT IN
			(
				2160 -- Breakage - Optout (from SLCPointsNegative)
				, 2158 -- Breakage - Deceased (from SLCPointsNegative)
				, 2159 -- Breakage - Deactivation (from SLCPointsNegative)
				, 2174 -- Breakage Negative Adjustment (from TransactionType)
			)


	END


	----------------------------------------------------------------------
	-- Build cumulative earning ranges for each customer
	----------------------------------------------------------------------
	DECLARE @CumulativeEarningTo DECIMAL(9,2) = 0
		, @CustomerEarningID INT = 0
		, @PreviousCustomerID INT
		, @isCurrentCustomer TINYINT = 0

	-- Sensitive to order of variables being set if using @Var = Col = @Var 
		-- i.e. it is possible to see the previous set variable and the currently set variable at the same time
			-- the previous variable is available until the SET operation occurs
	
	-- if using Column = @Var, the value of @Var will be the result of the current row
	UPDATE e
	SET 
		@isCurrentCustomer = CASE -- do before we update the @PreviousCustomerID variable to get the previous customerid
			WHEN CustomerID = @PreviousCustomerID 
				THEN 1 
			ELSE 0 
		END 
		-- update variable and column to current customer id -- could also just use CustomerID instead of another column
		, @PreviousCustomerID = PreviousCustomerID = CustomerID
		-- if the previous row customer id is different, reset variable to 0, otherwise +1 to the previous earning id
		, @CustomerEarningID = CustomerEarningID = (@CustomerEarningID * @isCurrentCustomer ) + 1 
		-- if the previous row customer id is different, reset variable to 0, otherwise +Earning to the previous CumulativeEarningTo
		, @CumulativeEarningTo = CumulativeEarningTo = (@CumulativeEarningTo * @isCurrentCustomer) + Earning 
		-- Subtract currently set CumulativeEarningTo from the Earning to get the start range of earning
		, CumulativeEarningFrom = @CumulativeEarningTo - Earning 
	FROM FIFO.Earnings  e
	WITH (INDEX(cx_Stuff)) -- enforce the order of the update by using the clustered index on the table as first operation 
							-- (can see in the execution plan, and the index ORDERED = true)
							-- this will scan the table in clustered index order and therefore update in said order


END



