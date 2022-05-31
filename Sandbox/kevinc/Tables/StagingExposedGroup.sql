CREATE TABLE [kevinc].[StagingExposedGroup] (
    [FanID]            INT NOT NULL,
    [ReportingOfferID] INT NOT NULL,
    [CINID]            INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [StagingExposedGroup_PartnerId_StartDate_EndDate]
    ON [kevinc].[StagingExposedGroup]([FanID] ASC);

