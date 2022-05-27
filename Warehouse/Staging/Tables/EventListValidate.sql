CREATE TABLE [Staging].[EventListValidate] (
    [EventListInputID] INT            NOT NULL,
    [BrandID]          SMALLINT       NULL,
    [EventTypeID]      TINYINT        NOT NULL,
    [StartDate]        DATE           NULL,
    [EndDate]          DATE           NULL,
    [Tentative]        BIT            NULL,
    [Notes]            VARCHAR (8000) NULL,
    [EventTitle]       VARCHAR (60)   NOT NULL,
    PRIMARY KEY CLUSTERED ([EventListInputID] ASC)
);

