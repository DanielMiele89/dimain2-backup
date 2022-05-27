/******************************************************************************
Author: Jason Shipp
Created: 23/05/2018
Purpose: 
	- Loads ConsumerTransactions for the partner being reported on for the analysis period into Warehouse.Staging.FlashOfferReport_ConsumerTransaction
	- Data loaded from ConsumerTransaction and ConsumerTransactionHolding
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 14/11/2018
	- Drop alternate index on Staging.FlashOfferReport_ConsumerTransaction, if it exists 

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Load_ConsumerTransaction
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Load values to constrain rows from Warehouse.Relational.ConsumerTransaction
	******************************************************************************/

	DECLARE @AnalysisStartDate date = (SELECT MIN(StartDate) FROM Warehouse.Staging.FlashOfferReport_All_offers);
	DECLARE @AnalysisEndDate date = (SELECT MAX(EndDate) FROM Warehouse.Staging.FlashOfferReport_All_offers);

	/******************************************************************************
	Clear and drop any indexes on Warehouse.Staging.FlashOfferReport_ConsumerTransaction
	******************************************************************************/

	TRUNCATE TABLE Warehouse.Staging.FlashOfferReport_ConsumerTransaction;

	IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'IX_FlashOfferReport_ConsumerTransaction_MainCover')
		DROP INDEX IX_FlashOfferReport_ConsumerTransaction_MainCover ON Warehouse.Staging.FlashOfferReport_ConsumerTransaction;

	IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'IX_FlashOfferReport_ConsumerTransaction_MainCoverV2')
		DROP INDEX IX_FlashOfferReport_ConsumerTransaction_MainCoverV2 ON Warehouse.Staging.FlashOfferReport_ConsumerTransaction;

	/******************************************************************************
	Load ConsumerTransactions for the partner being reported on for the analysis period (done using SSIS package)

	-- Create table for storing results:		

	CREATE TABLE Warehouse.Staging.FlashOfferReport_ConsumerTransaction (
		PartnerID int NOT NULL
		, FileID int NOT NULL
		, RowNum int NOT NULL
		, ConsumerCombinationID int NOT NULL
		, SecondaryCombinationID int
		, BankID tinyint NOT NULL
		, LocationID int NOT NULL
		, CardholderPresentData tinyint NOT NULL
		, TranDate date NOT NULL
		, CINID int NOT NULL
		, Amount money NOT NULL
		, IsRefund bit NOT NULL
		, IsOnline bit NOT NULL
		, InputModeID tinyint NOT NULL
		, PostStatusID tinyint NOT NULL
		, PaymentTypeID tinyint NOT NULL CONSTRAINT DF_Relational_ConsumerTransaction_Partitioned_PaymentTypeID DEFAULT (1)
		, CONSTRAINT PK_FlashOfferReport_ConsumerTransaction PRIMARY KEY CLUSTERED (FileID ASC, RowNum ASC, TranDate ASC)
	)
	******************************************************************************/

	-- Data from ConsumerTransaction

	--INSERT INTO Warehouse.Staging.FlashOfferReport_ConsumerTransaction (
	--	PartnerID
	--	, FileID
	--	, RowNum
	--	, ConsumerCombinationID
	--	, SecondaryCombinationID
	--	, BankID
	--	, LocationID
	--	, CardholderPresentData
	--	, TranDate
	--	, CINID
	--	, Amount
	--	, IsRefund
	--	, IsOnline
	--	, InputModeID
	--	, PostStatusID
	--	, PaymentTypeID
	--)
	
	SELECT 
		cc.PartnerID
		, ct.FileID
		, ct.RowNum
		, ct.ConsumerCombinationID
		, ct.SecondaryCombinationID
		, ct.BankID
		, ct.LocationID
		, ct.CardholderPresentData
		, ct.TranDate
		, ct.CINID
		, ct.Amount
		, ct.IsRefund
		, ct.IsOnline
		, ct.InputModeID
		, ct.PostStatusID
		, ct.PaymentTypeID
	FROM Warehouse.Relational.ConsumerTransaction ct WITH(NOLOCK)
	INNER JOIN Warehouse.Staging.FlashOfferReport_ConsumerCombinations cc
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID 
	WHERE
		ct.TranDate BETWEEN @AnalysisStartDate AND @AnalysisEndDate

	-- Data from ConsumerTransactionHolding

	--INSERT INTO Warehouse.Staging.FlashOfferReport_ConsumerTransaction (
	--	PartnerID
	--	, FileID
	--	, RowNum
	--	, ConsumerCombinationID
	--	, SecondaryCombinationID
	--	, BankID
	--	, LocationID
	--	, CardholderPresentData
	--	, TranDate
	--	, CINID
	--	, Amount
	--	, IsRefund
	--	, IsOnline
	--	, InputModeID
	--	, PostStatusID
	--	, PaymentTypeID
	--)

	UNION ALL
	
	SELECT
		cc.PartnerID 
		, ct.FileID
		, ct.RowNum
		, ct.ConsumerCombinationID
		, ct.SecondaryCombinationID
		, ct.BankID
		, ct.LocationID
		, ct.CardholderPresentData
		, ct.TranDate
		, ct.CINID
		, ct.Amount
		, ct.IsRefund
		, ct.IsOnline
		, ct.InputModeID
		, ct.PostStatusID
		, ct.PaymentTypeID
	From Warehouse.Relational.ConsumerTransactionHolding ct WITH(NOLOCK)
	INNER JOIN Warehouse.Staging.FlashOfferReport_ConsumerCombinations cc
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID 
	WHERE
		ct.TranDate BETWEEN @AnalysisStartDate AND @AnalysisEndDate;

END