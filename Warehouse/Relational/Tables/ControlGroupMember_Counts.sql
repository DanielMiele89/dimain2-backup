CREATE TABLE [Relational].[ControlGroupMember_Counts] (
    [id]             INT     IDENTITY (1, 1) NOT NULL,
    [PartnerID]      INT     NOT NULL,
    [SuperSegmentID] TINYINT NOT NULL,
    [ControlGroupID] INT     NOT NULL,
    [StartDate]      DATE    NOT NULL,
    [NumberofFanIDs] INT     NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNCIX_ControlGroupMember_Counts]
    ON [Relational].[ControlGroupMember_Counts]([ControlGroupID] ASC, [StartDate] ASC);

