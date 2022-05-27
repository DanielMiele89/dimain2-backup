CREATE TABLE [Relational].[PaymentGatewayStatus] (
    [PaymentGatewayStatusID] TINYINT      NOT NULL,
    [StatusDesc]             VARCHAR (30) NOT NULL,
    CONSTRAINT [PK_Relational_PaymentGatewayStatus] PRIMARY KEY CLUSTERED ([PaymentGatewayStatusID] ASC)
);

