CREATE TABLE [Relational].[PaymentGatewaySecondaryDetail] (
    [PaymentGatewayID]      INT          IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT          NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Relational_PaymentGatewaySecondaryDetail] PRIMARY KEY CLUSTERED ([PaymentGatewayID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Relational_PaymentGatewaySecondaryDetail]
    ON [Relational].[PaymentGatewaySecondaryDetail]([ConsumerCombinationID] ASC, [MID] ASC, [Narrative] ASC) WITH (FILLFACTOR = 80)
    ON [Warehouse_Indexes];

