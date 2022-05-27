CREATE TABLE [Report].[OfferReport_ControlGroupMembers] (
    [ControlGroupID] INT NOT NULL,
    [FanID]          INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ControlGroupID] ASC, [FanID] ASC),
    CONSTRAINT [UCI_All] UNIQUE NONCLUSTERED ([ControlGroupID] ASC, [FanID] ASC)
);

