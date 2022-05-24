CREATE TABLE [Relational].[Customers_ReducedFrequency_ExcludedEver] (
    [ID]        INT      IDENTITY (1, 1) NOT NULL,
    [FanID]     INT      NOT NULL,
    [StartDate] DATE     NOT NULL,
    [EndDate]   DATE     NULL,
    [TestGroup] CHAR (1) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Customers_ReducedFrequency_ExcludedEver_Allfields]
    ON [Relational].[Customers_ReducedFrequency_ExcludedEver]([FanID] ASC, [StartDate] ASC, [EndDate] ASC, [TestGroup] ASC);

