CREATE TABLE [Relational].[Outlets_TrackedbyCLS] (
    [ID]        INT     IDENTITY (1, 1) NOT NULL,
    [OutletID]  INT     NULL,
    [StatusID]  TINYINT NULL,
    [StartDate] DATE    NULL,
    [EndDate]   DATE    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

