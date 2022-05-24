CREATE TABLE [Relational].[EventType] (
    [EventTypeID]   TINYINT      NOT NULL,
    [EventTypeDesc] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_EventType] PRIMARY KEY CLUSTERED ([EventTypeID] ASC)
);

