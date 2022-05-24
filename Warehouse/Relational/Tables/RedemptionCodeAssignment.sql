CREATE TABLE [Relational].[RedemptionCodeAssignment] (
    [MembersAssignedBatch] SMALLINT IDENTITY (1, 1) NOT NULL,
    [AssignedDate]         DATE     NULL,
    PRIMARY KEY CLUSTERED ([MembersAssignedBatch] ASC)
);

