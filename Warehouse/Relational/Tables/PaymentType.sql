CREATE TABLE [Relational].[PaymentType] (
    [PaymentTypeID] TINYINT      NOT NULL,
    [TypeDesc]      VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Relational_PaymentType] PRIMARY KEY CLUSTERED ([PaymentTypeID] ASC)
);

