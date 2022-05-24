CREATE TABLE [Staging].[OPE_Weighting] (
    [WeightingID]    INT     IDENTITY (1, 1) NOT NULL,
    [ConceptID]      INT     NOT NULL,
    [ConceptLevelID] TINYINT NOT NULL,
    [Weighting]      TINYINT NOT NULL,
    [StartDate]      DATE    NOT NULL,
    [EndDate]        DATE    NULL,
    PRIMARY KEY CLUSTERED ([WeightingID] ASC),
    UNIQUE NONCLUSTERED ([WeightingID] ASC)
);

