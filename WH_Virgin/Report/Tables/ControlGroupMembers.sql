CREATE TABLE [Report].[ControlGroupMembers] (
    [ControlGroupID] INT NOT NULL,
    [FanID]          INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ControlGroupID] ASC, [FanID] ASC),
    CONSTRAINT [UC_ControlGroupID_FanID] UNIQUE NONCLUSTERED ([ControlGroupID] ASC, [FanID] ASC)
);

