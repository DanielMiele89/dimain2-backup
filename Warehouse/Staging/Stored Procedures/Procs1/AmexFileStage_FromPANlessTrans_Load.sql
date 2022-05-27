/******************************************************************************
Author: Jason Shipp
Created: 30/05/2019
Purpose: 
	- Load new AMEX-type file transaction data (AMEX, Visa etc.) from the SLC_REPORT.RAS.PANless_Transaction table into the Warehouse.Staging.AmexFileStage_FromPANlessTrans table, for loading into BI.SchemeTrans in APW
	- Log loaded data in the Warehouse.Staging.PANlessTrans_To_SchemeTrans_DateLog table, using the timestamp of when the data was added to the Warehouse.Staging.AmexFileStage_FromPANlessTrans table
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 23/10/2019
	- Added condition to join to nFI.Relational.AmexOffer to handle Visa self-funded transactions

Jason Shipp 20/01/2020
	- Added NetAmount (Investment excluding VAT) to load

******************************************************************************/
CREATE PROCEDURE [Staging].[AmexFileStage_FromPANlessTrans_Load]
	
AS
BEGIN

	SET NOCOUNT ON;

	-- Declare variables

	DECLARE @Now datetime = GETDATE();

	-- Clear staging table

	-- TRUNCATE TABLE Warehouse.Staging.AmexFileStage_FromPANlessTrans; -- This is done in SSIS

	-- Create temp table for storing timestamps associated with new rows picked up from the RAS.PANless_Transaction table

	IF OBJECT_ID('tempdb..#NewDateTimes') IS NOT NULL DROP TABLE #NewDateTimes;
	CREATE TABLE #NewDateTimes (ImportedToPANlessDateTime datetime NOT NULL);

	

	IF OBJECT_ID('tempdb..#CRT_File') IS NOT NULL DROP TABLE #CRT_File;
	SELECT *
	INTO #CRT_File
	FROM [SLC_REPL].[dbo].[CRT_File]
	WHERE MatcherShortName NOT IN ('VGN')

	CREATE CLUSTERED INDEX CIX_ID ON #CRT_File (ID)

	-- Load transaction data into the staging table, where the timestamp is new

	INSERT INTO [Staging].[AmexFileStage_FromPANlessTrans] (ImportDate
														,	DetailIdentifier
														,	PartnerID
														,	CurrencyCode
														,	MerchantNumber
														,	MaskedPAN
														,	RewardOfferID
														,	AmexCustomerID
														,	TransactionDateSTR
														,	TransactionAmountSTR
														,	CashbackAmountSTR
														,	TransactionDate
														,	TransactionAmount
														,	CashbackAmount
														,	NetAmount
														,	PublisherID
														,	FileID
														,	ImportedToPANlessDateTime
														,	SourceTableID)
	OUTPUT INSERTED.ImportedToPANlessDateTime INTO #NewDateTimes (ImportedToPANlessDateTime) -- Record new timestamps loaded into staging table
	SELECT	ImportDate = @Now
		,	DetailIdentifier = 'D'
		,	PartnerID = onp.PublisherCodeRawFiles -- Legacy- this is related to the publisher, not a retailer. Useful for confirming the offer exists in the nFI.Relational.AmexOffer table
		,	CurrencyCode = 'GBP'
		,	MerchantNumber = pt.MerchantNumber
		,	MaskedPAN = pt.MaskedCardNumber
		,	RewardOfferID =	CASE
								WHEN pt.PublisherOfferCode = 'TA' THEN pt.OfferCode
								ELSE pt.PublisherOfferCode
							END
		,	AmexCustomerID = pt.CustomerID
		,	TransactionDateSTR = CAST(pt.TransactionDate AS date) -- Legacy
		,	TransactionAmountSTR = pt.Price  -- Legacy
		,	CashbackAmountSTR = pt.CashbackEarned  -- Legacy
		,	TransactionDate = CAST(pt.TransactionDate AS date)
		,	TransactionAmount = pt.Price
		,	CashbackAmount = pt.CashbackEarned
		,	NetAmount = pt.NetAmount
		,	PublisherID = onp.PublisherID
		,	FileID = pt.FileID
		,	ImportedToPANlessDateTime = pt.AddedDate
		,	SourceTableID = pt.ID
	FROM [DIMAIN_TR].[SLC_REPL].[RAS].[PANless_Transaction] pt
	LEFT JOIN [nFI].[Relational].[AmexOffer] ao -- Load will fail if offer does not exist in this table
		ON pt.PublisherOfferCode = ao.AmexOfferID
		OR (pt.PublisherOfferCode = 'TA' AND pt.OfferCode = ao.AmexOfferID) -- To handle Visa self-funded
	LEFT JOIN [Staging].[AmexOfferStage_OfferNameToPublisher] onp
		ON ao.PublisherID = onp.PublisherID
	WHERE EXISTS (	SELECT 1
					FROM #CRT_File crt
					WHERE pt.FileID = crt.ID)
	AND pt.PublisherOfferCode IS NOT NULL -- Check transaction is AMEX-type (not MTR)
	AND pt.CustomerID IS NOT NULL
	AND NOT EXISTS (SELECT NULL	--	Check AddedDate timestamp has not been logged, so is new
					FROM [Staging].[PANlessTrans_To_SchemeTrans_DateLog] l
					WHERE pt.AddedDate = l.ImportedToPANlessDateTime);

	-- Update log table with new timestamps

	INSERT INTO [Staging].[PANlessTrans_To_SchemeTrans_DateLog] (ImportedToPANlessDateTime, LoggedDateTime)
	SELECT	DISTINCT
			ImportedToPANlessDateTime = ImportedToPANlessDateTime
		,	LoggedDateTime = @Now
	FROM #NewDateTimes;

	/******************************************************************************
	-- Create staging tables
	
	CREATE TABLE Warehouse.Staging.PANlessTrans_To_SchemeTrans_DateLog (
		ID int IDENTITY (1,1) NOT NULL
		, ImportedToPANlessDateTime datetime NOT NULL
		, LoggedDateTime datetime  NOT NULL
		, CONSTRAINT PK_PANlessTrans_To_SchemeTrans_DateLog PRIMARY KEY (ImportToPANlessDateTime)
	);

	CREATE TABLE Warehouse.Staging.AmexFileStage_FromPANlessTrans (
		ID int IDENTITY(1,1) NOT NULL
		, ImportDate datetime NOT NULL
		, DetailIdentifier varchar(1) NOT NULL
		, PartnerID varchar(8) NOT NULL
		, CurrencyCode varchar(3) NOT NULL
		, MerchantNumber varchar(20) NOT NULL
		, MaskedPAN varchar(16) NOT NULL
		, RewardOfferID varchar(10) NOT NULL
		, AmexCustomerID varchar(25) NOT NULL
		, TransactionDateSTR varchar(10) NOT NULL
		, TransactionAmountSTR varchar(17) NOT NULL
		, CashbackAmountSTR varchar(17) NOT NULL
		, TransactionDate date NOT NULL
		, TransactionAmount money NOT NULL
		, CashbackAmount money NOT NULL
		, NetAmount money
		, PublisherID int NOT NULL
		, FileID int NOT NULL
		, ImportedToPANlessDateTime datetime NOT NULL
		CONSTRAINT PK_Staging_AmexFileStage_FromPANlessTrans PRIMARY KEY CLUSTERED (ID)
	);
	******************************************************************************/

END
