CREATE PROCEDURE [FIFO].[ReductionIntervals_Load]
AS
BEGIN

	IF EXISTS (SELECT TOP 1 1 FROM FIFO.ReductionIntervals)
	BEGIN
		RAISERROR('FIFO.ReductionIntervals already populated, skipping',1,-1, -1) 
		RETURN
	END
	----------------------------------------------------------------------
	-- Get Reduction ranges
	----------------------------------------------------------------------
	DROP TABLE IF EXISTS #Reductions;
	SELECT 
		CustomerReductionID 
		, ReductionSourceID
		, CustomerID
		, ReductionDate
		, Reduction
		, [CumulativeReductionFrom] = [CumulativeReductionTo] - Reduction
		, [CumulativeReductionTo]
		, isBreakage
	INTO #Reductions
	FROM (
		SELECT 
			*
			, [CumulativeReductionTo] = SUM(Reduction) OVER (PARTITION BY CustomerID ORDER BY ReductionDateTime, ReductionSourceID) 
		FROM (		
			SELECT 
				CustomerReductionID = ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY ReductionDateTime, ReductionSourceID)
				, CustomerID
				, ReductionSourceID
				, Reduction
				, ReductionDate = CAST(ReductionDateTime AS DATE)
				, ReductionDateTime
				, isBreakage
			FROM [FIFO].[Reductions]
		) r
	) d

	CREATE CLUSTERED INDEX CIX ON #Reductions (CUstomerReductionID, CustomerID, ReductionDate, Reduction, isBreakage)

	----------------------------------------------------------------------
	-- First Reduction Interval
	----------------------------------------------------------------------

	DROP TABLE IF EXISTS #ReductionIntervals;
	SELECT 
		r.CustomerID
		, r.CustomerReductionID
		, r.ReductionDate
		, r.ReductionSourceID
		, r.Reduction
		, CumulativeReductionFrom
		, CumulativeReductionTo
		, e.MinCustomerEarningID
		, e.MaxCustomerEarningID
		, EndEarnings = e2.CumulativeEarningTo
		, isCarried = CAST(0 AS BIT)
		, r.isBreakage
	INTO #ReductionIntervals
	FROM #Reductions r
	CROSS APPLY (
		SELECT 
			MinCustomerEarningID = MIN(CustomerEarningID) -- the minimum earning id that is suitable for this allocation
			, MaxCustomerEarningID = MAX(CustomerEarningID) -- if the reduction is not able to be allocated 
		FROM FIFO.Earnings e 
		WHERE e.CustomerID = r.CustomerID
			AND e.EligibleDate <= r.ReductionDate
			AND e.CumulativeEarningFrom < r.Reduction 
	) e
	INNER loop JOIN FIFO.Earnings e2 
		ON e2.CustomerID = r.CustomerID AND e2.CustomerEarningID = e.MaxCustomerEarningID
	WHERE r.CustomerReductionID = 1
	ORDER BY CustomerID, CustomerReductionID

	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #ReductionIntervals (CustomerID, CustomerReductionID)

	SET NOCOUNT ON

	DECLARE 
		@CustomerReductionID BIGINT = 2
		, @MaxCustomerReductionID BIGINT 

	SELECT 
		@MaxCustomerReductionID = MAX(CustomerReductionID) 
	FROM 
	(
		SELECT 
			CustomerReductionID = ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY ReductionDate, ReductionSourceID) 
		FROM #Reductions
	) d

	----------------------------------------------------------------------
	-- For each customer reduction id, get reduction interval
	----------------------------------------------------------------------
	WHILE 1 = 1 
	BEGIN

		INSERT INTO #ReductionIntervals (
			CustomerID
			, CustomerReductionID
			, ReductionDate
			, ReductionSourceID
			, Reduction
			, CumulativeReductionFrom
			, CumulativeReductionTo
			, MinCustomerEarningID
			, MaxCustomerEarningID
			, EndEarnings
			, isCarried
			, isBreakage
		)
		SELECT 
			r.CustomerID
			, r.CustomerReductionID
			, r.ReductionDate
			, r.ReductionSourceID
			, r.Reduction
			, CumulativeReductionFrom
			, r.CumulativeReductionTo
			, e.MinCustomerEarningID
			, e.MaxCustomerEarningID
			, EndEarnings = e2.CumulativeEarningTo
			, isCarried
			, isBreakage
		FROM #Reductions r
		CROSS APPLY ( -- get the previous row from the results table
			SELECT 
				CumulativeReductionTo
				, NextCustomerEarningID = CASE 
									WHEN ri.CumulativeReductionTo = ri.EndEarnings 
										THEN ri.MaxCustomerEarningID + 1 
									ELSE ri.MaxCustomerEarningID 
								END
				, isCarried = CAST(ri.CumulativeReductionTo - ri.EndEarnings AS BIT)
			FROM #ReductionIntervals ri 
			WHERE ri.CustomerID = r.CustomerID 
				AND ri.CustomerReductionID = r.CustomerReductionID - 1
		) lr
		CROSS APPLY (
			SELECT 
				MinCustomerEarningID = MIN(CustomerEarningID)
				, MaxCustomerEarningID = MAX(CustomerEarningID)
			FROM FIFO.Earnings e 
			WHERE e.CustomerID = r.CustomerID
				AND e.EligibleDate <= r.ReductionDate
				AND e.CumulativeEarningFrom < r.Reduction + lr.CumulativeReductionTo
				AND e.CustomerEarningID >= lr.NextCustomerEarningID
		) e
		INNER LOOP JOIN FIFO.Earnings e2 
			ON e2.CustomerID = r.CustomerID AND e2.CustomerEarningID = e.MaxCustomerEarningID
		WHERE r.CustomerReductionID = @CustomerReductionID	

		SET @CustomerReductionID = @CustomerReductionID + 1

		IF @CustomerReductionID > @MaxCustomerReductionID 
			BREAK
	
	END
	SET NOCOUNT OFF

	----------------------------------------------------------------------
	-- Load into table
	----------------------------------------------------------------------
	INSERT INTO FIFO.ReductionIntervals WITH (TABLOCKX)
	(
		[CustomerID]
		, [CustomerReductionID] 
		, [ReductionDate] 
		, [ReductionSourceID] 
		, [Reduction] 
		, [CumulativeReductionFrom] 
		, [CumulativeReductionTo] 
		, [MinCustomerEarningID] 
		, [MaxCustomerEarningID] 
		, [EndEarnings] 
		, [isCarried] 
		, [isBreakage]
	)
	SELECT
		[CustomerID]
		, [CustomerReductionID] 
		, [ReductionDate] 
		, [ReductionSourceID] 
		, [Reduction] 
		, [CumulativeReductionFrom] 
		, [CumulativeReductionTo] 
		, [MinCustomerEarningID] 
		, [MaxCustomerEarningID] 
		, [EndEarnings] 
		, [isCarried] 
		, [isBreakage]
	FROM #ReductionIntervals 
	ORDER BY CustomerID, CustomerReductionID

END
