CREATE TABLE [Selections].[CustomerExclusions] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT          NULL,
    [ClubID]    INT          NULL,
    [SourceUID] VARCHAR (20) NULL,
    [StartDate] DATE         NULL,
    [EndDate]   DATE         NULL
);

