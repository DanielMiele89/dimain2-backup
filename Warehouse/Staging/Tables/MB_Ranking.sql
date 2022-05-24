CREATE TABLE [Staging].[MB_Ranking] (
    [PartnerID] INT NOT NULL,
    [Ranking]   INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_MB_Ranking_PartnerID]
    ON [Staging].[MB_Ranking]([PartnerID] ASC);

