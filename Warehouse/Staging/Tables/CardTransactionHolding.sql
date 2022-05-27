CREATE TABLE [Staging].[CardTransactionHolding] (
    [FileID]                 INT           NOT NULL,
    [RowNum]                 INT           NOT NULL,
    [BrandMIDID]             INT           NULL,
    [BankIDString]           VARCHAR (4)   NULL,
    [BankID]                 TINYINT       NULL,
    [TerminalID]             VARCHAR (8)   NULL,
    [MID]                    VARCHAR (50)  NOT NULL,
    [Narrative]              VARCHAR (22)  NOT NULL,
    [LocationAddress]        VARCHAR (18)  NOT NULL,
    [LocationCountry]        VARCHAR (3)   NOT NULL,
    [MCC]                    VARCHAR (4)   NOT NULL,
    [CardholderPresentData]  CHAR (1)      NOT NULL,
    [TranDateString]         VARCHAR (10)  NULL,
    [TranDate]               SMALLDATETIME NULL,
    [InDate]                 SMALLDATETIME NULL,
    [PaymentCardID]          INT           NULL,
    [CIN]                    VARCHAR (20)  NULL,
    [CINID]                  INT           NULL,
    [Amount]                 MONEY         NOT NULL,
    [IsOnline]               BIT           NULL,
    [IsRefund]               BIT           NULL,
    [OriginatorID]           VARCHAR (11)  NOT NULL,
    [PostStatus]             CHAR (1)      NOT NULL,
    [MCCID]                  SMALLINT      NULL,
    [PostStatusID]           TINYINT       NULL,
    [CardholderPresentID]    TINYINT       NULL,
    [LocationID]             INT           NULL,
    [BrandCombinationID]     INT           NULL,
    [SecondaryCombinationID] INT           NULL,
    [RequiresSecondaryID]    BIT           CONSTRAINT [DF_Staging_CardTransactionHolding_RequiresSecondaryID] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [pk_CardTransactionHolding] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 80)
);




GO
GRANT SELECT
    ON OBJECT::[Staging].[CardTransactionHolding] TO [gas]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Staging].[CardTransactionHolding] TO [gas]
    AS [dbo];

