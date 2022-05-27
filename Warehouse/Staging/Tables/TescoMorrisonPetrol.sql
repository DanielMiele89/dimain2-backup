CREATE TABLE [Staging].[TescoMorrisonPetrol] (
    [Brand]       VARCHAR (100) NULL,
    [MID]         VARCHAR (22)  NOT NULL,
    [Narrative]   VARCHAR (50)  NOT NULL,
    [MCC]         VARCHAR (4)   NOT NULL,
    [MCCDesc]     VARCHAR (200) NOT NULL,
    [PartnerID]   INT           NULL,
    [PartnerName] VARCHAR (50)  NULL,
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [Category]    VARCHAR (50)  NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_TescoMorrisonPetrol]
    ON [Staging].[TescoMorrisonPetrol]([MID] ASC);

