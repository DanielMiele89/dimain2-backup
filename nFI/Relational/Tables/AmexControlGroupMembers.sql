CREATE TABLE [Relational].[AmexControlGroupMembers] (
    [AmexControlgroupID] INT NOT NULL,
    [FanID]              INT NULL
);


GO
CREATE CLUSTERED INDEX [i_AmexControlGroupMembersAmexControlGroupID_FanID]
    ON [Relational].[AmexControlGroupMembers]([AmexControlgroupID] ASC, [FanID] ASC) WITH (DATA_COMPRESSION = PAGE);


GO
DENY ALTER
    ON OBJECT::[Relational].[AmexControlGroupMembers] TO [OnCall]
    AS [dbo];

