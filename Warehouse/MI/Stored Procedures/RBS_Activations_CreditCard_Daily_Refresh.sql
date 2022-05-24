-- =============================================
-- Author:		JEA
-- Create date: 15/08/2014
-- Description:	Persists activation figures, CB+ and credit card
-- =============================================
CREATE PROCEDURE [MI].[RBS_Activations_CreditCard_Daily_Refresh]

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @RunDate DATE

	SET @RunDate = GETDATE()

	DECLARE
	@ActivationOnlineRegisteredPrevDayNatWest INT,
	@ActivationOnlineUnregisteredPrevDayNatWest INT,
	@ActivationOfflinePrevDayNatWest INT,
	@OptOutOnlinePrevDayNatWest INT,
	@OptOutOfflinePrevDayNatWest INT,
	@DeactivationPrevDayNatWest INT,
	@ActivationOnlineRegisteredCumulNatWest INT,
	@ActivationOnlineUnregisteredCumulNatWest INT,
	@ActivationOfflineCumulNatWest INT,
	@OptOutOnlineCumulNatWest INT,
	@OptOutOfflineCumulNatWest INT,
	@DeactivationCumulNatWest INT,
	@EarnersMonthNatWest INT,
	@EarnersCumulNatWest INT,
	@ActivationOnlineRegisteredPrevDayRBS INT,
	@ActivationOnlineUnregisteredPrevDayRBS INT,
	@ActivationOfflinePrevDayRBS INT,
	@OptOutOnlinePrevDayRBS INT,
	@OptOutOfflinePrevDayRBS INT,
	@DeactivationPrevDayRBS INT,
	@ActivationOnlineRegisteredCumulRBS INT,
	@ActivationOnlineUnregisteredCumulRBS INT,
	@ActivationOfflineCumulRBS INT,
	@OptOutOnlineCumulRBS INT,
	@OptOutOfflineCumulRBS INT,
	@DeactivationCumulRBS INT,
	@EarnersMonthRBS INT,
	@EarnersCumulRBS INT,
	@CCActivationOnlineRegisteredPrevDayNatWest INT,
	@CCActivationOnlineUnregisteredPrevDayNatWest INT,
	@CCActivationOfflinePrevDayNatWest INT,
	@CCAdditionOnlineRegisteredPrevDayNatWest INT,
	@CCAdditionOnlineUnregisteredPrevDayNatWest INT,
	@CCAdditionOfflinePrevDayNatWest INT,
	@CCRemovalOnlinePrevDayNatWest INT,
	@CCRemovalOfflinePrevDayNatWest INT,
	@CCDeactivationPrevDayNatWest INT,
	@CCActivationOnlineRegisteredCumulNatWest INT,
	@CCActivationOnlineUnregisteredCumulNatWest INT,
	@CCActivationOfflineCumulNatWest INT,
	@CCAdditionOnlineRegisteredCumulNatWest INT,
	@CCAdditionOnlineUnregisteredCumulNatWest INT,
	@CCAdditionOfflineCumulNatWest INT,
	@CCRemovalOnlineCumulNatWest INT,
	@CCRemovalOfflineCumulNatWest INT,
	@CCDeactivationCumulNatWest INT,
	@CCActivationOnlineRegisteredPrevDayRBS INT,
	@CCActivationOnlineUnregisteredPrevDayRBS INT,
	@CCActivationOfflinePrevDayRBS INT,
	@CCAdditionOnlineRegisteredPrevDayRBS INT,
	@CCAdditionOnlineUnregisteredPrevDayRBS INT,
	@CCAdditionOfflinePrevDayRBS INT,
	@CCRemovalOnlinePrevDayRBS INT,
	@CCRemovalOfflinePrevDayRBS INT,
	@CCDeactivationPrevDayRBS INT,
	@CCActivationOnlineRegisteredCumulRBS INT,
	@CCActivationOnlineUnregisteredCumulRBS INT,
	@CCActivationOfflineCumulRBS INT,
	@CCAdditionOnlineRegisteredCumulRBS INT,
	@CCAdditionOnlineUnregisteredCumulRBS INT,
	@CCAdditionOfflineCumulRBS INT,
	@CCRemovalOnlineCumulRBS INT,
	@CCRemovalOfflineCumulRBS INT,
	@CCDeactivationCumulRBS INT,
	@PrevDayDate DATE,
	@MonthDate DATE

	CREATE TABLE #Customers(FanID INT PRIMARY KEY, ActivatedDate DATE NOT NULL, OptedOutDate DATE NULL, DeactivatedDate DATE NULL, IsRBS BIT NOT NULL, IsOnline BIT NOT NULL, IsRegistered BIT NOT NULL)

	INSERT INTO #Customers(FanID, ActivatedDate, OptedOutDate, DeactivatedDate, IsRBS, IsOnline, IsRegistered)
	SELECT c.FanID
		, s.ActivatedDate
		, S.OptedOutDate
		, CASE WHEN S.DeactivatedDate IS NOT NULL AND S.OptedOutDate IS NULL THEN s.DeactivatedDate ELSE NULL END
		, S.IsRBS
		, CASE WHEN S.ActivationMethodID = 1 THEN 1 ELSE 0 END
		, CASE WHEN c.Registered = 1 THEN 1 ELSE 0 END
	FROM Relational.Customer c
	INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID

	CREATE NONCLUSTERED INDEX IX_TMP_CustomerActiveCalc ON #Customers(ActivatedDate, OptedOutDate, DeactivatedDate, IsOnline, IsRegistered)

	SET @PrevDayDate = DATEADD(DAY, -1, @RunDate)

	SET @MonthDate = DATEFROMPARTS(YEAR(@PrevDayDate), MONTH(@PrevDayDate), 1)

	--EARNERS
	SELECT @EarnersCumulNatWest = COUNT(DISTINCT pt.FanID) FROM Relational.PartnerTrans PT
										INNER JOIN Relational.Customer C ON PT.FanID = C.FanID
										WHERE pt.CashbackEarned > 0 
										AND c.ClubID = 132

	SELECT @EarnersCumulRBS = COUNT(DISTINCT pt.FanID) FROM Relational.PartnerTrans PT
										INNER JOIN Relational.Customer C ON PT.FanID = C.FanID
										WHERE pt.CashbackEarned > 0 
										AND c.ClubID = 138

	SELECT @EarnersMonthNatWest = COUNT(DISTINCT pt.FanID) FROM Relational.PartnerTrans PT
										INNER JOIN Relational.Customer C ON PT.FanID = C.FanID
										WHERE pt.CashbackEarned > 0 
										AND pt.AddedDate >= @MonthDate
										AND c.ClubID = 132

	SELECT @EarnersMonthRBS = COUNT(DISTINCT pt.FanID) FROM Relational.PartnerTrans PT
										INNER JOIN Relational.Customer C ON PT.FanID = C.FanID
										WHERE pt.CashbackEarned > 0 
										AND pt.AddedDate >= @MonthDate
										AND c.ClubID = 138

	--NAT WEST NON-CREDIT CARD PREVIOUS DAY

	SELECT @ActivationOnlineRegisteredPrevDayNatWest = COUNT(1)
	FROM #Customers
	WHERE ActivatedDate >= @PrevDayDate
	AND IsOnline = 1
	AND IsRegistered = 1
	AND IsRBS = 0

	SELECT @ActivationOnlineUnregisteredPrevDayNatWest = COUNT(1)
	FROM #Customers
	WHERE ActivatedDate >= @PrevDayDate
	AND IsOnline = 1
	AND IsRegistered = 0
	AND IsRBS = 0

	SELECT @ActivationOfflinePrevDayNatWest = COUNT(1)
	FROM #Customers
	WHERE ActivatedDate >= @PrevDayDate
	AND IsOnline = 0
	AND IsRBS = 0

	SELECT @OptOutOnlinePrevDayNatWest = COUNT(1)
	FROM #Customers
	WHERE OptedOutDate >= @PrevDayDate
	AND IsOnline = 1
	AND IsRBS = 0

	SELECT @OptOutOfflinePrevDayNatWest = COUNT(1)
	FROM #Customers
	WHERE OptedOutDate >= @PrevDayDate
	AND IsOnline = 0
	AND IsRBS = 0

	SELECT @DeactivationPrevDayNatWest = COUNT(1)
	FROM #Customers
	WHERE DeactivatedDate >= @PrevDayDate
	AND IsRBS = 0

	--NAT WEST NON-CREDIT CARD CUMULATIVE
	SELECT @ActivationOnlineRegisteredCumulNatWest = COUNT(1)
	FROM #Customers
	WHERE IsOnline = 1
	AND IsRegistered = 1
	AND IsRBS = 0

	SELECT @ActivationOnlineUnregisteredCumulNatWest = COUNT(1)
	FROM #Customers
	WHERE IsOnline = 1
	AND IsRegistered = 0
	AND IsRBS = 0

	SELECT @ActivationOfflineCumulNatWest = COUNT(1)
	FROM #Customers
	WHERE IsOnline = 0
	AND IsRBS = 0

	SELECT @OptOutOnlineCumulNatWest = COUNT(1)
	FROM #Customers
	WHERE OptedOutDate IS NOT NULL
	AND IsOnline = 1
	AND IsRBS = 0

	SELECT @OptOutOfflineCumulNatWest = COUNT(1)
	FROM #Customers
	WHERE OptedOutDate IS NOT NULL
	AND IsOnline = 0
	AND IsRBS = 0

	SELECT @DeactivationCumulNatWest = COUNT(1)
	FROM #Customers
	WHERE DeactivatedDate IS NOT NULL
	AND IsRBS = 0

	----RBS STARTS HERE!!!!!!!!!!!!!!!!!!

	--RBS NON-CREDIT CARD PREVIOUS DAY

	SELECT @ActivationOnlineRegisteredPrevDayRBS = COUNT(1)
	FROM #Customers
	WHERE ActivatedDate >= @PrevDayDate
	AND IsOnline = 1
	AND IsRegistered = 1
	AND IsRBS = 1

	SELECT @ActivationOnlineUnregisteredPrevDayRBS = COUNT(1)
	FROM #Customers
	WHERE ActivatedDate >= @PrevDayDate
	AND IsOnline = 1
	AND IsRegistered = 0
	AND IsRBS = 1

	SELECT @ActivationOfflinePrevDayRBS = COUNT(1)
	FROM #Customers
	WHERE ActivatedDate >= @PrevDayDate
	AND IsOnline = 0
	AND IsRBS = 1

	SELECT @OptOutOnlinePrevDayRBS = COUNT(1)
	FROM #Customers
	WHERE OptedOutDate >= @PrevDayDate
	AND IsOnline = 1
	AND IsRBS = 1

	SELECT @OptOutOfflinePrevDayRBS = COUNT(1)
	FROM #Customers
	WHERE OptedOutDate >= @PrevDayDate
	AND IsOnline = 0
	AND IsRBS = 1

	SELECT @DeactivationPrevDayRBS = COUNT(1)
	FROM #Customers
	WHERE DeactivatedDate >= @PrevDayDate
	AND IsRBS = 1

	--RBS NON-CREDIT CARD CUMULATIVE
	SELECT @ActivationOnlineRegisteredCumulRBS = COUNT(1)
	FROM #Customers
	WHERE IsOnline = 1
	AND IsRegistered = 1
	AND IsRBS = 1

	SELECT @ActivationOnlineUnregisteredCumulRBS = COUNT(1)
	FROM #Customers
	WHERE IsOnline = 1
	AND IsRegistered = 0
	AND IsRBS = 1

	SELECT @ActivationOfflineCumulRBS = COUNT(1)
	FROM #Customers
	WHERE IsOnline = 0
	AND IsRBS = 1

	SELECT @OptOutOnlineCumulRBS = COUNT(1)
	FROM #Customers
	WHERE OptedOutDate IS NOT NULL
	AND IsOnline = 1
	AND IsRBS = 1

	SELECT @OptOutOfflineCumulRBS = COUNT(1)
	FROM #Customers
	WHERE OptedOutDate IS NOT NULL
	AND IsOnline = 0
	AND IsRBS = 1

	SELECT @DeactivationCumulRBS = COUNT(1)
	FROM #Customers
	WHERE DeactivatedDate IS NOT NULL
	AND IsRBS = 1

	--CREDIT CARD STARTS HERE!

	CREATE TABLE #PayMethods(CustomerPaymentMethodsAvailableID INT PRIMARY KEY
		, FanID INT NOT NULL
		, PaymentMethodsAvailableID TINYINT NOT NULL
		, StartDate DATE NOT NULL
		, EndDate DATE NULL
		, PrevMethodID TINYINT NULL
		, NextMethodID TINYINT NULL
		, FirstEntry INT NOT NULL
		, LastEntry INT NOT NULL)

	CREATE TABLE #CreditCardStatusChange(ID INT PRIMARY KEY IDENTITY
		, FanID INT NOT NULL
		, CreditCardStatus VARCHAR(50) NOT NULL
		, StatusDate DATE NOT NULL)

	INSERT INTO #PayMethods
	(CustomerPaymentMethodsAvailableID
		, FanID
		, PaymentMethodsAvailableID
		, StartDate
		, EndDate
		, PrevMethodID
		, NextMethodID
		, FirstEntry
		, LastEntry)

	--use window functions to capture previous and following IDs in the data set
	SELECT CustomerPaymentMethodsAvailableID
		, FanID
		, PaymentMethodsAvailableID
		, StartDate
		, EndDate
		, PrevMethodID
		, NextMethodID
		, FIRST_VALUE(CustomerPaymentMethodsAvailableID) OVER (PARTITION BY FanID ORDER BY StartDate) As FirstEntry
		, LAST_VALUE(CustomerPaymentMethodsAvailableID) OVER (PARTITION BY FanID ORDER BY StartDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) As LastEntry
	FROM
	(
		SELECT CustomerPaymentMethodsAvailableID, FanID, PaymentMethodsAvailableID, StartDate, EndDate
			, LAG(PaymentMethodsAvailableID, 1) OVER (PARTITION BY FanID ORDER BY StartDate) AS PrevMethodID
			, LEAD(PaymentMethodsAvailableID, 1) OVER (PARTITION BY FanID ORDER BY StartDate) AS NextMethodID
		FROM Relational.CustomerPaymentMethodsAvailable
	) c
	WHERE PaymentMethodsAvailableID IN (1,2)

	INSERT INTO #CreditCardStatusChange(FanID
		, CreditCardStatus
		, StatusDate)
	SELECT FanID, 'Activation', StartDate
	FROM #PayMethods
	WHERE PrevMethodID IS NULL
	AND CustomerPaymentMethodsAvailableID = FirstEntry

	INSERT INTO #CreditCardStatusChange(FanID
		, CreditCardStatus
		, StatusDate)
	SELECT FanID, 'Addition', StartDate
	FROM #PayMethods
	WHERE PrevMethodID IS NOT NULL
	AND CustomerPaymentMethodsAvailableID = FirstEntry

	INSERT INTO #CreditCardStatusChange(FanID
		, CreditCardStatus
		, StatusDate)
	SELECT FanID, 'Removal', StartDate
	FROM #PayMethods
	WHERE NextMethodID IS NOT NULL
	AND CustomerPaymentMethodsAvailableID = LastEntry

	CREATE TABLE #CreditActiveCustomers(FanID INT PRIMARY KEY)

	--gather list of all customers who have a credit card which has NOT been removed - deactivations irrelevant where credit card has been removed
	INSERT INTO #CreditActiveCustomers(FanID)
	SELECT DISTINCT FanID
	FROM #PayMethods
	EXCEPT --excludes removal FanIDs
	SELECT DISTINCT FanID
	FROM #CreditCardStatusChange
	WHERE CreditCardStatus = 'Removal'

	--use temp table to specify where customer deactivation is relevant to credit card holding
	INSERT INTO #CreditCardStatusChange(FanID, CreditCardStatus, StatusDate)
	SELECT c.FanID, 'Deactivation', COALESCE(OptedOutDate, DeactivatedDate)
	FROM #Customers c
	INNER JOIN #CreditActiveCustomers a ON c.FanID = a.FanID
	WHERE c.OptedOutDate IS NOT NULL
	OR c.DeactivatedDate IS  NOT NULL

	--index to assist customer matching
	CREATE NONCLUSTERED INDEX IX_TMP_CreditCardStatusChange_FanID ON #CreditCardStatusChange(FanID)

	--nat west previous day

	SELECT @CCActivationOnlineRegisteredPrevDayNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 1
	AND c.IsRegistered = 1
	AND c.IsRBS = 0

	SELECT @CCActivationOnlineUnregisteredPrevDayNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 1
	AND c.IsRegistered = 0
	AND c.IsRBS = 0

	SELECT @CCActivationOfflinePrevDayNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 0
	AND c.IsRBS = 0

	SELECT @CCAdditionOnlineRegisteredPrevDayNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 1
	AND c.IsRegistered = 1
	AND c.IsRBS = 0

	SELECT @CCAdditionOnlineUnregisteredPrevDayNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 1
	AND c.IsRegistered = 0
	AND c.IsRBS = 0

	SELECT @CCAdditionOfflinePrevDayNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 0
	AND c.IsRBS = 0

	SELECT @CCRemovalOnlinePrevDayNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Removal'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 1
	AND c.IsRBS = 0

	SELECT @CCRemovalOfflinePrevDayNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Removal'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 0
	AND c.IsRBS = 0

	SELECT @CCDeactivationPrevDayNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Deactivation'
	AND S.StatusDate >= @RunDate
	AND c.IsRBS = 0

	--natwest cumulative

	SELECT @CCActivationOnlineRegisteredCumulNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND c.IsOnline = 1
	AND c.IsRegistered = 1
	AND c.IsRBS = 0

	SELECT @CCActivationOnlineUnregisteredCumulNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND c.IsOnline = 1
	AND c.IsRegistered = 0
	AND c.IsRBS = 0

	SELECT @CCActivationOfflineCumulNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND c.IsOnline = 0
	AND c.IsRBS = 0

	SELECT @CCAdditionOnlineRegisteredCumulNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND c.IsOnline = 1
	AND c.IsRegistered = 1
	AND c.IsRBS = 0

	SELECT @CCAdditionOnlineUnregisteredCumulNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND c.IsOnline = 1
	AND c.IsRegistered = 0
	AND c.IsRBS = 0

	SELECT @CCAdditionOfflineCumulNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND c.IsOnline = 0
	AND c.IsRBS = 0

	SELECT @CCRemovalOnlineCumulNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Removal'
	AND c.IsOnline = 1
	AND c.IsRBS = 0

	SELECT @CCRemovalOfflineCumulNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Removal'
	AND c.IsOnline = 0
	AND c.IsRBS = 0

	SELECT @CCDeactivationCumulNatWest = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Deactivation'
	AND c.IsRBS = 0

	--RBS Credit Card

	--RBS previous day

	SELECT @CCActivationOnlineRegisteredPrevDayRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 1
	AND c.IsRegistered = 1
	AND c.IsRBS = 1

	SELECT @CCActivationOnlineUnregisteredPrevDayRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 1
	AND c.IsRegistered = 0
	AND c.IsRBS = 1

	SELECT @CCActivationOfflinePrevDayRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 0
	AND c.IsRBS = 1

	SELECT @CCAdditionOnlineRegisteredPrevDayRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 1
	AND c.IsRegistered = 1
	AND c.IsRBS = 1

	SELECT @CCAdditionOnlineUnregisteredPrevDayRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 1
	AND c.IsRegistered = 0
	AND c.IsRBS = 1

	SELECT @CCAdditionOfflinePrevDayRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 0
	AND c.IsRBS = 1

	SELECT @CCRemovalOnlinePrevDayRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Removal'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 1
	AND c.IsRBS = 1

	SELECT @CCRemovalOfflinePrevDayRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Removal'
	AND S.StatusDate >= @RunDate
	AND c.IsOnline = 0
	AND c.IsRBS = 1

	SELECT @CCDeactivationPrevDayRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Deactivation'
	AND S.StatusDate >= @RunDate
	AND c.IsRBS = 1

	--rbs cumulative

	SELECT @CCActivationOnlineRegisteredCumulRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND c.IsOnline = 1
	AND c.IsRegistered = 1
	AND c.IsRBS = 1

	SELECT @CCActivationOnlineUnregisteredCumulRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND c.IsOnline = 1
	AND c.IsRegistered = 0
	AND c.IsRBS = 1

	SELECT @CCActivationOfflineCumulRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Activation'
	AND c.IsOnline = 0
	AND c.IsRBS = 1

	SELECT @CCAdditionOnlineRegisteredCumulRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND c.IsOnline = 1
	AND c.IsRegistered = 1
	AND c.IsRBS = 1

	SELECT @CCAdditionOnlineUnregisteredCumulRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND c.IsOnline = 1
	AND c.IsRegistered = 0
	AND c.IsRBS = 1

	SELECT @CCAdditionOfflineCumulRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Addition'
	AND c.IsOnline = 0
	AND c.IsRBS = 1

	SELECT @CCRemovalOnlineCumulRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Removal'
	AND c.IsOnline = 1
	AND c.IsRBS = 1

	SELECT @CCRemovalOfflineCumulRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Removal'
	AND c.IsOnline = 0
	AND c.IsRBS = 1

	SELECT @CCDeactivationCumulRBS = COUNT(1)
	FROM #CreditCardStatusChange s
	INNER JOIN #Customers C ON s.FanID = c.FanID
	WHERE s.CreditCardStatus = 'Deactivation'
	AND c.IsRBS = 1

	--INSERT VALUES
	INSERT INTO MI.RBS_Activations_CreditCard_Daily
	(
		ActivationOnlineRegisteredPrevDayNatWest,
		ActivationOnlineUnregisteredPrevDayNatWest,
		ActivationOfflinePrevDayNatWest,
		OptOutOnlinePrevDayNatWest,
		OptOutOfflinePrevDayNatWest,
		DeactivationPrevDayNatWest,
		ActivationOnlineRegisteredCumulNatWest,
		ActivationOnlineUnregisteredCumulNatWest,
		ActivationOfflineCumulNatWest,
		OptOutOnlineCumulNatWest,
		OptOutOfflineCumulNatWest,
		DeactivationCumulNatWest,
		EarnersMonthNatWest,
		EarnersCumulNatWest,
		ActivationOnlineRegisteredPrevDayRBS,
		ActivationOnlineUnregisteredPrevDayRBS,
		ActivationOfflinePrevDayRBS,
		OptOutOnlinePrevDayRBS,
		OptOutOfflinePrevDayRBS,
		DeactivationPrevDayRBS,
		ActivationOnlineRegisteredCumulRBS,
		ActivationOnlineUnregisteredCumulRBS,
		ActivationOfflineCumulRBS,
		OptOutOnlineCumulRBS,
		OptOutOfflineCumulRBS,
		DeactivationCumulRBS,
		EarnersMonthRBS,
		EarnersCumuRBS,
		CCActivationOnlineRegisteredPrevDayNatWest,
		CCActivationOnlineUnregisteredPrevDayNatWest,
		CCActivationOfflinePrevDayNatWest,
		CCAdditionOnlineRegisteredPrevDayNatWest,
		CCAdditionOnlineUnregisteredPrevDayNatWest,
		CCAdditionOfflinePrevDayNatWest,
		CCRemovalOnlinePrevDayNatWest,
		CCRemovalOfflinePrevDayNatWest,
		CCDeactivationPrevDayNatWest,
		CCActivationOnlineRegisteredCumulNatWest,
		CCActivationOnlineUnregisteredCumulNatWest,
		CCActivationOfflineCumulNatWest,
		CCAdditionOnlineRegisteredCumulNatWest,
		CCAdditionOnlineUnregisteredCumulNatWest,
		CCAdditionOfflineCumulNatWest,
		CCRemovalOnlineCumulNatWest,
		CCRemovalOfflineCumulNatWest,
		CCDeactivationCumulNatWest,
		CCActivationOnlineRegisteredPrevDayRBS,
		CCActivationOnlineUnregisteredPrevDayRBS,
		CCActivationOfflinePrevDayRBS,
		CCAdditionOnlineRegisteredPrevDayRBS,
		CCAdditionOnlineUnregisteredPrevDayRBS,
		CCAdditionOfflinePrevDayRBS,
		CCRemovalOnlinePrevDayRBS,
		CCRemovalOfflinePrevDayRBS,
		CCDeactivationPrevDayRBS,
		CCActivationOnlineRegisteredCumulRBS,
		CCActivationOnlineUnregisteredCumulRBS,
		CCActivationOfflineCumulRBS,
		CCAdditionOnlineRegisteredCumulRBS,
		CCAdditionOnlineUnregisteredCumulRBS,
		CCAdditionOfflineCumulRBS,
		CCRemovalOnlineCumulRBS,
		CCRemovalOfflineCumulRBS,
		CCDeactivationCumulRBS
	)
	VALUES
	(
		ISNULL(@ActivationOnlineRegisteredPrevDayNatWest,0)
		, ISNULL(@ActivationOnlineUnregisteredPrevDayNatWest,0)
		, ISNULL(@ActivationOfflinePrevDayNatWest,0)
		, ISNULL(@OptOutOnlinePrevDayNatWest,0)
		, ISNULL(@OptOutOfflinePrevDayNatWest,0)
		, ISNULL(@DeactivationPrevDayNatWest,0)
		, ISNULL(@ActivationOnlineRegisteredCumulNatWest,0)
		, ISNULL(@ActivationOnlineUnregisteredCumulNatWest,0)
		, ISNULL(@ActivationOfflineCumulNatWest,0)
		, ISNULL(@OptOutOnlineCumulNatWest,0)
		, ISNULL(@OptOutOfflineCumulNatWest,0)
		, ISNULL(@DeactivationCumulNatWest,0)
		, ISNULL(@EarnersMonthNatWest,0)
		, ISNULL(@EarnersCumulNatWest,0)
		, ISNULL(@ActivationOnlineRegisteredPrevDayRBS,0)
		, ISNULL(@ActivationOnlineUnregisteredPrevDayRBS,0)
		, ISNULL(@ActivationOfflinePrevDayRBS,0)
		, ISNULL(@OptOutOnlinePrevDayRBS,0)
		, ISNULL(@OptOutOfflinePrevDayRBS,0)
		, ISNULL(@DeactivationPrevDayRBS,0)
		, ISNULL(@ActivationOnlineRegisteredCumulRBS,0)
		, ISNULL(@ActivationOnlineUnregisteredCumulRBS,0)
		, ISNULL(@ActivationOfflineCumulRBS,0)
		, ISNULL(@OptOutOnlineCumulRBS,0)
		, ISNULL(@OptOutOfflineCumulRBS,0)
		, ISNULL(@DeactivationCumulRBS,0)
		, ISNULL(@EarnersMonthRBS,0)
		, ISNULL(@EarnersCumulRBS,0)
		, ISNULL(@CCActivationOnlineRegisteredPrevDayNatWest,0)
		, ISNULL(@CCActivationOnlineUnregisteredPrevDayNatWest,0)
		, ISNULL(@CCActivationOfflinePrevDayNatWest,0)
		, ISNULL(@CCAdditionOnlineRegisteredPrevDayNatWest,0)
		, ISNULL(@CCAdditionOnlineUnregisteredPrevDayNatWest,0)
		, ISNULL(@CCAdditionOfflinePrevDayNatWest,0)
		, ISNULL(@CCRemovalOnlinePrevDayNatWest,0)
		, ISNULL(@CCRemovalOfflinePrevDayNatWest,0)
		, ISNULL(@CCDeactivationPrevDayNatWest,0)
		, ISNULL(@CCActivationOnlineRegisteredCumulNatWest,0)
		, ISNULL(@CCActivationOnlineUnregisteredCumulNatWest,0)
		, ISNULL(@CCActivationOfflineCumulNatWest,0)
		, ISNULL(@CCAdditionOnlineRegisteredCumulNatWest,0)
		, ISNULL(@CCAdditionOnlineUnregisteredCumulNatWest,0)
		, ISNULL(@CCAdditionOfflineCumulNatWest,0)
		, ISNULL(@CCRemovalOnlineCumulNatWest,0)
		, ISNULL(@CCRemovalOfflineCumulNatWest,0)
		, ISNULL(@CCDeactivationCumulNatWest,0)
		, ISNULL(@CCActivationOnlineRegisteredPrevDayRBS,0)
		, ISNULL(@CCActivationOnlineUnregisteredPrevDayRBS,0)
		, ISNULL(@CCActivationOfflinePrevDayRBS,0)
		, ISNULL(@CCAdditionOnlineRegisteredPrevDayRBS,0)
		, ISNULL(@CCAdditionOnlineUnregisteredPrevDayRBS,0)
		, ISNULL(@CCAdditionOfflinePrevDayRBS,0)
		, ISNULL(@CCRemovalOnlinePrevDayRBS,0)
		, ISNULL(@CCRemovalOfflinePrevDayRBS,0)
		, ISNULL(@CCDeactivationPrevDayRBS,0)
		, ISNULL(@CCActivationOnlineRegisteredCumulRBS,0)
		, ISNULL(@CCActivationOnlineUnregisteredCumulRBS,0)
		, ISNULL(@CCActivationOfflineCumulRBS,0)
		, ISNULL(@CCAdditionOnlineRegisteredCumulRBS,0)
		, ISNULL(@CCAdditionOnlineUnregisteredCumulRBS,0)
		, ISNULL(@CCAdditionOfflineCumulRBS,0)
		, ISNULL(@CCRemovalOnlineCumulRBS,0)
		, ISNULL(@CCRemovalOfflineCumulRBS,0)
		, ISNULL(@CCDeactivationCumulRBS,0)
	)

END