CREATE TABLE [kevinc].[StagingControlGroupMembers] (
    [FanId]            INT           NOT NULL,
    [ControlGroupID]   INT           NOT NULL,
    [ReportingOfferID] INT           NOT NULL,
    [CINID]            INT           NOT NULL,
    [PartnerID]        INT           NOT NULL,
    [StartDate]        DATETIME2 (7) NOT NULL,
    [EndDate]          DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [StagingControlGroupMembers_CINID]
    ON [kevinc].[StagingControlGroupMembers]([CINID] ASC);

