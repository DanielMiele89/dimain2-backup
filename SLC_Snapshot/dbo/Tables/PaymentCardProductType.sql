CREATE TABLE [dbo].[PaymentCardProductType] (
    [PaymentCardID]     INT           NOT NULL,
    [ProductTypeID]     INT           NOT NULL,
    [AccountIdentifier] NVARCHAR (11) NULL,
    CONSTRAINT [PK_PaymentCardProductType_PaymentCardID] PRIMARY KEY CLUSTERED ([PaymentCardID] ASC)
);

