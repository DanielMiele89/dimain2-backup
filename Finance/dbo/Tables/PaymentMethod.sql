CREATE TABLE [dbo].[PaymentMethod] (
    [PaymentMethodID]   SMALLINT     NOT NULL,
    [PaymentMethodType] VARCHAR (40) NOT NULL,
    CONSTRAINT [PK_PaymentMethod] PRIMARY KEY CLUSTERED ([PaymentMethodID] ASC) WITH (FILLFACTOR = 90)
);

