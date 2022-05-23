CREATE TABLE [dbo].[PaymentCard] (
    [PaymentCardID]           INT           IDENTITY (1, 1) NOT NULL,
    [StartDate]               DATE          NOT NULL,
    [SourcePaymentCardTypeID] SMALLINT      NULL,
    [PaymentCardType]         VARCHAR (40)  NULL,
    [SourceTypeID]            SMALLINT      NOT NULL,
    [SourceID]                VARCHAR (36)  NOT NULL,
    [CreatedDateTime]         DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_PaymentCard] PRIMARY KEY CLUSTERED ([PaymentCardID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_PaymentCard_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_PaymentCard_Source]
    ON [dbo].[PaymentCard]([SourceTypeID] ASC, [SourceID] ASC) WITH (FILLFACTOR = 90);

