CREATE TABLE [dbo].[InsightArchive.DMResults] (
    [ID]              INT            NULL,
    [MID]             NVARCHAR (255) NULL,
    [Narrative]       NVARCHAR (255) NULL,
    [LocationCountry] NVARCHAR (255) NULL,
    [MCCID]           SMALLINT       NULL,
    [OriginatorID]    NVARCHAR (255) NULL,
    [Prob]            FLOAT (53)     NULL,
    [PredictBrandID]  BIGINT         NULL
);

