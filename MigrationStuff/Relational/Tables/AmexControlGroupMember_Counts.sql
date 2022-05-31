CREATE TABLE [Relational].[AmexControlGroupMember_Counts] (
    [id]                 INT     IDENTITY (1, 1) NOT NULL,
    [PartnerID]          INT     NOT NULL,
    [SuperSegmentID]     TINYINT NOT NULL,
    [AmexControlGroupID] INT     NOT NULL,
    [StartDate]          DATE    NOT NULL,
    [NumberofFanIDs]     INT     NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

