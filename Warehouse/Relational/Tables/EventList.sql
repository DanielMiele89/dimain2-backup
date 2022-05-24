CREATE TABLE [Relational].[EventList] (
    [EventListID] INT            IDENTITY (1, 1) NOT NULL,
    [BrandID]     SMALLINT       NULL,
    [EventTypeID] TINYINT        NOT NULL,
    [StartDate]   DATE           NOT NULL,
    [EndDate]     DATE           NOT NULL,
    [IsTentative] BIT            DEFAULT ((0)) NOT NULL,
    [Notes]       VARCHAR (8000) NULL,
    [EventTitle]  VARCHAR (60)   NOT NULL,
    PRIMARY KEY CLUSTERED ([EventListID] ASC),
    CONSTRAINT [FK_EventList_EventType] FOREIGN KEY ([EventTypeID]) REFERENCES [Relational].[EventType] ([EventTypeID])
);

