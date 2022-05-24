CREATE TABLE [MIDI].[BrandMatch] (
    [BrandMatchID] INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]      SMALLINT     NOT NULL,
    [Narrative]    VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([BrandMatchID] ASC),
    CONSTRAINT [UQ_BrandMatch_Narrative] UNIQUE NONCLUSTERED ([Narrative] ASC) WITH (FILLFACTOR = 80)
);

