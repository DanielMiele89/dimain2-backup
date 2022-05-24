CREATE TABLE [Staging].[__Transactions_Archived] (
    [FileID]                INT          NULL,
    [RowNum]                INT          NULL,
    [BankID]                VARCHAR (4)  NULL,
    [MID]                   VARCHAR (50) NULL,
    [Narrative]             VARCHAR (22) NULL,
    [LocationAddress]       VARCHAR (18) NULL,
    [LocationCountry]       VARCHAR (3)  NULL,
    [MCC]                   VARCHAR (4)  NULL,
    [CardholderPresentData] CHAR (1)     NULL,
    [TranDate]              VARCHAR (10) NULL,
    [PaymentCardID]         INT          NULL,
    [Amount]                MONEY        NULL,
    [OriginatorID]          VARCHAR (11) NULL,
    [PostStatus]            CHAR (1)     NULL,
    [CardInputMode]         CHAR (1)     NULL,
    [PaymentTypeID]         TINYINT      NULL,
    [IsOnline]              INT          NOT NULL,
    [IsRefund]              INT          NOT NULL,
    [MCCID]                 INT          NULL,
    [BrandMID_Type]         VARCHAR (3)  NULL,
    [CC_ID]                 INT          NULL,
    [BrandID]               INT          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_Stuff]
    ON [Staging].[__Transactions_Archived]([FileID] ASC, [RowNum] ASC) WITH (DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_Narrative]
    ON [Staging].[__Transactions_Archived]([Narrative] ASC)
    INCLUDE([BrandMID_Type]);

