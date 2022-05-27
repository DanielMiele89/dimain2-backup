CREATE TABLE [Relational].[CardActivations] (
    [CardActivationsID] INT      IDENTITY (1, 1) NOT NULL,
    [PanID]             INT      NOT NULL,
    [FanID]             INT      NOT NULL,
    [AdditionDate]      DATETIME NOT NULL,
    [RemovalDate]       DATETIME NULL,
    [PaymentCardID]     INT      NULL,
    PRIMARY KEY CLUSTERED ([CardActivationsID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_CardActivations_FanID]
    ON [Relational].[CardActivations]([FanID] ASC);

