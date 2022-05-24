CREATE TABLE [Staging].[EventListInput] (
    [EventListInputID] INT            IDENTITY (1, 1) NOT NULL,
    [BrandID]          VARCHAR (50)   NULL,
    [EventTypeID]      VARCHAR (50)   NULL,
    [StartDate]        VARCHAR (50)   NULL,
    [EndDate]          VARCHAR (50)   NULL,
    [Tentative]        VARCHAR (50)   NULL,
    [Notes]            VARCHAR (8000) NULL,
    [EventTitle]       VARCHAR (60)   NOT NULL,
    PRIMARY KEY CLUSTERED ([EventListInputID] ASC)
);

