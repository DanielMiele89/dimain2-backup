CREATE TABLE [Prototype].[Ijaz_Zinio] (
    [ConsumerCombinationID] INT          NOT NULL,
    [BrandID]               SMALLINT     NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [LocationCountry]       VARCHAR (3)  NOT NULL,
    [OriginatorID]          VARCHAR (11) NOT NULL,
    [IsUKSpend]             BIT          NOT NULL,
    [TranDate]              DATE         NOT NULL,
    [Amount]                MONEY        NOT NULL,
    [IsRefund]              BIT          NOT NULL,
    [IsOnline]              BIT          NOT NULL,
    [PaymentTypeID]         TINYINT      NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IDX_CCID]
    ON [Prototype].[Ijaz_Zinio]([ConsumerCombinationID] ASC);

