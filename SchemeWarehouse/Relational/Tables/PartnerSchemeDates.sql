CREATE TABLE [Relational].[PartnerSchemeDates] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT  NOT NULL,
    [ClubID]    INT  NOT NULL,
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerSchemeDatesID]
    ON [Relational].[PartnerSchemeDates]([PartnerID] ASC, [StartDate] ASC, [EndDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerSchemeDatesID_ClubID]
    ON [Relational].[PartnerSchemeDates]([ClubID] ASC);

