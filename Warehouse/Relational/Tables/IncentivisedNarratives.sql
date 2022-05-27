CREATE TABLE [Relational].[IncentivisedNarratives] (
    [ID]        INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT           NULL,
    [Narrative] NVARCHAR (50) NULL,
    [StartDate] DATE          NULL,
    [EndDate]   DATE          NULL
);

