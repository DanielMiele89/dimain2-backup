﻿CREATE TABLE [Relational].[controlgroupmembers] (
    [controlgroupid] INT NOT NULL,
    [fanid]          INT NOT NULL,
    PRIMARY KEY CLUSTERED ([controlgroupid] ASC, [fanid] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [uc_controlgroupid_FanID] UNIQUE NONCLUSTERED ([controlgroupid] ASC, [fanid] ASC) WITH (DATA_COMPRESSION = PAGE) ON [Warehouse_Indexes]
);




GO
DENY DELETE
    ON OBJECT::[Relational].[controlgroupmembers] TO [OnCall]
    AS [dbo];


GO
DENY ALTER
    ON OBJECT::[Relational].[controlgroupmembers] TO [OnCall]
    AS [dbo];

