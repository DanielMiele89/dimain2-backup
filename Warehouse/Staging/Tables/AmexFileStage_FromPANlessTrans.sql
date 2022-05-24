CREATE TABLE [Staging].[AmexFileStage_FromPANlessTrans] (
    [ID]                        INT          IDENTITY (1, 1) NOT NULL,
    [ImportDate]                DATETIME     NOT NULL,
    [DetailIdentifier]          VARCHAR (1)  NOT NULL,
    [PartnerID]                 VARCHAR (25) NULL,
    [CurrencyCode]              VARCHAR (3)  NOT NULL,
    [MerchantNumber]            VARCHAR (20) NOT NULL,
    [MaskedPAN]                 VARCHAR (16) NOT NULL,
    [RewardOfferID]             VARCHAR (10) NOT NULL,
    [AmexCustomerID]            VARCHAR (25) NOT NULL,
    [TransactionDateSTR]        VARCHAR (10) NOT NULL,
    [TransactionAmountSTR]      VARCHAR (17) NOT NULL,
    [CashbackAmountSTR]         VARCHAR (17) NOT NULL,
    [TransactionDate]           DATE         NOT NULL,
    [TransactionAmount]         MONEY        NOT NULL,
    [CashbackAmount]            MONEY        NOT NULL,
    [NetAmount]                 MONEY        NULL,
    [PublisherID]               INT          NOT NULL,
    [FileID]                    INT          NOT NULL,
    [ImportedToPANlessDateTime] DATETIME     NOT NULL,
    [SourceTableID]             BIGINT       NULL,
    CONSTRAINT [PK_Staging_AmexFileStage_FromPANlessTrans] PRIMARY KEY CLUSTERED ([ID] ASC)
);

