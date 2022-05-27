CREATE TABLE [Report].[OfferReport_CTCustomers] (
    [Exposed]                    BIT NOT NULL,
    [IsInPromgrammeControlGroup] BIT NOT NULL,
    [GroupID]                    INT NOT NULL,
    [FanID]                      INT NOT NULL,
    [CINID]                      INT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_CINGroupEx]
    ON [Report].[OfferReport_CTCustomers]([CINID] ASC, [GroupID] ASC)
    INCLUDE([Exposed]);


GO
CREATE NONCLUSTERED INDEX [IX_ExGroupCIN]
    ON [Report].[OfferReport_CTCustomers]([Exposed] ASC, [GroupID] ASC)
    INCLUDE([CINID]);


GO
CREATE NONCLUSTERED INDEX [IX_ExpGroup_IncFanCINID]
    ON [Report].[OfferReport_CTCustomers]([Exposed] ASC, [GroupID] ASC)
    INCLUDE([FanID], [CINID]);

