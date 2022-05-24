CREATE TABLE [InsightArchive].[Nuffield_gym_competition_OINs] (
    [RecordType]      VARCHAR (50) NULL,
    [OIN]             VARCHAR (50) NULL,
    [Narrative]       VARCHAR (50) NULL,
    [AddresseeName]   VARCHAR (50) NULL,
    [PostalName]      VARCHAR (50) NULL,
    [Address1]        VARCHAR (50) NULL,
    [LastAmend]       VARCHAR (50) NULL,
    [Brand_Code]      VARCHAR (50) NULL,
    [Brand_group]     VARCHAR (50) NULL,
    [Match_Narrative] VARCHAR (50) NULL
);


GO
CREATE CLUSTERED INDEX [cix_OIN]
    ON [InsightArchive].[Nuffield_gym_competition_OINs]([OIN] ASC);


GO
CREATE NONCLUSTERED INDEX [nix_OIN_Narrative]
    ON [InsightArchive].[Nuffield_gym_competition_OINs]([OIN] ASC)
    INCLUDE([Narrative]);

