


CREATE PROCEDURE [FIFO].[Reductions_Load]
AS
BEGIN

	IF EXISTS (SELECT TOP 1 1 FROM FIFO.Reductions)
	BEGIN
		RAISERROR('FIFO.Reductions already populated, skipping',1,-1, -1) 
		RETURN
	END

	DROP TABLE IF EXISTS #Breakage
	SELECT 
		TransactionID AS ReductionSourceID
		, CustomerID
		, PublisherID
		, t.Earning * -1 AS Reduction
		, TranDateTime AS ReductionDateTime
		, 1 AS isBreakage
	INTO #Breakage
	FROM dbo.Transactions t
	WHERE t.EarningSourceID IN 
	(
		2160 -- Breakage - Optout (from SLCPointsNegative)
		, 2158 -- Breakage - Deceased (from SLCPointsNegative)
		, 2159 -- Breakage - Deactivation (from SLCPointsNegative)
		, 2174 -- Breakage Negative Adjustment (from TransactionType)
	)

	CREATE CLUSTERED INDEX CIX ON #Breakage (CustomerID, ReductionDateTime, ReductionSourceID)


	INSERT INTO FIFO.Reductions WITH (TABLOCKX)
	(
		ReductionSourceID
		, CustomerID
		, PublisherID
		, Reduction
		, ReductionDateTime
		, isBreakage
	)
	SELECT
		RedemptionID
		, CustomerID
		, PublisherID
		, RedemptionValue
		, RedemptionDateTime
		, 0 AS isBreakage
	FROM dbo.Redemptions


	INSERT INTO FIFO.Reductions
	(
		ReductionSourceID
		, CustomerID
		, PublisherID
		, Reduction
		, ReductionDateTime
		, isBreakage
	)
	SELECT
		ReductionSourceID
		, CustomerID
		, PublisherID
		, Reduction
		, ReductionDateTime
		, isBreakage
	FROM #Breakage

	DECLARE @CumulativeReductionTo DECIMAL(9,2) = 0
		, @CustomerReductionID INT = 0
		, @PreviousCustomerID INT
		, @isCurrentCustomer TINYINT = 0


	-- Sensitive to order of variables being set if using @Var = Col = @Var i.e. it is possible to see the previous set variable and the currently set variable at the same time
	-- if using Column = @Var, the value of @Var will be the result of the current row
	UPDATE e
	SET 
		@isCurrentCustomer = CASE WHEN CustomerID = @PreviousCustomerID THEN 1 ELSE 0 END -- do before we update the @PreviousCustomerID variable to get the previous row
		, @PreviousCustomerID = PreviousCustomerID = CustomerID -- update variable and column to current customer id
		, @CustomerReductionID = CustomerReductionID = (@CustomerReductionID * @isCurrentCustomer ) + 1 -- if the previous row customer id is different, reset variable to 0
		, @CumulativeReductionTo = CumulativeReductionTo = (@CumulativeReductionTo * @isCurrentCustomer) + Reduction -- if the previous row customer id is different, reset variable to 0
		, CumulativeReductionFrom = @CumulativeReductionTo - Reduction -- Subtract currently set reduction to get the start range of reduction
	FROM FIFO.Reductions  e
	WITH (INDEX(CIX))


END



