CREATE TABLE [MI].[RetailerMetricPaymentypes] (
    [ID]              SMALLINT     IDENTITY (1, 1) NOT NULL,
    [ProgramID]       INT          NOT NULL,
    [PaymentID]       INT          NOT NULL,
    [SourcePaymentID] INT          NULL,
    [Description]     VARCHAR (20) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

