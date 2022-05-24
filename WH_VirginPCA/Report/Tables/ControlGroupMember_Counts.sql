CREATE TABLE [Report].[ControlGroupMember_Counts] (
    [ID]             INT     IDENTITY (1, 1) NOT NULL,
    [PartnerID]      INT     NOT NULL,
    [SuperSegmentID] TINYINT NOT NULL,
    [ControlGroupID] INT     NOT NULL,
    [StartDate]      DATE    NOT NULL,
    [NumberofFanIDs] INT     NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNCIX_ControlGroupMember_Counts]
    ON [Report].[ControlGroupMember_Counts]([ControlGroupID] ASC, [StartDate] ASC);

