CREATE TABLE [InsightArchive].[allcustomers] (
    [FanID]       INT    NOT NULL,
    [CompositeID] BIGINT NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Comp]
    ON [InsightArchive].[allcustomers]([CompositeID] ASC);

