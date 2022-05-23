CREATE PROCEDURE [FIFO].[ReductionAllocations_Load]
AS
BEGIN

	IF EXISTS (SELECT TOP 1 1 FROM FIFO.ReductionAllocations)
	BEGIN
		RAISERROR('FIFO.ReductionAllocations already populated, skipping',1,-1, -1) 
		RETURN
	END

	DECLARE @Start INT = 1
		, @Increment INT = 10000
		, @Max INT = (SELECT MAX(CustomerID) FROM dbo.Customer)

	IF OBJECT_ID('tempdb..##ReductCheckpoint') IS NULL
		CREATE TABLE ##ReductCheckpoint
		(
			CustomerID INT
			, InsertDateTIme DATETIME2
		)
	ELSE
		SELECT @Start = ISNULL(MAX(CustomerID), 1) FROM ##ReductCheckpoint
	
	WHILE 1=1
	BEGIN

		INSERT INTO ##ReductCheckpoint
		SELECT @Start, GetDate()
	
		INSERT INTO FIFO.ReductionAllocations 
		(
			CustomerID
			, PublisherID
			, isBreakage
			, ReductionDate
			, Reduction
			, ReductionRemaining
			, EarningDate
			, Earning
			, EarningAllocated
			, EarningRemaining
			, EarningSourceID
			, PaymentCardID
			, PaymentMethodID
			, TranDate
			, ReductionSourceID
			, TransactionID
			, CustomerEarningOrdinal
			, CustomerReductionOrdinal
		)
		SELECT 
			CustomerID
			, PublisherID
			, isBreakage
			, ReductionDate
			, Reduction
			, ReductionRemaining
			, EarningDate = EligibleDate
			, Earning
			, EarningAllocated = 
				CASE WHEN Carry2 = 'BC' 
					THEN CASE 
							WHEN PreviousEarningRemaining > d.Reduction
								THEN Reduction
							ELSE PreviousEarningRemaining 
						END 
					ELSE Earning - EarningRemaining
				END
			, EarningRemaining
			, EarningSourceID
			, PaymentCardID
			, PaymentMethodID
			, TranDate
			, ReductionSourceID
			, TransactionID
			, CustomerEarningOrdinal = CustomerEarningID
			, CustomerReductionOrdinal = CustomerReductionID
		FROM (
			SELECT 
				er.CustomerID
				, er.PublisherID
				, er.EarningSourceID
				, er.EligibleDate
				, er.TranDate
				, er.CustomerEarningID
				, er.TransactionID
				, er.Earning
				, ri.ReductionDate
				, ri.CustomerReductionID
				, ri.ReductionSourceID
				, ri.Reduction
				, er.PaymentMethodID
				, er.PaymentCardID
				, x.EarningRemaining
				, x.ReductionRemaining
				, ri.MinCustomerEarningID
				, ri.MaxCustomerEarningID
				, ri.isBreakage
				, c.Carry
				, c.Carry2
				, PreviousEarningRemaining = LAG(x.EarningRemaining,1,0) OVER(PARTITION BY er.CustomerID ORDER BY er.CustomerEarningID, ri.CustomerReductionID)
			FROM FIFO.Earnings er
			INNER JOIN FIFO.ReductionIntervals ri 
				ON er.CustomerID = ri.CustomerID 
				AND er.CustomerEarningID BETWEEN ri.MinCustomerEarningID AND ri.MaxCustomerEarningID
			CROSS APPLY (
				SELECT
					Carry = CASE
								WHEN er.CustomerEarningID = ri.MaxCustomerEarningID THEN 'E ' -- end
								WHEN er.CustomerEarningID = ri.MinCustomerEarningID AND ri.isCarried = 1 THEN 'BC' -- beginning of a "redemption set" with carryover 
								WHEN er.CustomerEarningID = ri.MinCustomerEarningID THEN 'B ' -- beginning of a "redemption set"
						END,
					Carry2 = CASE
								WHEN er.CustomerEarningID = ri.MinCustomerEarningID AND ri.isCarried = 1 THEN 'BC' -- beginning of a "redemption set" with carryover 
						END
			) c
			CROSS APPLY (
				SELECT 
					EarningRemaining = CASE
						WHEN Earning < 0 THEN 0
						WHEN c.Carry = 'E ' -- When final allocation
								AND (er.[CumulativeEarningTo] > ri.[CumulativeReductionTo]) -- and there is money remanining after allocation
							THEN er.[CumulativeEarningTo] - ri.[CumulativeReductionTo] -- take the difference
						ELSE 0 END, 
					ReductionRemaining = CASE 
						WHEN Earning < 0 
							THEN (ri.[CumulativeReductionTo] - er.[CumulativeEarningTo]) -- When refund, add the amount to the reduction
						WHEN c.Carry = 'E ' -- When final allocation
								AND (er.[CumulativeEarningTo] > ri.[CumulativeReductionTo]) -- and there is money remaining after allocation
							THEN 0
						ELSE ri.[CumulativeReductionTo] - er.[CumulativeEarningTo] END -- take the difference for unallocated reductions
			WHERE er.CustomerID BETWEEN @Start and @Start + @Increment - 1
			) x
		) d

		SET @Start += @Increment

		IF @Start > @Max
			BREAK
	END

	DROP TABLE ##ReductCheckpoint

END





