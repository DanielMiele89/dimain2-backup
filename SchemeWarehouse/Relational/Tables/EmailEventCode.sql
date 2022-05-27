CREATE TABLE [Relational].[EmailEventCode] (
    [EmailEventCodeID] INT            NOT NULL,
    [Description]      NVARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([EmailEventCodeID] ASC),
    UNIQUE NONCLUSTERED ([EmailEventCodeID] ASC)
);

